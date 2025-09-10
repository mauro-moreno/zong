# Contributing to Zong

Thanks for helping! This repo aims to be small, readable, and educational.

## Build

- Zig: use Mach’s **nominated Zig** for the branch you’re on (check docs / repo).
- Mach: follow the getting-started guide for examples, then run this project.

## Workflow

1. Choose an issue and comment “I’ll take this.”
2. Create a branch: `feat/<short-name>` or `fix/<short-name>`.
3. Keep PRs short; include a brief test plan (what you manually verified).
4. Link the issue (e.g., “Fixes #12”).  
5. Labels: `type:*`, `area:*`, priority `P0..P2`.

## Style

- Clear names, small functions, early returns.
- Fixed-timestep physics; avoid frame-dependent logic.
- Keep assets small; prefer procedural where possible.

## Tiger Style basics (read this before coding)

- **Build mode:** use **ReleaseSafe** locally; keep asserts and safety checks on.
- **Contracts:** validate at the call site and assert in the callee (pre + post conditions).
- **Allocations:** no dynamic allocation inside the game loop. If a feature needs it, preallocate at init or at level-load; otherwise open an issue to discuss.
- **Limits:** add hard caps for arrays, queue sizes, speeds, iterations, and frame time (drop back to menu if exceeded).
- **Determinism:** the simulation must not depend on wall clock or timers outside the fixed-step; use seeded RNG.
- **Control flow:** keep functions small; prefer early returns; avoid cleverness.
- **Dependencies:** discuss before adding any new external library.

## Tests & snapshots

- **Deterministic simulation tests:** feed recorded inputs with a fixed RNG seed for N frames and assert invariants (no tunneling, score increments exactly once, speed ≤ cap).
- **Snapshot checks:** render HUD/arena to an offscreen buffer and compare against a stored snapshot (allow a tiny tolerance).
- **Budget:** tests should be fast; prefer many tiny cases over a few large ones.

## Commits & PRs

- One change per commit; clear message; link the issue (e.g., “Fixes #12”).
- Keep PRs focused and include a short **test plan** (what you ran, what you saw).
- Use labels `type:*`, `area:*`, and priority `P0..P2`.

## Runbook (manual checks)

- 60 FPS render; stable physics (no jitter).
- Ball never escapes arena after 1000 bounces.
- Paddle collision sets angle as described in the design.
- Audio plays once per event (debounced).

## Code of Conduct

We use the Contributor Covenant.
