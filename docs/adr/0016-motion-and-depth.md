# ADR-0016 — Motion, state layers and depth

- Status: accepted
- Date: 2026-11-01

## Context
Panels appeared with a plain fade and vanished at once, hover was a different colour swap per component, and surfaces were flat with borders. The chosen direction is restrained: fast, strict and with little ornament.

## Decision
Theme has `animMs` (200, enter) and `fastMs` (100, exit and state changes), both 0 when animations are off. `C.Reveal` drives a panel: it fades and rises 8 px with OutCubic, and leaves with InCubic. It keeps the window alive during exit, but the panel gives up the keyboard and input as soon as it starts closing, so a key or click cannot act on something that is leaving. `C.StateLayer` is the one hover and press treatment (8 % and 12 %). Level 0 surfaces get a soft shadow and a hairline; level 1 cards are tonal, with a border only when it carries meaning. `C.Toggle` replaces on and off text.

The shadow uses `RectangularShadow` from Qt 6.9, in a file loaded by a `Loader`, because a missing QML type in a module stops the whole shell. Older Qt shows no shadow.

## Consequences
- Positive: one motion and hover language, and older Qt still runs. Additive, so `apiVersion` becomes 1.9.0.
- Negative / risks: a closing panel stays mapped for 100 ms. Shadows add a little memory while a panel is open.
