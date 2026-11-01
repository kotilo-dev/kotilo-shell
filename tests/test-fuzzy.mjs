// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for Shell/internal/fuzzy.js. Run: node tests/test-fuzzy.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const src = readFileSync(new URL("../Shell/internal/fuzzy.js", import.meta.url), "utf8").replace(".pragma library", "");
const ctx = {};
vm.runInNewContext(src, ctx);
const { score, rank } = ctx;
const before = (q, a, b) => assert.ok(score(q, a) > score(q, b), `"${q}": "${a}" should beat "${b}"`);

assert.equal(score("", "anything"), 0);
assert.equal(score("xyz", "firefox"), -1);
assert.equal(score("ba", "ab"), -1);
assert.equal(score("firefox browser", "fire"), -1);
assert.ok(score("FIRE", "firefox") > 0, "case-insensitive");
assert.ok(score("vs code", "VS Code") > 0, "spaces in the query are ignored");

before("code", "Code", "Barcode Reader");
before("code", "VS Code", "Colored Dice");
before("fi", "Firefox", "Wifi Settings");
before("term", "Terminal", "Alacritty Terminal Emulator");
before("sc", "Slack Client", "Discord");
before("gh", "GitHub Desktop", "Rough Sketch");

assert.equal(rank("xyz", "Firefox", "web browser"), -1);
assert.ok(rank("browser", "Firefox", "web browser") > 0, "keywords still find a row");
assert.equal(rank("nord", "Disks", "storage partition format drive"), -1, "scattered letters in keywords are no match");
assert.ok(rank("sample", "Kotilotest Sample", "") > rank("sample", "LibreOffice Draw", "Vector Graphics Sample Map Plot Lines Editor"),
  "a title match beats a keyword match");

console.log("  fuzzy checks pass");
