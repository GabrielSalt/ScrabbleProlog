import json
import time
import uuid
from pathlib import Path

from flask import Flask, abort, jsonify, request

import engine

ROOT = Path(__file__).resolve().parent.parent
GAMES = ROOT / "games"
GAMES.mkdir(exist_ok=True)

app = Flask(__name__, static_folder=str(ROOT / "webInterface"), static_url_path="")


def load(gid):
    path = GAMES / f"{gid}.json"
    if not path.is_file():
        abort(404)
    return json.loads(path.read_text())


def save(game):
    (GAMES / f"{game['id']}.json").write_text(json.dumps(game, indent=2))
    return jsonify(game)


def play(game, move):
    turn = len(game["moves"]) % 2
    rack = game["state"]["racks"][turn]
    try:
        game["state"], score = engine.apply_move(game["state"], move)
    except engine.MoveError as e:
        return jsonify(error=str(e)), 400
    game["moves"].append({"player": turn, "move": move, "score": score, "rack": rack})
    return save(game)


@app.get("/")
def index():
    return app.send_static_file("index.html")


@app.get("/api/games")
def list_games():
    games = [json.loads(p.read_text()) for p in GAMES.glob("*.json")]
    games.sort(key=lambda g: g["created"], reverse=True)
    return jsonify([
        {"id": g["id"], "created": g["created"], "players": g["players"], "moves": len(g["moves"])}
        for g in games
    ])


@app.post("/api/games")
def new_game():
    game = {
        "id": uuid.uuid4().hex[:8],
        "created": time.time(),
        "players": request.json["players"],
        "moves": [],
        "state": engine.new_game(),
    }
    return save(game)


@app.get("/api/games/<gid>")
def get_game(gid):
    return jsonify(load(gid))


@app.post("/api/games/<gid>/move")
def human_move(gid):
    return play(load(gid), request.json["move"])


@app.post("/api/games/<gid>/bot")
def bot_move(gid):
    game = load(gid)
    return play(game, engine.bot_move(game["state"]))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True, use_debugger=False)
