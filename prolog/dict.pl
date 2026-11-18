:- ensure_loaded('fileOps.pl').

:- dynamic isWord/1.

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
