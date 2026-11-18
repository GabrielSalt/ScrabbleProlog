:- use_module(library(iso_char)).
:- ensure_loaded('dict.pl').

direction(horizontal).
direction(vertical).

other_direction(horizontal, vertical).
other_direction(vertical, horizontal).

place(Board, Row, Column, Letter, [sq(Row, Column, Letter) | Board]).

tile(Board, Row, Column, Letter) :-
    member(sq(Row, Column, Letter), Board).

nextCell(R, C, vertical,   R1, C) :-
    R1 is R + 1.
nextCell(R, C, horizontal, R, C1) :-
    C1 is C + 1.

backCell(R, C, vertical,   R1, C) :-
    R1 is R - 1.
backCell(R, C, horizontal, R, C1) :-
    C1 is C - 1.

wordStart(Board, (R, C, vertical), R0, C0) :-
    lookUp(R, C, Board, R0, C0).
wordStart(Board, (R, C, horizontal), R0, C0) :-
    lookLeft(R, C, Board, R0, C0).

% Overlap of existing letter
playMove([0'(, L, 0') | Rest], Board, (R,C,Direction), Rack, NewBoard, NewRack, WordScore + LScore, WMult, _, IsConnected) :-
    !,
    tile(Board, R, C, L),
    letter_score(L, LScore),
    nextCell(R,C,Direction, R1, C1),
    playMove(Rest, Board, (R1, C1, Direction), Rack, NewBoard, NewRack, WordScore, WMult, 1, IsConnected).

% Normal Letter
playMove([L | Rest], Board, (R,C,Direction), Rack, NewBoard, NewRack, WordScore + CScore + HScore * Ws, WMult * Ws, Acc, Final) :-
    char_code(L, X),
    X > 64, X < 91,
    \+ tile(Board, R, C, _),
    remove(Rack, L, NewRack1),
    place(Board, R, C, L, NewBoard1),
    scoreLetter(L, R, C, CScore, Ws),
    other_direction(Direction, Direction1),
    scoreHook(NewBoard1, (R,C,Direction1), HScore),
    ( HScore > 0 ->
        Acc1 is Acc + 1
    ;   Acc1 = Acc
    ),
    nextCell(R,C,Direction, R1, C1),
    playMove(Rest, NewBoard1, (R1, C1, Direction), NewRack1, NewBoard, NewRack, WordScore, WMult, Acc1, Final).

% Blank Tile
playMove([L | Rest], Board, (R,C,Direction), Rack, NewBoard, NewRack, WordScore + HScore * Ws, WMult * Ws, Acc, Final) :- 
    char_code(L, X),
    X > 96, X < 123,
    \+ tile(Board, R, C, _),
    remove(Rack, blank, NewRack1),
    place(Board, R, C, L, NewBoard1),
    score_cell(R, C, Ws, _),
    other_direction(Direction, Direction1),
    scoreHook(NewBoard1, (R,C,Direction1), HScore),
    ( HScore > 0 ->
        Acc1 is Acc + 1
    ;   Acc1 = Acc
    ),
    nextCell(R,C,Direction, R1, C1),
    playMove(Rest, NewBoard1, (R1, C1, Direction), NewRack1, NewBoard, NewRack, WordScore, WMult, Acc1, Final).

% End Of Word. The position is the square after the last tile.
playMove([], Board, (R, C, Direction), Rack, Board, Rack, 0, 1, Acc, Acc) :-
    backCell(R, C, Direction, R1, C1),
    wordStart(Board, (R1, C1, Direction), R0, C0),
    grabWord(Board, (R0, C0, Direction), _, Atoms),
    (   Atoms = [_, _ | _] ->
        ( atom_chars(Word, Atoms), known_word(Word) )
    ;   true
    ).

scoreLetter(L, R, C, CScore, Ws) :-
    letter_score(L, LScore),
    score_cell(R, C, Ws, Ls),
    CScore is LScore * Ls.

scoreHook(Board, (R, C, vertical), HScore) :-
    hasNeighbour(Board, R, C, vertical),
    lookUp(R, C, Board, RStart, CStart),
    grabWord(Board, (RStart, CStart, vertical), HScore, WordAtoms),
    atom_chars(Word, WordAtoms),
    known_word(Word).
scoreHook(Board, (R, C, horizontal), HScore) :-
    hasNeighbour(Board, R, C, horizontal),
    lookLeft(R, C, Board, RStart, CStart),
    grabWord(Board, (RStart, CStart, horizontal), HScore, WordAtoms),
    atom_chars(Word, WordAtoms),
    known_word(Word).
scoreHook(_, _, 0).

joins(Old, New) :-
    member(sq(R, C, _), New),
    \+ tile(Old, R, C, _),
    beside(Old, R, C).

beside(Board, R, C) :-
    R1 is R - 1, tile(Board, R1, C, _).
beside(Board, R, C) :-
    R1 is R + 1, tile(Board, R1, C, _).
beside(Board, R, C) :-
    C1 is C - 1, tile(Board, R, C1, _).
beside(Board, R, C) :-
    C1 is C + 1, tile(Board, R, C1, _).

hasNeighbour(Board, R, C, horizontal) :-
    C1 is C-1,
    tile(Board, R, C1, _).
hasNeighbour(Board, R, C, horizontal) :-
    C1 is C+1,
    tile(Board, R, C1, _).
hasNeighbour(Board, R, C, vertical) :-
    R1 is R-1,
    tile(Board, R1, C, _).
hasNeighbour(Board, R, C, vertical) :-
    R1 is R+1,
    tile(Board, R1, C, _).

lookUp(R, C, Board, RStart, CStart) :-
    R1 is R - 1,
    tile(Board, R1, C, _),
    !,
    lookUp(R1, C, Board, RStart, CStart).
lookUp(R, C, _, R, C).

lookLeft(R, C, Board, RStart, CStart) :-
    C1 is C - 1,
    tile(Board, R, C1, _),
    !,
    lookLeft(R, C1, Board, RStart, CStart).
lookLeft(R, C, _, R, C).

grabWord(Board, (R, C, vertical), HScore + LScore, [Letter | Word]) :-
    tile(Board, R, C, Letter),
    !,
    R1 is R + 1,
    letter_score(Letter, LScore),
    grabWord(Board, (R1, C, vertical), HScore, Word).
grabWord(Board, (R, C, horizontal), HScore + LScore, [Letter | Word]) :-
    tile(Board, R, C, Letter),
    !,
    C1 is C + 1,
    letter_score(Letter, LScore),
    grabWord(Board, (R, C1, horizontal), HScore, Word).
grabWord(_, _, 0, []).

remove([L | Rest], L, Rest).
remove([L1 | Rest], L, [L1 | NewRack]) :-
    remove(Rest, L, NewRack).

