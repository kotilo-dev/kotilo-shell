// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for services/agentprotocol.js. Run: node tests/test-agentprotocol.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const src = readFileSync(new URL("../services/agentprotocol.js", import.meta.url), "utf8").replace(".pragma library", "");
const ctx = {};
vm.runInNewContext(src, ctx);
const { parse, reply, display } = ctx;
const plain = v => JSON.parse(JSON.stringify(v));
const line = o => JSON.stringify(o);

assert.deepEqual(plain(parse(line({ type: "agent.status", id: "a", tool: "claude", project: "p", state: "running", since: 5, extra: 1 }))),
    { type: "agent.status", id: "a", tool: "claude", project: "p", state: "running", since: 5 });
assert.deepEqual(plain(parse(line({ type: "agent.approval", id: "a", command: "ls" }))), { type: "agent.approval", id: "a", command: "ls", cwd: "", agent: "" });
assert.equal(parse(line({ type: "agent.approval", id: "a:1", agent: "a", command: "ls" })).agent, "a");

for (const bad of ["", "not json", "null", "[]", "5", line({ type: "other", id: "a" }), line({ type: "agent.status", state: "running" }),
                   line({ type: "agent.status", id: "a", state: "sleeping" }), line({ type: "agent.status", id: 5, state: "running" }),
                   line({ type: "agent.approval", id: "a" }), line({ type: "agent.approval", id: "a", command: "" }),
                   line({ type: "agent.approval", id: "a", command: 7 }), line({ type: "agent.approval", id: "a", command: "x".repeat(8193) }),
                   line({ type: "agent.approval", id: "a", command: "ls", agent: 5 }),
                   line({ type: "agent.approval", id: "a", command: "ls", agent: "x".repeat(129) }),
                   line({ type: "agent.status", id: "x".repeat(129), state: "idle" })])
    assert.equal(parse(bad), null, "should reject: " + bad.slice(0, 40));

assert.deepEqual(JSON.parse(reply("a", true)), { type: "agent.approval.reply", id: "a", allow: true });
assert.ok(reply("a", false).endsWith("\n"));

assert.equal(display("ls\nrm"), "ls\nrm");
assert.equal(display("a\u001b[2Jb"), "a�[2Jb");
assert.equal(display("safe‮gnp.exe"), "safe�gnp.exe");
assert.equal(display("a​b﻿"), "a�b�");

console.log("  agent protocol checks pass");
