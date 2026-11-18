import { api } from "./api.js";
import { renderBoard, renderPlayers, renderRack } from "./board.js";
import { boardAfter, buildMove, isOver, key, placedTiles, totalsAfter } from "./scrabble.js";

const $ = (id) => document.getElementById(id);
const cards = [...document.querySelectorAll("#play .player")];

let game = null;
let seat = 0;
let rack = [];             // [{letter, used}]
let pending = new Map();   // key -> {letter, tile}  (tile = rack entry)
let selected = null;
let cursor = null;         // {row, col, dir}: where the next typed letter goes
let timer = null;

const status = (msg) => ($("play-status").textContent = msg);
const turn = () => game.moves.length % 2;
const currentBoard = () => boardAfter(game.moves, game.moves.length);

export function initPlay() {
  $("new-bot").onclick = () => start([{ name: $("name").value, type: "human" }, { name: "Bot", type: "bot" }]);
  $("new-friend").onclick = () => start([{ name: $("name").value, type: "human" }, { name: "Friend", type: "human" }]);
  $("new-botbot").onclick = () => start([{ name: "Bot 1", type: "bot" }, { name: "Bot 2", type: "bot" }]);
  $("submit").onclick = submit;
  $("move-input").onkeydown = (e) => e.key === "Enter" && submit();
  $("recall").onclick = recall;
  $("pass").onclick = () => send("PASS");
  $("exchange").onclick = () => {
    const tiles = prompt("Tiles to exchange, e.g. QV");
    if (tiles) send(`EXCHANGE ${tiles.toUpperCase()}`);
  };
  $("shuffle").onclick = () => {
    rack.sort(() => Math.random() - 0.5);
    render();
  };
  document.addEventListener("keydown", onKey);

  const params = new URLSearchParams(location.search);
  if (params.get("game")) {
    seat = Number(params.get("seat") ?? 0);
    api(`/games/${params.get("game")}`).then(setGame, (e) => status(e.message));
  } else {
    render();
  }
}

async function start(players) {
  seat = 0;
  setGame(await api("/games", { players }));
  const friend = players[1].type === "human";
  $("share").textContent = friend
    ? `Friend link (swap localhost for your IP): ${location.origin}/?game=${game.id}&seat=1`
    : "";
  history.replaceState(null, "", `?game=${game.id}&seat=0`);
}

function setGame(g) {
  game = g;
  rack = [...game.state.racks[seat]].map((letter) => ({ letter, used: false }));
  pending.clear();
  selected = null;
  cursor = null;
  $("move-input").value = "";
  render();
  schedule();
}

// Bots move automatically; a human opponent is picked up by polling.
function schedule() {
  clearTimeout(timer);
  if (isOver(game)) return status("Game over");
  const t = turn();
  if (game.players[t].type === "bot") {
    status(`${game.players[t].name} is thinking...`);
    timer = setTimeout(() => request(`/games/${game.id}/bot`, {}), 400);
  } else if (t !== seat) {
    status(`Waiting for ${game.players[t].name}...`);
    timer = setTimeout(poll, 2000);
  } else {
    status("Your move");
  }
}

async function poll() {
  try {
    const g = await api(`/games/${game.id}`);
    if (g.moves.length !== game.moves.length) return setGame(g);
  } catch (e) {
    status(e.message);
  }
  schedule();
}

async function request(path, body) {
  try {
    setGame(await api(path, body));
  } catch (e) {
    status(e.message);
  }
}

function send(move) {
  if (!game) return status("Start a game first");
  if (turn() !== seat || game.players[seat].type !== "human") return status("Not your turn");
  request(`/games/${game.id}/move`, { move });
}

function submit() {
  const typed = $("move-input").value.trim();
  try {
    send(typed || buildMove(currentBoard(), letters()));
  } catch (e) {
    status(e.message);
  }
}

function recall() {
  rack.forEach((t) => (t.used = false));
  pending.clear();
  cursor = null;
  render();
}

const letters = () => new Map([...pending].map(([k, p]) => [k, p.letter]));

// Empty square: place the selected rack tile, otherwise show the arrow
// (horizontal first, clicking the same square again flips it).
function onCell(r, c) {
  const k = key(r, c);
  if (pending.has(k)) {
    pending.get(k).tile.used = false;
    pending.delete(k);
  } else if (currentBoard().has(k)) {
    return;
  } else if (selected !== null) {
    const tile = rack.filter((t) => !t.used)[selected];
    let letter = tile.letter;
    if (letter === "?") {
      letter = (prompt("Letter for blank?") ?? "").toLowerCase();
      if (!/^[a-z]$/.test(letter)) return;
    }
    tile.used = true;
    pending.set(k, { letter, tile });
    selected = null;
  } else if (cursor?.row === r && cursor?.col === c) {
    cursor.dir = cursor.dir === "h" ? "v" : "h";
  } else {
    cursor = { row: r, col: c, dir: "h" };
  }
  render();
}

function onKey(e) {
  if (!game || !$("play").classList.contains("active") || e.target.tagName === "INPUT") return;
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  if (e.key === "Enter") submit();
  else if (e.key === "Escape") recall();
  else if (e.key === "Backspace") takeBack();
  else if (/^[a-z]$/i.test(e.key) && cursor) typeLetter(e.key.toUpperCase());
  else return;
  e.preventDefault();
}

// Uses the matching rack tile, or a blank standing in for the letter.
function typeLetter(letter) {
  if (cursor.row > 15 || cursor.col > 15) return;
  const free = rack.filter((t) => !t.used);
  const tile = free.find((t) => t.letter === letter) ?? free.find((t) => t.letter === "?");
  if (!tile) return status(`No ${letter} or blank on your rack`);
  tile.used = true;
  pending.set(key(cursor.row, cursor.col), { letter: tile.letter === "?" ? letter.toLowerCase() : letter, tile });
  advance();
  render();
}

// Next empty square along the arrow; may run off the board (row/col 16).
function advance() {
  const board = currentBoard();
  const filled = () => board.has(key(cursor.row, cursor.col)) || pending.has(key(cursor.row, cursor.col));
  do {
    if (cursor.dir === "h") cursor.col++;
    else cursor.row++;
  } while (cursor.row <= 15 && cursor.col <= 15 && filled());
}

function takeBack() {
  const k = [...pending.keys()].at(-1);
  if (!k) return;
  pending.get(k).tile.used = false;
  pending.delete(k);
  const [row, col] = k.split(",").map(Number);
  cursor = { row, col, dir: cursor?.dir ?? "h" };
  render();
}

function render() {
  const moves = game?.moves ?? [];
  const last = moves.at(-1);
  renderPlayers(cards, game?.players ?? [], totalsAfter(moves, moves.length), game && turn());
  renderBoard($("play-board"), {
    board: boardAfter(moves, moves.length),
    pending: letters(),
    highlight: new Set(last ? placedTiles(last.move).map((t) => key(t.row, t.col)) : []),
    cursor,
    onCell: game && onCell,
  });
  renderRack($("play-rack"), rack.filter((t) => !t.used).map((t) => t.letter), {
    selected,
    onTile: (i) => { selected = selected === i ? null : i; render(); },
  });
}
