:- ensure_loaded('fileOps.pl').
:- ensure_loaded('grid.pl').
:- ensure_loaded('bag.pl').
:- ensure_loaded('dict.pl').
:- ensure_loaded('parseMove.pl').
:- ensure_loaded('print.pl').
:- ensure_loaded('save.pl').

:- dynamic gameState/1.

player(human).
player(bot).

next_player(human, bot).
next_player(bot, human).

initialState(state(["human"], [], racks(InitRackH, InitRackB), scores(0, 0), human, Bag2)) :-
    freshBag(Ordered), 
    shuffle(Ordered, Bag),
    draw(Bag, [], InitRackH, Bag1),
    draw(Bag1, [], InitRackB, Bag2).

resetGame :-
    initialState(State),
    retractall(gameState(_)),
    asserta(gameState(State)).

play(Move) :-
    gameState(State0),
    catch(
        (   makeMove(Move, State0, State)
        ->  retractall(gameState(_)),
            asserta(gameState(State))
        ;   write(no), nl
        ),
        Reason,
        (write(Reason), nl)
    ).

parseMove(Move, Word, R, C, Direction) :-
    append(WordCodes, [0' | CellCodes], Move),
    isCell(CellCodes, R, C, Direction),
    letters(WordCodes, Word).

% Passing
makeMove(Move, state(Moves, Board, Racks, Scores, Player, Bag), state(NewMoves, Board, Racks, Scores, Next, Bag)) :-
    Move = "PASS",
    !,
    next_player(Player, Next),
    record_move(Moves, Move, 0, NewMoves).

% Exchanges
makeMove(Move, state(Moves, Board, racks(H, B), Scores, human, Bag), state(NewMoves, Board, racks(H2, B), Scores, bot, Bag2)) :-
    append("EXCHANGE", [0' | TileCodes], Move),
    !,
    length(Bag, L),
    L >= 7,
    remove_tiles(H, TileCodes, H1),
    draw(Bag1, H1, H2, Bag2),
    addToBag(Bag, TileCodes, Bag1),
    record_move(Moves, Move, 0, NewMoves).
makeMove(Move, state(Moves, Board, racks(H, B), Scores, bot, Bag), state(NewMoves, Board, racks(H, B2), Scores, human, Bag2)) :-
    append("EXCHANGE", [0' | TileCodes], Move),
    length(Bag, L),
    L >= 7,
    !,
    remove_tiles(B, TileCodes, B1),
    draw(Bag1, B1, B2, Bag2),
    addToBag(Bag, TileCodes, Bag1),
    record_move(Moves, Move, 0, NewMoves).

% Ensure first (on-board) move covers middle tile
makeMove(Move, state(_, [], _, _, _, _), _) :-
    parseMove(Move, Word, R, C, Direction),
    length(Word, L),
    \+ covers_centre(L, R, C, Direction),
    throw(must_cover_centre).

makeMove(Move, state(Moves, Board, racks(H, B), scores(Hs, Bs), human, Bag), state(NewMoves, NewBoard, racks(H2, B), scores(Hs1, Bs), bot, NewBag)) :-
    parseMove(Move, Word, R, C, Direction),
    playMove(Word, Board, (R, C, Direction), H, NewBoard, H1, Ws, Wm, 0, Connected),
    ( (Board = [] ; Connected > 0 ; joins(Board, NewBoard)) ->
        true
    ;   throw(not_connected)
    ),
    Scored is Ws * Wm,
    Hs1 is Hs + Scored,
    record_move(Moves, Move, Scored, NewMoves),
    draw(Bag, H1, H2, NewBag).
makeMove(Move, state(Moves, Board, racks(H, B), scores(Hs, Bs), bot, Bag), state(NewMoves, NewBoard, racks(H, B2), scores(Hs, Bs1), human, NewBag)) :-
    parseMove(Move, Word, R, C, Direction),
    playMove(Word, Board, (R, C, Direction), B, NewBoard, B1, Ws, Wm, 0, Connected),
    ( (Board = [] ; Connected > 0 ; joins(Board, NewBoard)) ->
        true
    ;   throw(not_connected)
    ),
    Scored is Ws * Wm,
    Bs1 is Bs + Scored,
    record_move(Moves, Move, Scored, NewMoves),
    draw(Bag, B1, B2, NewBag).

record_move(Moves, Move, Points, NewMoves) :-
    number_codes(Points, PointCodes),
    append(Move, [0' , 0'+ | PointCodes], Entry),
    append(Moves, [Entry], NewMoves).

attempt(Move, State0, ok(State)) :-
    makeMove(Move, State0, State), !.
attempt(Move, State0, reject(Reason)) :-
    catch(makeMove(Move, State0, _), Reason, true).

letters([], []).
letters([0'(, Code, 0') | Rest], [0'(, Letter, 0') | Letters]) :-
    !,
    atom_codes(Letter, [Code]),
    letters(Rest, Letters).
letters([Code | Rest], [Letter | Letters]) :-
    atom_codes(Letter, [Code]),
    letters(Rest, Letters).

remove_tiles(Rack, [TileCode | Rest], NewRack) :-
    tile_atom(TileCode, Letter),
    remove(Rack, Letter, Rack1),
    remove_tiles(Rack1, Rest, NewRack).
remove_tiles(Rack, [], Rack).

tile_atom(0'?, blank) :- !.
tile_atom(Code, Letter) :-
    char_code(Letter, Code). 