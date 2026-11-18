import { initPlay } from "./play.js";
import { initAnalysis, showGames } from "./analysis.js";

for (const btn of document.querySelectorAll(".tabs button")) {
  btn.onclick = () => {
    document.querySelectorAll(".tabs button, .tab").forEach((el) => el.classList.remove("active"));
    btn.classList.add("active");
    document.getElementById(btn.dataset.tab).classList.add("active");
    if (btn.dataset.tab === "analysis") showGames();
  };
}

initPlay();
initAnalysis();
