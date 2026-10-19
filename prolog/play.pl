:- ensure_loaded('fileOps.pl').
:- ensure_loaded('grid.pl').
:- ensure_loaded('bag.pl').
:- ensure_loaded('parseMove.pl').
:- ensure_loaded('print.pl').
:- ensure_loaded('save.pl').

:- dynamic gameState/1.
:- dynamic isWord/1.

player(human).
player(bot).

load_words(File) :-
    load_file(File, read_word).

read_word(Codes) :-
    atom_codes(Word, Codes),
    assertz(isWord(Word)).

known_word(Word) :-
    downcase_atom(Word, Lower),
    (   isWord(Lower)
    ->  true
    ;   throw(not_a_word(Word))
    ).

downcase_atom(Word, Lower) :-
    atom_codes(Word, Codes),
    map_lower(Codes, LowerCodes),
    atom_codes(Lower, LowerCodes).
map_lower([], []).
map_lower([Code | Rest], [Lower | RestLower]) :-
    ( Code >= 0'A, Code =< 0'Z -> Lower is Code + 32 ; Lower = Code ),
    map_lower(Rest, RestLower).

initialState(state([], racks(InitRackH, InitRackB), scores(0, 0), human, Bag2)) :-
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

makeMove(Move, state(Board, racks(H, B), scores(Hs, Bs), human, Bag), state(NewBoard, racks(H2, B), scores(Hs1, Bs), bot, NewBag)) :-
    parseMove(Move, Word, R, C, Direction),
    playMove(Word, Board, (R, C, Direction), H, NewBoard, H1, Ws, Wm),
    Hs1 is Hs + Ws * Wm,
    draw(Bag, H1, H2, NewBag).
makeMove(Move, state(Board, racks(H, B), scores(Hs, Bs), bot, Bag), state(NewBoard, racks(H, B2), scores(Hs, Bs1), human, NewBag)) :-
    parseMove(Move, Word, R, C, Direction),
    playMove(Word, Board, (R, C, Direction), B, NewBoard, B1, Ws, Wm),
    Bs1 is Bs + Ws * Wm,
    draw(Bag, B1, B2, NewBag).

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