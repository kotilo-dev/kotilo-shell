# ADR-0013 — Claude Code hook adapter

- Status: accepted
- Date: 2026-11-01

## Context
Claude Code should appear in the bar and take approvals from it. Kotilo Desktop only observes through hooks and answers by sending keys to the terminal it owns; the shell owns no terminal, so a hook decision is its only way to answer. Tested on Claude Code 2.1.316: the terminal dialog opens while a `PermissionRequest` hook runs, the first answer applies, and a Yes in the terminal does not cancel the hook.

## Options
1. **`kotilo-agent hook claude`**, one Python entry for all events.
2. **A separate script per agent**; more files for a few lines of mapping.
3. **Installing the hooks automatically**; the installer would edit a file another program owns.

## Decision
Option 1, and the user adds the hooks. The hook decides only on an answer from the shell and otherwise prints nothing, so every failure leaves the terminal dialog in charge. Requests that exceed the protocol limit are not sent, because a cut request could hide what is approved. Each request gets a unique id, because the shell drops repeats and subagents share a session; the optional `agent` field links it to its session. Bash shows `command` and other tools their whole input; Claude's own `description` is not shown, since it is a claim. Panes of Kotilo Desktop (`AGENTHUB_PANE_ID`) report status but do not ask, and its internal runs (`AGENTHUB_INTERNAL=1`) stay silent.

## Consequences
- Positive: approvals work from any terminal, and removing the shell changes nothing for Claude Code.
- Negative / risks: a popup leaves when its session next reports a state, so a parallel subagent can remove another request from the bar; its terminal dialog stays open. Esc in the terminal cancels the hook, so its popup leaves, but no event follows and the session reads awaiting until the next prompt. Non-interactive runs wait for the hook's 600 s timeout and are then denied by Claude Code. The `agent` field is additive; Desktop may ignore it.
- Follow-ups: adapters for other CLIs as further `hook` choices.
