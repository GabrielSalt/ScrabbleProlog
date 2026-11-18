"""Where the bot decides. It does not apply moves.

A state carries `term`, the whole Prolog game written as text. Evaluating
a move returns a new state and leaves the one you sent unchanged, so a
search tree is a list of those states. `engine.explore(state, moves)`
tries several moves from the same term in one call.
"""

class Bot:
    def choose_move(state):
        """Return a move in engine notation for the player about to play."""
        return "PASS"


    def get_moves(state):
        """Return the list of possible moves for the player about to play."""




    def apply_move(state, move):
        """Apply the move to the state and return the new state."""
        return state


    def evaluate_move(state, move):
        """Evaluate the move and return the score."""
        return 0