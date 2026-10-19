save_game(File) :-
    gameState(State),
    open(File, write, Out),
    writeq(Out, State),
    write(Out, '.'), nl(Out),
    close(Out).
load_game(File) :-
    open(File, read, In),
    read(In, State),
    close(In),
    retractall(gameState(_)),
    asserta(gameState(State)).