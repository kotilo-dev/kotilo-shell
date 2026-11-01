# ADR-0002 — Own notification daemon

- Status: accepted (supersedes the 0.1 limits in ADR-0007)
- Date: 2026-11-01

## Context
The spec needs per-app grouping, history and, in 0.3, agent approvals with inline Allow/Deny routed back through the agent protocol. swaync cannot express that last part without being patched or wrapped. Only one process can own `org.freedesktop.Notifications`, and desktops such as Omarchy already have an owner, so taking the name by accident would break notifications elsewhere.

## Options
1. **Own daemon** on Quickshell's `NotificationServer`, drawn with theme tokens.
2. **Integrate swaync** through its CLI; less code, but a separate theme and no approval class.

## Decision
Own daemon, in `services/Notifications.qml`, with UI in the `notifications` plugin. The shell never takes the name from another owner. It claims the name if it is free after a 5 s grace period, which lets another daemon started at login win, or at once if this process already owns it after a reload. While another daemon owns it, the shell keeps the ADR-0007 passive behaviour and rechecks every 15 s. `plugins.notifications.daemon: false` turns the daemon off.

## Consequences
- Positive: one look, approvals become possible, and installing the shell cannot break an existing daemon.
- Negative / risks: history is in memory only. A daemon started more than 5 s after the shell loses the name to it.
- Follow-ups: agent approval class (0.3), persistent history, DND control from the control center.
