const { SWIPL } = await import(
    "https://SWI-Prolog.github.io/npm-swipl-wasm/7/0/6/dynamic-import.js"
  );
const swipl = await SWIPL({ arguments: ["-q"] });

const text = (url) => fetch(url).then((r) => r.text());
const [play, words, fileOps, grid, bag, wordList] = await Promise.all([
  text("webInterface/play.pl"),
  text("static/words.pl"),
  text("fileOps.pl"),
  text("static/grid.pl"),
  text("static/bag.pl"),
  text("words.txt"),
]);
swipl.FS.writeFile("/play.pl", play);
swipl.FS.writeFile("/words.pl", words);
swipl.FS.writeFile("/fileOps.pl", fileOps);
swipl.FS.writeFile("/grid.pl", grid);
swipl.FS.writeFile("/bag.pl", bag);
swipl.FS.writeFile("/words.txt", wordList);
swipl.prolog.consult("/play.pl");