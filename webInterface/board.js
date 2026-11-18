import { COLS, key, premium, tileScore } from "./scrabble.js";

const div = (className, text = "") => {
  const el = document.createElement("div");
  el.className = className;
  el.textContent = text;
  return el;
};

export function tile(letter, extra = "") {
  const blank = letter === letter.toLowerCase();
  const el = div(`tile ${blank ? "blank" : ""} ${extra}`, letter === "?" ? "" : letter.toUpperCase());
  if (!blank) el.append(Object.assign(document.createElement("sub"), { textContent: tileScore(letter) }));
  return el;
}

// pending/board: Map key -> letter; highlight: Set of keys; cursor: {row, col, dir} or null.
export function renderBoard(el, { board, pending = new Map(), highlight = new Set(), cursor = null, onCell }) {
  el.replaceChildren(div("label"));
  for (const c of COLS) el.append(div("label", c));
  for (let r = 1; r <= 15; r++) {
    el.append(div("label", r));
    for (let c = 1; c <= 15; c++) {
      const k = key(r, c);
      const sq = div(`sq ${premium(r, c)}`);
      if (pending.has(k)) sq.append(tile(pending.get(k), "pending"));
      else if (board.has(k)) sq.append(tile(board.get(k), highlight.has(k) ? "last" : ""));
      else if (cursor?.row === r && cursor?.col === c) sq.append(div("arrow", cursor.dir === "h" ? "\u2192" : "\u2193"));
      if (onCell) sq.onclick = () => onCell(r, c);
      el.append(sq);
    }
  }
}

// rack: array of letters; selected: index or null.
export function renderRack(el, rack, { selected = null, onTile } = {}) {
  el.replaceChildren();
  for (let i = 0; i < 7; i++) {
    const slot = div("slot");
    if (rack[i]) {
      slot.append(tile(rack[i], i === selected ? "selected" : ""));
      if (onTile) slot.onclick = () => onTile(i);
    }
    el.append(slot);
  }
}

export function renderPlayers(cards, players, totals, turn) {
  cards.forEach((card, i) => {
    card.classList.toggle("to-move", i === turn);
    card.querySelector(".name").textContent = players[i]?.name ?? "---";
    card.querySelector(".score").textContent = totals[i];
  });
}
