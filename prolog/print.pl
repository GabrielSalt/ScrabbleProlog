printBoard(Board, Output) :-
    gridAsList(Board, Cells),
    header(Head),
    rows(1, Cells, Body),
    append(Head, Body, Output).

header(Codes) :-
    labels(['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O'], Cols),
    append("   ", Cols, Codes).

labels([], "\n").
labels([Atom | Rest], Codes) :-
    atom_codes(Atom, [Code]),
    labels(Rest, RestCodes),
    append([Code, 0' , 0' , 0' ], RestCodes, Codes).

rows(_, [], []).
rows(N, Cells, Output) :-
    length(Row, 15),
    append(Row, Rest, Cells),
    row_codes(N, Row, Line),
    N1 is N + 1,
    rows(N1, Rest, More),
    append(Line, More, Output).

row_codes(N, Cells, Codes) :-
    row_label(N, Label),
    cell_codes(N, 1, Cells, Flat),
    append(Label, Flat, Line),
    append(Line, "\n", Codes).

row_label(N, [0' , Digit, 0' ]) :-
    N < 10,
    Digit is N + 0'0.

row_label(N, Codes) :-
    N >= 10,
    number_codes(N, Digits),
    append(Digits, " ", Codes).

cell_codes(_, _, [], []).
cell_codes(R, C, [Cell | Rest], Codes) :-
    ( var(Cell)
        -> ( score_cell(R, C, Ws, Ls), cellSymbol(Ws, Ls, Letter) )
        ;  atom_codes(Cell, Letter)
    ),
    append(Letter, " | ", Piece),
    C1 is C + 1,
    cell_codes(R, C1, Rest, More),
    append(Piece, More, Codes).

gridAsList(Squares, List) :-
    length(List, 225),
    fill(Squares,List).

fill([], _).
fill([sq(R, C, L) | Rest], List) :-
    Index is (R-1) * 15 + C,
    nth(Index, List, L),
    fill(Rest, List).

show :-
    gameState(state(Board, racks(Human, _), scores(Hs, Bs), human, _)),
    printBoard(Board, X),
    format("~s", [X]),
    HumanScore is Hs,
    BotScore is Bs,
    write(Human), nl,
    write(scores(HumanScore, BotScore)), nl.
show :-
    gameState(state(Board, racks(_, Bot), scores(Hs, Bs), bot, _)),
    printBoard(Board, X),
    format("~s", [X]),
    HumanScore is Hs,
    BotScore is Bs,
    write(Bot), nl,
    write(scores(HumanScore, BotScore)), nl.

cellSymbol(3,1, "*").
cellSymbol(2,1, "+").
cellSymbol(1,3, "∆").
cellSymbol(1,2, "~").
cellSymbol(1,1, " ").