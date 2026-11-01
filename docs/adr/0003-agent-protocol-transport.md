# ADR-0003 — Agent protocol over a Unix socket

- Status: accepted
- Date: 2026-11-01

## Context
Agent CLIs need to publish status and ask for approval, and Kotilo Desktop shares the protocol. Hooks are short scripts, so the transport must be trivial to speak from any language. An approval lets a program run a command, so the UI must make a wrong or accidental yes hard.

## Options
1. **Unix socket with JSON lines** at `$XDG_RUNTIME_DIR/kotilo-agents.sock`.
2. **D-Bus**; richer, but needs a binding in every adapter and does not map onto Desktop's network link.

## Decision
Option 1, one JSON object per line. `KOTILO_AGENT_SOCKET` overrides the path, for tests. Client messages: `{type:"agent.status",id,tool,project,state,since}` with state running, awaiting, idle or done, and `{type:"agent.approval",id,command,cwd}`. The shell answers an approval only on the connection that asked: `{type:"agent.approval.reply",id,allow}`. If that connection closes, the request is withdrawn. Invalid lines are dropped and their content is never logged.

Approvals are shown by the `agents` plugin, not as notifications, so they work beside any notification daemon and ignore do not disturb. Popups never take the keyboard. Keyboard answers need the panel opened on purpose, and only `a` and `d` answer there, never Enter, and `a` waits until the panel is scrolled to its end. IPC can open the panel but cannot answer. Allow is hidden in a popup whose command does not fit, and control and bidirectional characters are replaced on display.

## Consequences
- Positive: an adapter is a few lines; the runtime directory's 0700 mode limits the socket to the user.
- Negative / risks: any process of the user can post a request, so the shown text is what the requester claims. Changing the wire format means changing Kotilo Desktop too.
- Follow-ups: adapters for agent CLIs, the agents list in the control center.
