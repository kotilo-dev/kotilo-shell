# ADR-0007 — The 0.1 notification badge is passive

- Status: superseded by ADR-0002 while no other daemon runs; still the behaviour beside one
- Date: 2026-11-01

## Context
Roadmap 0.1 needs a notifications badge, but the notification daemon is 0.2 and ADR-0002 (own daemon or swaync) is undecided. Only one process can own `org.freedesktop.Notifications`. A `NotificationServer` in the shell would fail beside another daemon (Omarchy's shell owns the name on the dev machine), and with no other daemon it would accept notifications that nothing displays.

## Decision
`services/Notifications.qml` never registers on D-Bus in 0.1. It detects swaync, dunst or mako by their CLI, polls the count every 5 s, and `bar.notifications` hides itself when none is present.

## Consequences
- Positive: cannot swallow or block anyone's notifications, and does not pre-empt ADR-0002.
- Negative / risks: no badge on desktops whose notifications live elsewhere, including Omarchy's shell. The CLI parsing depends on those tools' output.
- Follow-ups: replace the backend with the real daemon in 0.2. The plugin's `count`/`open()` contract stays.
