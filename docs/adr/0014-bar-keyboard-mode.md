# ADR-0014 — Bar keyboard mode

- Status: accepted
- Date: 2026-11-01

## Context
The definition of done asks for every module to be keyboard reachable, but a layer-shell bar never receives the keyboard, and giving it permanently would take keys from applications. Third-party widgets must get this with little work, as tiles do (ADR-0009).

## Decision
`qs -c kotilo ipc call bar toggle` gives the bar on the focused output exclusive keyboard focus. Items join with `activeFocusOnTab`, so the order is the visual one. `Shell.barKey(event, item)` is the shared handler: Left and Right move and wrap, Enter and Space activate, Menu opens the context action, Esc leaves. `C.Pill` already uses it. Activating leaves keyboard mode first, because the panel it opens needs the keyboard. If no item can take focus the mode ends at once, so the keyboard can never be held by a bar with nothing to answer Esc. Focus also shows a pill's tooltip.

## Consequences
- Positive: every pill is reachable with no plugin code. Additive, so `apiVersion` becomes 1.5.0.
- Negative / risks: the user has to bind the command, since the shell does not own compositor keybindings. Enter does what a click does, so it can toggle Bluetooth or mute audio. Approvals are unaffected: the agents pill only opens the panel, where `a` and `d` still answer.
- Follow-ups: a default binding in compositor setup hints.
