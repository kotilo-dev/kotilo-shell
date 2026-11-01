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

console.log("  devstatus checks pass");
