# ADR-0010 — Git, Containers and Ports services

- Status: accepted
- Date: 2026-11-01

## Context
The bar's center modules need data from git, podman or docker, and the kernel's socket tables. None of them send change events, and the spec does not say which repository `bar.git` should show. The focused window is no reliable guide: terminals, editors and tmux expose a working directory differently or not at all.

## Decision
Three singletons poll, at intervals set by measured CPU cost: git every 10 s and containers every 2 minutes through `Shell.run`, ports every 5 s by reading `/proc/net/tcp` and `tcp6`. Spawning accounted for most idle CPU, so ports start no process, and `podman ps`, the costliest command at about 170 ms of CPU, runs least. The tools are found once at startup. `bar.git` shows the `repo` setting if set, otherwise the most recently touched repository under the `palette.projects` roots, rechecked every 60 s. Git runs with `--no-optional-locks` so polling never blocks a real git command. Ports lists listeners from 1024 to 32767 on loopback or all interfaces, minus an `exclude` list. Parsing lives in `services/devstatus.js`, so it can be tested without a compositor.

## Consequences
- Positive: no per-terminal integration, and each module hides itself when it has nothing to show.
- Negative / risks: the bar may show a repository other than the one being worked in; pinning `repo` is the way out. Polling adds process spawns against the idle CPU budget.
- Follow-ups: follow the focused terminal's directory if a compositor-neutral way appears.
