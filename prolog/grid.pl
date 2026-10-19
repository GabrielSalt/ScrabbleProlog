inGrid(Index) :-
    Index > 0,
    Index < 16.

colToIndex('A', 1).
colToIndex('B', 2).
colToIndex('C', 3).
colToIndex('D', 4).
colToIndex('E', 5).
colToIndex('F', 6).
colToIndex('G', 7).
colToIndex('H', 8).
colToIndex('I', 9).
colToIndex('J', 10).
colToIndex('K', 11).
colToIndex('L', 12).
colToIndex('M', 13).
colToIndex('N', 14).
colToIndex('O', 15).

isCell([D1, D2, Letter], Row, Column, horizontal) :-
    row_number([D1, D2], Row),
    column(Letter, Column).
isCell([D, Letter], Row, Column, horizontal) :-
    row_number([D], Row),
    column(Letter, Column).
isCell([Letter, D1, D2], Row, Column, vertical) :-
    column(Letter, Column),
    row_number([D1, D2], Row).
isCell([Letter, D], Row, Column, vertical) :-
    column(Letter, Column),
    row_number([D], Row).

row_number(Codes, Row) :-
    number_codes(Row, Codes),
    inGrid(Row).
column(Code, Index) :-
    atom_codes(Letter, [Code]),
    colToIndex(Letter, Index),
    inGrid(Index).

score_cell(R, C, Ws, Ls) :-
    canon(R, C, A, B),
    score_pos(A, B, Ws, Ls).

mirror(N, D) :-
    D is abs(N - 8).
canon(R, C, A, B) :-
    mirror(R, Dr),
    mirror(C, Dc),
    (   Dr >= Dc
    ->  A = Dr, B = Dc
    ;   A = Dc, B = Dr
    ).

% Here R,C refers to distance from centre, 
% with the smaller number always first,
% which works thanks to 4-way symmetry.
score_pos(R, C, 1, 2) :-
    double_letter(R,C), !.
score_pos(R, C, 1, 3) :-
    triple_letter(R,C), !.
    score_pos(R, C, 3, 1) :-
    triple_word(R,C), !.
score_pos(R, C, 2, 1) :-
    double_word(R,C), !.
score_pos(_, _, 1, 1).

double_letter(1,1).
double_letter(4,0).
double_letter(5,1).
double_letter(7,4).

triple_letter(2,2).
triple_letter(6,2).

triple_word(7,0).
triple_word(7,7).

double_word(A,A).