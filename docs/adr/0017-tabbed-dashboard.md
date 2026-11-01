# ADR-0017 — Tabbed dashboard

- Status: accepted
- Date: 2026-11-01

## Context
The dashboard should become one large panel, opened from the date and time, with tabs for cards, performance, agents, GitHub and RSS. Tabs should work like every other feature, and cost nothing while closed.

## Decision
A new `dashboard.tab` slot: a tab is a plugin whose root has `title`, `current` (set by the panel) and `key(event)`, which gets keys the panel does not use. Cards stay as the first tab. A tab loads on first visit and is gone when the panel closes, so a tab fetches on load and polls only while `current`. The panel owns ←→ and the number keys. `C.PickList` is the shared keyboard list.

The Agents tab shows state and pending requests but cannot answer: it opens the agents panel, so approvals keep one surface and the rules in ADR-0003. External text is plain text, and links open only over https to known hosts (GitHub) or over http or https (feeds). Feeds come only from the user's list, fetched with `curl` under size and time limits.

## Consequences
- Positive: third-party tabs, with no idle cost. Additive, so `apiVersion` becomes 1.12.0.
- Negative / risks: tab order for existing users comes from `settings.slots`. The first open of a tab pays its fetch. A feed reveals the user's address to its host, which is what a feed reader does.
