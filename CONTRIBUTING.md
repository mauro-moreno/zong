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

## Runbook (manual checks)
- 60 FPS render; stable physics (no jitter).
- Ball never escapes arena after 1000 bounces.
- Paddle collision sets angle as described in the design.
- Audio plays once per event (debounced).

## Code of Conduct
We use the Contributor Covenant.
