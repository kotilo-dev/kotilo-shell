// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for Shell/internal/schemaform.js. Run: node tests/test-schemaform.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const src = readFileSync(new URL("../Shell/internal/schemaform.js", import.meta.url), "utf8").replace(".pragma library", "");
const ctx = {};
vm.runInNewContext(src, ctx);
const { fields, step, parse, display, move } = ctx;

const schema = { properties: {
    on: { type: "boolean", default: true, title: "Enabled" },
    count: { type: "integer", default: 5, minimum: 1, maximum: 6 },
    ratio: { type: "number", default: 0.5 },
    name: { type: "string" },
    side: { type: "string", enum: ["left", "right"], default: "left" },
    list: { type: "array", default: [] },
    map: { type: "object" }
} };
const f = fields(schema, { count: 2 });
const by = key => f.find(x => x.key === key);
assert.deepEqual(Array.from(f.map(x => x.kind)), ["boolean", "integer", "number", "string", "enum", "other", "other"]);
assert.equal(by("on").title, "Enabled");
assert.equal(by("count").title, "count");
assert.equal(by("count").value, 2, "a stored value beats the default");
assert.equal(by("on").value, true, "the default fills a missing value");
assert.equal(fields({ properties: { off: { type: "boolean", default: true } } }, { off: false })[0].value, false, "false is a value");
assert.equal(fields(null, null).length, 0);
assert.equal(fields({}, {}).length, 0);

assert.equal(step(by("on"), 1), false);
assert.equal(step(fields({ properties: { n: { type: "integer", default: 6, maximum: 6 } } }, {})[0], 1), 6, "stays at maximum");
assert.equal(step(fields({ properties: { n: { type: "integer", default: 1, minimum: 1 } } }, {})[0], -1), 1, "stays at minimum");
assert.equal(step(by("count"), 1), 3);
assert.equal(step(by("side"), 1), "right");
assert.equal(step(fields({ properties: { s: { enum: ["a", "b"], default: "a" } } }, {})[0], -1), "b", "enum wraps");
assert.equal(step(by("name"), 1), undefined);
assert.equal(step(by("list"), 1), undefined);

const value = (r) => { assert.equal(r.ok, true); return r.value; };
assert.equal(value(parse(by("count"), " 3 ")), 3);
assert.equal(value(parse(by("ratio"), "0.25")), 0.25);
assert.equal(value(parse(by("name"), "")), "");
for (const bad of ["", "  ", "abc", "1.5", "0", "7", "Infinity", "NaN"]) assert.equal(parse(by("count"), bad).ok, false, "refuse: " + bad);
assert.equal(parse(by("list"), "[]").ok, false);
assert.equal(parse(by("side"), "up").ok, false);

assert.equal(display(by("on")), "on");
assert.equal(display(by("count")), "2");
assert.equal(display(by("name")), "not set");
assert.equal(display(by("list")), "edit in settings.json");

const rows = [{ heading: "A" }, { field: {} }, { field: {} }, { heading: "B" }, { field: {} }];
assert.equal(move(rows, 1, 1), 2);
assert.equal(move(rows, 2, 1), 4, "skips a heading");
assert.equal(move(rows, 4, 1), 1, "wraps past a heading");
assert.equal(move(rows, 1, -1), 4, "wraps backwards");
assert.equal(move([{ heading: "A" }], 0, 1), 0, "no fields, no move");

console.log("  schema form checks pass");
