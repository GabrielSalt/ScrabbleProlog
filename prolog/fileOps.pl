:- use_module(library(stream_utils)).

load_file(File, Func) :-
    open(File, read, In),
    catch(read_lines(In, Func), Error, (close(In), throw(Error))),
    close(In).

read_lines(In, Func) :-
    get_line(In, Line),
    (   Line == end_of_file
    ->  true
    ;   Goal =.. [Func, Line],
        call(Goal),
        read_lines(In, Func)
    ).