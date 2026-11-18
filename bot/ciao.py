"""A long-lived Ciao process that evaluates Scrabble moves.

The dictionary stays loaded in that process. The game itself is not kept
there: each call sends the whole state (the `term` string) and gets a new
one back. `explore` runs several moves against one term. The results do
not share a board, so they are separate branches of a search.
"""

import atexit
import json
import os
import queue
import subprocess
import tempfile
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BRIDGE = ROOT / "prolog" / "start.pl"
PROLOG = ROOT / "prolog"

_STATE_KEYS = ("term", "racks", "bag", "scores", "turn", "board", "over")


class MoveError(Exception):
    pass


class Ciao:
    def __init__(self, words=None, start_timeout=300):
        words = Path(words or os.environ.get("SCRABBLE_WORDS") or (ROOT / "words.txt"))
        self._lock = threading.Lock()
        self._lines = queue.Queue()
        self._err = []
        env = os.environ.copy()
        env["SCRABBLE_PROLOG"] = str(PROLOG)
        env["SCRABBLE_WORDS"] = str(words)
        self._scratch = Path(tempfile.mkstemp(prefix="scrabble-")[1])
        env["SCRABBLE_SCRATCH"] = str(self._scratch)
        # ciaosh, not ciao-shell: the toplevel loads every file into one
        # module, which is what the cross-file engine calls expect.
        # No -f: that skips the default package, and then (/)/2 is missing
        # so dynamic/1 directives do not parse. The query has no comma.
        try:
            self.proc = subprocess.Popen(
                ["ciaosh", "-q", "-l", str(BRIDGE), "-e", "serve"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                cwd=str(PROLOG),
                env=env,
            )
        except FileNotFoundError as e:
            raise RuntimeError("ciaosh is not on PATH") from e
        threading.Thread(target=self._read_stdout, daemon=True).start()
        threading.Thread(target=self._read_stderr, daemon=True).start()
        atexit.register(self.close)
        try:
            self._wait_ready(start_timeout)
        except Exception:
            self._kill()
            raise

    @property
    def closed(self):
        return self.proc.poll() is not None

    def new_game(self):
        state, _ = self._unpack(self._request({"op": "new"}))
        return state

    def apply(self, state, move):
        message = self._request({"op": "apply", "term": state["term"], "move": move})
        return self._unpack(message)

    def explore(self, state, moves, timeout=120):
        """Try every move from the same state. Order matches `moves`."""
        message = self._request(
            {"op": "try", "term": state["term"], "moves": list(moves)},
            timeout=timeout,
        )
        if not message.get("ok"):
            raise RuntimeError(message.get("error", "Ciao request failed"))
        results = []
        for item in message["results"]:
            if item.get("ok"):
                child, score = self._unpack(item)
                results.append({"move": item["move"], "ok": True, "score": score, "state": child})
            else:
                results.append({
                    "move": item["move"],
                    "ok": False,
                    "error": item.get("error", "illegal"),
                })
        return results

    def close(self):
        if not self.closed:
            try:
                self.proc.stdin.write('{"op":"quit"}\n')
                self.proc.stdin.flush()
                self.proc.wait(timeout=5)
            except Exception:
                self._kill()
        if hasattr(self, "_scratch"):
            self._scratch.unlink(missing_ok=True)

    def _request(self, payload, timeout=120):
        with self._lock:
            if self.closed:
                raise RuntimeError("Ciao engine has stopped\n" + "".join(self._err))
            self.proc.stdin.write(json.dumps(payload) + "\n")
            self.proc.stdin.flush()
            line = self._read_line(timeout).strip()
        try:
            return json.loads(line)
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Bad Ciao reply: {line!r}") from e

    def _unpack(self, message):
        if not message.get("ok"):
            raise MoveError(str(message.get("error", "illegal")))
        state = {key: message[key] for key in _STATE_KEYS}
        return state, message.get("score", 0)

    def _wait_ready(self, timeout):
        end = time.monotonic() + timeout
        while True:
            remaining = end - time.monotonic()
            if remaining <= 0:
                raise RuntimeError("Ciao engine timed out while loading\n" + "".join(self._err))
            line = self._read_line(remaining).strip()
            if not line:
                continue
            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                self._err.append(line + "\n")
                continue
            if message.get("ready") is True:
                return
            raise RuntimeError(
                "Ciao engine failed to start: "
                + str(message.get("error", message))
                + "\n" + "".join(self._err)
            )

    def _read_line(self, timeout):
        try:
            line = self._lines.get(timeout=timeout)
        except queue.Empty:
            raise RuntimeError("Ciao engine timed out\n" + "".join(self._err))
        if line is None:
            raise RuntimeError("Ciao engine exited\n" + "".join(self._err))
        return line

    def _read_stdout(self):
        for line in self.proc.stdout:
            self._lines.put(line)
        self._lines.put(None)

    def _read_stderr(self):
        for line in self.proc.stderr:
            self._err.append(line)
            if len(self._err) > 40:
                del self._err[:20]

    def _kill(self):
        if self.proc.poll() is None:
            self.proc.kill()
        if hasattr(self, "_scratch"):
            self._scratch.unlink(missing_ok=True)
