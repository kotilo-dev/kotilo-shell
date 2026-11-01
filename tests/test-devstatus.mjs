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

const ss = `LISTEN 0 4096 127.0.0.54:53 0.0.0.0:*
LISTEN 0 4096 127.0.0.53%lo:53 0.0.0.0:*
LISTEN 0 128 127.0.0.1:5173 0.0.0.0:*
LISTEN 0 128 [::1]:5173 [::]:*
LISTEN 0 128 0.0.0.0:3000 0.0.0.0:*
LISTEN 0 128 *:8080 *:*
LISTEN 0 128 192.168.1.5:9000 0.0.0.0:*
LISTEN 0 128 127.0.0.1:45871 0.0.0.0:*
LISTEN 0 128 127.0.0.1:631 0.0.0.0:*
`;
assert.deepEqual(plain(ctx.parseListeners(ss, [])), [3000, 5173, 8080]);
assert.deepEqual(plain(ctx.parseListeners(ss, [8080])), [3000, 5173]);
assert.deepEqual(plain(ctx.parseListeners("", [])), []);

console.log("  devstatus checks pass");
