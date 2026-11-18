Requirements:
- Ciao Prolog
- words.txt (line-separated dictionary, I've generated mine from Collins' .lxl word list)

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
Existing Letters are shown in brackets

POS is formatted as so:
Number indicating Row
Letter indicating Column
Number first indicates Horizontal Placement and Vice Versa

Web UI:
    python3 -m venv .venv && .venv/bin/pip install -r server/requirements.txt
    .venv/bin/python server/app.py
    -> http://localhost:8000 (friends: http://<your-ip>:8000)
    server/engine.py keeps one Ciao process running (prolog/bridge.pl) and
    passes the game state back and forth. Games are saved to games/*.json.

Debug:
    nodebug.
    debug_module_source(user).
    use_module('prolog/play.pl').
    trace.
    {Continue with cmds}

TODO:
- Exchange blank