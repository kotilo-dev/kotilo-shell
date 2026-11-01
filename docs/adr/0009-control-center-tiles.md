# ADR-0009 — Control center tiles

- Status: accepted
- Date: 2026-11-01

## Context
`controlcenter.tile` is named in the spec but has no contract, and the keyboard must reach every tile, third-party ones included. Plugins also have no way to see other plugins' slots, which a panel hosting tiles needs.

## Decision
A tile is a `kind: "qml"` plugin in `controlcenter.tile` whose root is `C.Tile`. It sets `title`, `subtitle`, `icon`, `active` and `available`, and handles `activated()`. The panel owns selection and calls `activate()`, so a tile needs no keyboard code. `SlotRow` hands its `host` to any plugin with a `host` property. The panel opens with `Shell.toggleControlCenter()` or IPC (`qs -c kotilo ipc call controlcenter toggle`). Night light, VPN and screen share tiles wait for a compositor-neutral backend; the Focus Mode tile comes with Focus Mode in 0.3.

## Consequences
- Positive: third-party tiles get mouse and keyboard handling for free. Additive, so `apiVersion` becomes 1.2.0.
- Negative / risks: a plugin that receives `host` can read every plugin's manifest. QML has no sandbox, so this adds no new exposure.
- Follow-ups: more tiles, the agents list (0.3).
