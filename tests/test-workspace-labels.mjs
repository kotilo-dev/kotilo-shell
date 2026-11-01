// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for the bar.workspaces labels. Run: node tests/test-workspace-labels.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const src = readFileSync(new URL("../plugins/core/bar.workspaces/labels.js", import.meta.url), "utf8").replace(".pragma library", "");
const ctx = {};
vm.runInNewContext(src, ctx);
const expected = { 1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 9: "IX", 10: "X", 14: "XIV", 40: "XL", 90: "XC", 400: "CD", 1994: "MCMXCIV", 3999: "MMMCMXCIX" };
for (const [n, text] of Object.entries(expected)) assert.equal(ctx.roman(Number(n)), text);
for (const n of [0, -1, 4000, 1.5]) assert.equal(ctx.roman(n), String(n));
console.log("  workspace label checks pass");
