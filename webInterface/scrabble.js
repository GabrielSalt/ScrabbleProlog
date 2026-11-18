// Notation follows the engine: "WORD 8H" = row 8, column H, horizontal;
// "WORD H8" = vertical. "(X)" = existing tile, lowercase = blank.

export const COLS = "ABCDEFGHIJKLMNO";

const LETTER_SCORES = {
  A: 1, B: 3, C: 3, D: 2, E: 1, F: 4, G: 2, H: 4, I: 1, J: 8, K: 5, L: 1, M: 3,
  N: 1, O: 1, P: 3, Q: 10, R: 1, S: 1, T: 1, U: 1, V: 4, W: 4, X: 8, Y: 4, Z: 10,
};

export const tileScore = (letter) => LETTER_SCORES[letter] ?? 0;
export const key = (r, c) => `${r},${c}`;

// Mirrors grid.pl: distances from centre, larger first.
export function premium(r, c) {
  const dr = Math.abs(r - 8), dc = Math.abs(c - 8);
  const a = Math.max(dr, dc), b = Math.min(dr, dc);
  const is = (pairs) => pairs.some(([x, y]) => x === a && y === b);
  if (is([[1, 1], [4, 0], [5, 1], [7, 4]])) return "dl";
  if (is([[2, 2], [6, 2]])) return "tl";
  if (is([[7, 0], [7, 7]])) return "tw";
  if (a === b) return "dw";
  return "";
}

export function parsePosition(pos) {
  let m = pos.match(/^(\d{1,2})([A-O])$/);
  if (m) return { row: +m[1], col: COLS.indexOf(m[2]) + 1, dir: "h" };
  m = pos.match(/^([A-O])(\d{1,2})$/);
  if (m) return { row: +m[2], col: COLS.indexOf(m[1]) + 1, dir: "v" };
  return null;
}

const formatPosition = (row, col, dir) =>
  dir === "h" ? `${row}${COLS[col - 1]}` : `${COLS[col - 1]}${row}`;

// Tiles newly placed by a move: [{row, col, letter}]. PASS/EXCHANGE place none.
export function placedTiles(move) {
  const [word, pos] = move.trim().split(/\s+/);
  const start = pos && parsePosition(pos);
  if (!start) return [];
  const tiles = [];
  let { row, col } = start;
  for (let i = 0; i < word.length; i++) {
    if (word[i] === "(") i += 2;
    else tiles.push({ row, col, letter: word[i] });
    if (start.dir === "h") col++;
    else row++;
  }
  return tiles;
}

export function boardAfter(moves, ply) {
  const board = new Map();
  for (const m of moves.slice(0, ply)) {
    for (const t of placedTiles(m.move)) board.set(key(t.row, t.col), t.letter);
  }
  return board;
}

export function totalsAfter(moves, ply) {
  const totals = [0, 0];
  for (const m of moves.slice(0, ply)) totals[m.player] += m.score;
  return totals;
}

// Six consecutive scoreless turns ends the game, unless the engine says so first.
export function isOver(game) {
  const last = game.moves.slice(-6);
  return !!game.state?.over || (last.length === 6 && last.every((m) => m.score === 0));
}

// board, pending: Map key -> letter. Returns notation for the pending tiles.
export function buildMove(board, pending) {
  const cells = [...pending.keys()].map((k) => k.split(",").map(Number));
  if (!cells.length) throw new Error("Place some tiles first");
  const rows = new Set(cells.map(([r]) => r));
  const cols = new Set(cells.map(([, c]) => c));
  let dir;
  if (cells.length === 1) {
    const [r, c] = cells[0];
    dir = board.has(key(r, c - 1)) || board.has(key(r, c + 1)) ? "h" : "v";
  } else if (rows.size === 1) dir = "h";
  else if (cols.size === 1) dir = "v";
  else throw new Error("Tiles must be in one row or column");

  const [dr, dc] = dir === "h" ? [0, 1] : [1, 0];
  const filled = (r, c) => board.has(key(r, c)) || pending.has(key(r, c));
  let [r, c] = cells.reduce((a, b) => (a[0] + a[1] <= b[0] + b[1] ? a : b));
  while (filled(r - dr, c - dc)) { r -= dr; c -= dc; }
  const start = formatPosition(r, c, dir);

  let word = "", used = 0;
  for (; filled(r, c); r += dr, c += dc) {
    const k = key(r, c);
    if (pending.has(k)) { word += pending.get(k); used++; }
    else word += `(${board.get(k)})`;
  }
  if (used !== pending.size) throw new Error("Tiles must be contiguous");
  return `${word} ${start}`;
}
