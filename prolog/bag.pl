:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(library(system)).

add_letter(Bag0, _Letter, 0, Bag0).
add_letter(Bag0, Letter, N, Bag) :-
    N > 0,
    N1 is N - 1,
    add_letter(Bag0, Letter, N1, Bag1),
    Bag = [Letter | Bag1].

freshBag(Bag) :-
    fill_bag([], [
        'A'-9, 'E'-12, 'I'-9, 'O'-8, 'N'-6, 'R'-6, 'T'-6, 'L'-4, 'S'-4, 'U'-4, 'D'-4,
        'G'-3, 'B'-2, 'C'-2, 'M'-2, 'P'-2, 'F'-2, 'H'-2, 'V'-2, 'W'-2, 'Y'-2,
        'K'-1, 'J'-1, 'X'-1, 'Q'-1, 'Z'-1, blank-2
    ], Bag).

fill_bag(Bag, [], Bag).
fill_bag(Bag0, [Letter-N | Rest], Bag) :-
    add_letter(Bag0, Letter, N, Bag1),
    fill_bag(Bag1, Rest, Bag).

shuffle(List, Result) :-
    datime(Time, _, _, _, _, _, _, _, _),
    srandom(Time),
    shuffle_list(List, Result).

shuffle_list([], []).
shuffle_list(List, [Pick | Rest]) :-
    length(List, Length),
    Last is Length - 1,
    random(1, Last, Index),
    nth(Index, List, Pick),
    select(Pick, List, Remaining),
    shuffle_list(Remaining, Rest).

draw([], Tiles, Tiles, []).
draw(A, Tiles, Tiles, A) :-
    length(Tiles, Length),
    Length = 7.
draw(Bag, Tiles, Result, BagR) :-
    length(Tiles, Length),
    Length < 7,
    draw_letter(Bag, Bag1, L),
    draw(Bag1, [L | Tiles], Result, BagR).

draw_letter([Tile | Bag], Bag, Tile).

letter_score('A', 1).
letter_score('B', 3).
letter_score('C', 3).
letter_score('D', 2).
letter_score('E', 1).
letter_score('F', 4).
letter_score('G', 2).
letter_score('H', 4).
letter_score('I', 1).
letter_score('J', 8).
letter_score('K', 5).
letter_score('L', 1).
letter_score('M', 3).
letter_score('N', 1).
letter_score('O', 1).
letter_score('P', 3).
letter_score('Q', 10).
letter_score('R', 1).
letter_score('S', 1).
letter_score('T', 1).
letter_score('U', 1).
letter_score('V', 4).
letter_score('W', 4).
letter_score('X', 8).
letter_score('Y', 4).
letter_score('Z', 10).
letter_score(Letter, 0) :-
    atom_codes(Letter, [Code]),
    Code >= 0'a,
    Code =< 0'z.