"""Bridge to the Ciao engine.

`state` is JSON and always has "racks": [human, bot] ("?" is a blank).
"term" is the Prolog game. Send that same value back to play the next
move, or pass it to explore() with several moves to branch the search.
"over" stays false until the Prolog engine has an end-of-game condition.
"""

import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from bot.bot import choose_move
from bot.ciao import Ciao, MoveError

__all__ = ["MoveError", "new_game", "apply_move", "explore", "bot_move"]

_session = None
_lock = threading.Lock()


def _ciao():
    global _session
    with _lock:
        if _session is None or _session.closed:
            _session = Ciao()
        return _session


def new_game():
    return _ciao().new_game()


def apply_move(state, move):
    """Apply `move` ("WORD 8H", "PASS", "EXCHANGE ABC") for the player to move.
    Return (new_state, score) or raise MoveError(reason)."""
    if "term" not in state:
        raise MoveError("this game has no Prolog state; start a new game")
    return _ciao().apply(state, move)


def explore(state, moves):
    """Try each move from the same state. One result per move, in order."""
    if "term" not in state:
        raise MoveError("this game has no Prolog state; start a new game")
    return _ciao().explore(state, moves)


def bot_move(state):
    """Return the bot's move for the player to move, in engine notation."""
    return choose_move(state)
