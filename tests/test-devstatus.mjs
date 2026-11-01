// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for services/devstatus.js. Run: node tests/test-devstatus.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const src = readFileSync(new URL("../services/devstatus.js", import.meta.url), "utf8").replace(".pragma library", "");
const ctx = {};
vm.runInNewContext(src, ctx);
const plain = v => JSON.parse(JSON.stringify(v));

assert.deepEqual(plain(ctx.parseGit(`# branch.oid abc
# branch.head main
# branch.upstream origin/main
# branch.ab +2 -1
1 .M N... 100644 100644 100644 a b file.txt
? new.txt
`)), { branch: "main", ahead: 2, behind: 1, dirty: 2 });
assert.deepEqual(plain(ctx.parseGit("# branch.oid (initial)\n# branch.head (detached)\n")), { branch: "(detached)", ahead: 0, behind: 0, dirty: 0 });

const head = "  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode\n";
const row = (addr, port, st) => `   0: ${addr}:${port.toString(16).toUpperCase().padStart(4, "0")} 00000000:0000 ${st} 00000000:00000000 00:00000000 00000000  1000 0 1 1\n`;
const v4 = head + row("3500007F", 53, "0A") + row("0100007F", 5173, "0A") + row("00000000", 3000, "0A")
    + row("0501A8C0", 9000, "0A") + row("0100007F", 45871, "0A") + row("0100007F", 631, "0A") + row("0100007F", 4000, "01");
const v6 = head + row("00000000000000000000000001000000", 5173, "0A") + row("00000000000000000000000000000000", 8080, "0A")
    + row("0000000000000000FFFF00000100007F", 7000, "0A") + row("B80D0120000000000000000001000000", 9100, "0A");
assert.deepEqual(plain(ctx.devPorts([v4, v6], [])), [3000, 5173, 7000, 8080]);
assert.deepEqual(plain(ctx.devPorts([v4, v6], [8080])), [3000, 5173, 7000]);
assert.deepEqual(plain(ctx.devPorts(["", ""], [])), []);

const netDev = `Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 9000      10    0    0    0     0          0         0     9000      10    0    0    0     0       0          0
  eth0: 1000      10    0    0    0     0          0         0     200       10    0    0    0     0       0          0
 wlan0:500 10 0 0 0 0 0 0 30 10 0 0 0 0 0 0
vethab12: 7000 10 0 0 0 0 0 0 7000 10 0 0 0 0 0 0
docker0: 7000 10 0 0 0 0 0 0 7000 10 0 0 0 0 0 0
br-1234: 7000 10 0 0 0 0 0 0 7000 10 0 0 0 0 0 0
`;
assert.deepEqual(plain(ctx.parseNetDev(netDev)), { rx: 1500, tx: 230 });
assert.deepEqual(plain(ctx.parseNetDev("")), { rx: 0, tx: 0 });
assert.deepEqual(plain(ctx.parseNetDev("garbage: a b c")), { rx: 0, tx: 0 });

assert.equal(ctx.shortRate(0), "0K");
assert.equal(ctx.shortRate(-5), "0K");
assert.equal(ctx.shortRate(512 * 1024), "512K");
assert.equal(ctx.shortRate(999 * 1024), "999K");
assert.equal(ctx.shortRate(1000 * 1024), "1.0M");
assert.equal(ctx.shortRate(1.26 * 1024 * 1024), "1.3M");
assert.equal(ctx.shortRate(87 * 1024 * 1024), "87M");
assert.equal(ctx.shortRate(3 * 1024 * 1024 * 1024), "3.0G");
for (const b of [0, 1023, 1024, 9.99 * 1048576, 10 * 1048576, 999.6 * 1048576, 1e15]) assert.ok(ctx.shortRate(b).length <= 4, String(b));

const historyRows = plain(ctx.parseHistoryFiles(`{"app":"mail","summary":"New","body":"Hi","image":"/a.png","urgency":2,"timestamp":200}
not json
null
{"summary":"Old","timestamp":100}
`));
assert.deepEqual(historyRows.map(r => r.summary), ["Old", "New"], "oldest first, broken lines left out");
assert.equal(historyRows[1].appName, "mail");
assert.equal(historyRows[1].urgency, 2);
assert.deepEqual(historyRows[0].actions, []);
assert.equal(historyRows[0].image, "");
assert.equal(ctx.parseHistoryFiles("").length, 0);

console.log("  devstatus checks pass");
