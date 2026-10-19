pre_order(void,[]).
pre_order(tree(X, Left, Right), Elements) :-
    pre_order(Left, ElementsLeft),
    pre_order(Right, ElementsRight),
    append(ElementsLeft, [X], Elements).

post_order(void,[]).
post_order(tree(X, Left, Right), Elements) :-
    post_order(Left, ElementsLeft),
    post_order(Right, ElementsRight),
    append(ElementsLeft, [X], Elements).

in_order(void,[]).
in_order(tree(X, Left, Right), Elements) :-
    in_order(Left, ElementsLeft),
    in_order(Right, ElementsRight),
    append(ElementsLeft, [X], Elements).

    