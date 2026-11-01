# ADR-0006 — Plugin API is imported through `qs.*`

- Status: accepted
- Date: 2026-11-01

## Context
`docs/PLUGINS.md` promised `import Kotilo 1.0`, but no such module existed, and core plugins used relative imports that cannot work from `~/.config/kotilo/shell/plugins`. A plugin outside the shell loads from `file://`, and importing the shell by file path gives it a second copy of every singleton. A real `Kotilo` module would need `QML_IMPORT_PATH` set before launch, which `qs -c kotilo` and compositor autostart lines do not do.

## Decision
The plugin API is Quickshell's own root namespace: `import qs.Shell` (Theme, Settings, Shell, Log), `import qs.services as Services` and `import qs.components`. Core and third-party plugins use exactly these imports. Tested on Quickshell 0.3.2: a `file://` plugin gets the shell's single singleton instances. The runtime reads its validation rules from `plugins/schema/manifest.schema.json`, so the shell and `validate-manifests.py` share one definition.

## Consequences
- Positive: no launcher or environment setup, core plugins prove the public API, singletons stay single.
- Negative / risks: directory names (`Shell`, `services`, `components`) become public API, and `qs.*` depends on Quickshell behaviour that could change between versions.
- Follow-ups: freeze these names at API 1.0, and re-test external plugins on every Quickshell pin bump.
