import { api } from "./api.js";
import { renderBoard, renderPlayers, renderRack } from "./board.js";
import { boardAfter, key, placedTiles, totalsAfter } from "./scrabble.js";

const $ = (id) => document.getElementById(id);
const cards = [...document.querySelectorAll("#analysis .player")];

let game = null;
let ply = 0;   // number of moves applied to the shown position

export function initAnalysis() {
  $("refresh").onclick = showGames;
  $("first").onclick = () => go(0);
  $("prev").onclick = () => go(ply - 1);
  $("next").onclick = () => go(ply + 1);
  $("last").onclick = () => go(Infinity);
  document.addEventListener("keydown", (e) => {
    if (!$("analysis").classList.contains("active") || e.target.tagName === "INPUT" || !game) return;
    const to = { ArrowLeft: ply - 1, ArrowRight: ply + 1, ArrowUp: 0, Home: 0, ArrowDown: Infinity, End: Infinity }[e.key];
    if (to === undefined) return;
    e.preventDefault();
    go(to);
  });
  render();
}

export async function showGames() {
  const list = $("game-list");
  list.replaceChildren();
  for (const g of await api("/games")) {
    const li = document.createElement("li");
    li.textContent = `${g.players.map((p) => p.name).join(" vs ")} · ${g.moves} moves`;
    li.title = new Date(g.created * 1000).toLocaleString();
    li.classList.toggle("active", g.id === game?.id);
    li.onclick = () => open(g.id);
    list.append(li);
  }
}

async function open(id) {
  game = await api(`/games/${id}`);
  ply = game.moves.length;
  renderMoveList();
  render();
  showGames();
}

function go(to) {
  ply = Math.max(0, Math.min(to, game.moves.length));
  render();
}

// chess.com-style: one row per round, player 0 left, player 1 right.
function renderMoveList() {
  const table = $("move-list");
  table.replaceChildren();
  const totals = [0, 0];
  game.moves.forEach((m, i) => {
    if (i % 2 === 0) {
      const row = table.insertRow();
      row.insertCell().textContent = `${i / 2 + 1}.`;
    }
    totals[m.player] += m.score;
    const cell = table.rows[table.rows.length - 1].insertCell();
    cell.className = "move";
    cell.dataset.ply = i + 1;
    cell.innerHTML = `<b></b> <span class="pts">+${m.score}</span> <span class="total">${totals[m.player]}</span>`;
    cell.querySelector("b").textContent = m.move;
    cell.onclick = () => go(i + 1);
  });
}

function render() {
  const moves = game?.moves ?? [];
  const next = moves[ply];
  renderPlayers(cards, game?.players ?? [], totalsAfter(moves, ply), next?.player);
  renderBoard($("analysis-board"), {
    board: boardAfter(moves, ply),
    highlight: new Set(ply ? placedTiles(moves[ply - 1].move).map((t) => key(t.row, t.col)) : []),
  });
  $("rack-label").textContent = next ? `${game.players[next.player].name} to move:` : "";
  renderRack($("analysis-rack"), next?.rack ? [...next.rack] : []);
  for (const cell of document.querySelectorAll("#move-list .move")) {
    const active = Number(cell.dataset.ply) === ply;
    cell.classList.toggle("active", active);
    if (active) cell.scrollIntoView({ block: "nearest" });
  }
}
