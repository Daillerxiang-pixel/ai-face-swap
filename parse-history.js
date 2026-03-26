const j = JSON.parse(require("fs").readFileSync("/tmp/history.json","utf8"));
const items = j.data || j;
if (items[0]) console.log(JSON.stringify(items[0], null, 2));
console.log("Total:", items.length);
