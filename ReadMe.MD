Start:
Terminal -> 
    ciao


Setup:
Ciao ->
    use_module('prolog/play.pl'),
    load_words('words.txt'),
    resetGame.

View State:
    gameState(state(Board, racks(Human, Bot), Scores, Turn, _)).

Playing:
Ciao ->
    play("{WORD} {POS}").

Where WORD is formatted as so:
Normal Letters are shown in UPPERCASE
Blanks are shown with their adopted letter in LOWERCASE
Existing Letters are shown 

Debug:
    nodebug.
    debug_module_source(user).
    use_module('prolog/play.pl').
    trace.
    {Continue with cmds}

TODO:
- Show score after move.
- First play must touch middle tile.
- Play connects to board somehow.
- Keep history of moves along with their scores.