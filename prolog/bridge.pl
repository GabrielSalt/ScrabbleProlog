% Line protocol between Python and the Scrabble engine.
%
% One process loads the dictionary once. Each request carries the whole
% game as a Prolog term and returns a new term. makeMove/3 does not
% modify the term it is given, so the same term can be sent with many
% different moves, and each result is an independent branch.
%
%   -> {"op":"new"}
%   -> {"op":"apply","move":"HELLO 8D","term":"<state(...)>"}
%   -> {"op":"try","term":"<state(...)>","moves":["HELLO 8D","PASS"]}
%   -> {"op":"quit"}
%   <- one JSON object per request

:- use_module(library(system), [
    working_directory/2, delete_file/1, file_exists/1, getenvstr/2
]).
:- use_module(library(stream_utils), [get_line/2]).
:- use_module(library(format), [format/2, format/3]).
:- use_module(library(lists), [member/2]).
:- use_module(library(pillow/json), [
    string_to_json/2, json_to_string/2, json_get/3, json_get_atm/3
]).

% Launched as: ciaosh -q -l start.pl -e serve
% Paths come from the environment so the -e query needs no commas.
serve :-
    env_atom('SCRABBLE_PROLOG', PrologDir),
    env_atom('SCRABBLE_WORDS', Words),
    catch(start(PrologDir, Words), Reason, (reply_error(Reason), halt(1))).

env_atom(Name, Atom) :-
    getenvstr(Name, Codes),
    atom_codes(Atom, Codes).

start(PrologDir, Words) :-
    working_directory(_, PrologDir),
    use_module('play.pl'),
    ( file_exists(Words) -> true ; throw(missing_words(Words)) ),
    load_words(Words),
    reply(json([ready=true])),
    loop.

loop :-
    current_input(In),
    get_line(In, Line),
    ( Line == end_of_file -> halt(0)
    ; Line == [] -> loop
    ; handle(Line),
      loop
    ).

handle(Line) :-
    catch(
        ( dispatch(Line) -> true ; reply_error(bad_request) ),
        Reason,
        reply_error(Reason)
    ).

dispatch(Line) :-
    string_to_json(Line, Json),
    json_get_atm(Json, op, Op),
    dispatch_op(Op, Json).

dispatch_op(new, _) :-
    initialState(State), !,
    reply_state(0, State).
dispatch_op(apply, Json) :-
    json_get_atm(Json, move, Move),
    json_get(Json, term, string(TermCodes)),
    codes_term(TermCodes, State0),
    run_move(Move, State0, Outcome),
    reply_outcome(Outcome).
dispatch_op(try, Json) :-
    json_get(Json, term, string(TermCodes)),
    codes_term(TermCodes, State0),
    json_get(Json, moves, Moves),
    try_moves(Moves, State0, Results),
    reply(json([ok=true, results=Results])).
dispatch_op(quit, _) :-
    ( scratch(File) -> catch(delete_file(File), _, true) ; true ),
    halt(0).

try_moves([], _, []).
try_moves([string(MoveCodes)|Rest], State0, [Result|Results]) :-
    atom_codes(Move, MoveCodes),
    run_move(Move, State0, Outcome),
    outcome_json(MoveCodes, Outcome, Result),
    try_moves(Rest, State0, Results).

% makeMove/3 either fails or throws. One clause so a throw is an
% answer, not an abort of the request.
run_move(Move, State0, Result) :-
    atom_codes(Move, Codes),
    catch(
        ( makeMove(Codes, State0, State) ->
            score_delta(State0, State, Score),
            Result = ok(Score, State)
        ; Result = err(illegal)
        ),
        Reason,
        Result = err(Reason)
    ).

score_delta(state(_, _, _, scores(H0, B0), _, _), state(_, _, _, scores(H, B), _, _), Score) :-
    Score is (H - H0) + (B - B0).

reply_outcome(ok(Score, State)) :-
    reply_state(Score, State).
reply_outcome(err(Reason)) :-
    reply_error(Reason).

reply_state(Score, State) :-
    view_attrs(State, View),
    reply(json([ok=true, score=Score|View])).

outcome_json(MoveCodes, ok(Score, State), json(Attrs)) :-
    view_attrs(State, View),
    Attrs = [move=string(MoveCodes), ok=true, score=Score|View].
outcome_json(MoveCodes, err(Reason), json([
    move=string(MoveCodes), ok=false, error=string(Codes)
])) :-
    term_codes(Reason, Codes).

view_attrs(State, [
    term=string(TermCodes),
    racks=[string(Human), string(Bot)],
    bag=string(BagCodes),
    scores=[Hs, Bs],
    turn=string(Turn),
    board=Rows,
    over=false
]) :-
    State = state(_, Board, racks(HumanRack, BotRack), scores(Hs, Bs), Player, Bag),
    term_codes(State, TermCodes),
    tiles_codes(HumanRack, Human),
    tiles_codes(BotRack, Bot),
    tiles_codes(Bag, BagCodes),
    atom_codes(Player, Turn),
    board_rows(Board, Rows).

tiles_codes([], []).
tiles_codes([Tile|Tiles], [Code|Codes]) :-
    tile_code(Tile, Code),
    tiles_codes(Tiles, Codes).

tile_code(blank, 63) :- !. % '?'
tile_code(Atom, Code) :-
    atom_codes(Atom, [Code]).

board_rows(Board, Rows) :-
    board_rows(1, Board, Rows).

board_rows(16, _, []) :- !.
board_rows(Row, Board, [string(Codes)|Rows]) :-
    row_codes(Row, 1, Board, Codes),
    Next is Row + 1,
    board_rows(Next, Board, Rows).

row_codes(_, 16, _, []) :- !.
row_codes(Row, Col, Board, [Code|Codes]) :-
    ( member(sq(Row, Col, Letter), Board) ->
        tile_code(Letter, Code)
    ; Code = 46 % '.'
    ),
    Next is Col + 1,
    row_codes(Row, Next, Board, Codes).

reply(Json) :-
    json_to_string(Json, Codes),
    format("~s~n", [Codes]),
    flush_output.

reply_error(Reason) :-
    term_codes(Reason, Codes),
    reply(json([ready=false, ok=false, error=string(Codes)])).

term_codes(Term, Codes) :-
    scratch(File),
    open(File, write, Out),
    writeq(Out, Term),
    close(Out),
    open(File, read, In),
    read_codes(In, Codes),
    close(In).

codes_term(Codes, Term) :-
    scratch(File),
    open(File, write, Out),
    format(Out, "~s.~n", [Codes]),
    close(Out),
    open(File, read, In),
    read(In, Term),
    close(In),
    ( Term == end_of_file -> throw(bad_term) ; true ).

scratch(File) :-
    env_atom('SCRABBLE_SCRATCH', File).

read_codes(Stream, Codes) :-
    get_code(Stream, Code),
    ( Code < 0 -> Codes = []
    ; Codes = [Code|Rest],
      read_codes(Stream, Rest)
    ).
