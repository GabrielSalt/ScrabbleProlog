printBoard(Board, Output) :-
    gridAsList(Board, GList),
    boardToString(GList, 1, Output).

gridAsList(Squares, List) :-
    length(List, 225),
    fill(Squares,List).

fill([], _).
fill([sq(R, C, L) | Rest], List) :-
    Index is (R-1) * 15 + C,
    nth(Index, List, L),
    fill(Rest, List).

boardToString([], _, []).
boardToString([Cell | Rest], Pos, Output) :-
    Pos1 is Pos + 1,
    piece(Cell, Pos, Codes),
    boardToString(Rest, Pos1, RestCodes),
    append(Codes, RestCodes, Output).
piece(Cell, Pos, Codes) :-
    ( Pos mod 15 =:= 0 -> Sep = " |\n" ; Sep = " | " ),
    ( var(Cell) -> Letter = " " ; atom_codes(Cell, Letter) ),
    append(Letter, Sep, Codes).
    
show :-
    gameState(state(Board, racks(Human, Bot), scores(Hs, Bs), Turn, _)),
    printBoard(Board, X),
    format("~s", [X]),
    HumanScore is Hs,
    BotScore is Bs,
    write(racks(Human, Bot)), nl,
    write(scores(HumanScore, BotScore)), nl,
    write(Turn), nl.