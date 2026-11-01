# ADR-0015 — Dashboard panel and cards

- Status: accepted
- Date: 2026-11-01

## Context
The `dashboard.card` slot was reserved but nothing mounted it. Focus stats and developer status need a home that costs nothing while unused, and third-party cards should need little code.

## Decision
The `dashboard` plugin is a lazy panel opened by `qs -c kotilo ipc call dashboard toggle` or the palette. It mounts `dashboard.card` plugins as `kind: "qml"` items whose root is `C.Card`, in a two-column flow. Cards exist only while the panel is open, so a card fetches on load and has no background polling. Keyboard: an item joins with `activeFocusOnTab`, as in the bar (ADR-0014); Tab and the arrow keys move, Enter acts, Esc closes. External data is shown as plain text, and the pull request card opens only `https://github.com/` links.

## Consequences
- Positive: a card is one QML file with no idle cost. Additive, so `apiVersion` becomes 1.7.0.
- Negative / risks: data is only as fresh as the last opening. Opening the panel adds to the memory that panels keep (see `TODO.md`).
- Follow-ups: more cards from SPEC §3.6, such as CI status, calendar and todo.
