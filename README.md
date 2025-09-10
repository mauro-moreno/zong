# Zong — a tiny Pong clone in Zig + Mach

[![status](https://img.shields.io/badge/status-WIP-purple.svg)](#)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](#license)
[![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

**Zong** is a small, educational **Pong** clone built with **[Zig](https://ziglang.org/)** and the **[Mach](https://github.com/hexops/mach)** ecosystem.  
The goal: a tiny codebase with **fixed-timestep physics**, **crisp 2D rendering**, and a path to nicer visuals via **shaders** as the project grows.

> Why? To learn Zig/Mach well, keep the game polished-but-simple, and create a base you can reuse for future 2D experiments.

---

## Features (v0.x goals)

- 🎯 **Deterministic, fixed-timestep** physics (no frame-dependent logic)
- 🧱 **Circle vs AABB** collisions, paddle “english” (angle from impact offset)
- 🎮 **2-player local** (W/S and ↑/↓), pause (Esc), quick reset (R)
- 🔊 **Minimal SFX** (bounce / score / win)
- 🔢 **Bitmap score** (spritesheet digits) that scales with a **virtual resolution**
- 🤖 **Single-player AI** (intercept prediction + simple PD controller)
- ✨ Optional **post-fx shaders** (CRT/scanline/vignette/palette) as the engine matures

---

## Controls

- **Left paddle:** `W` / `S`  
- **Right paddle:** `↑` / `↓`  
- **Pause:** `Esc`  
- **Restart round:** `R`

---

## Quick start

> You’ll need the **Zig nightly nominated by Mach** for the branch you’re using (the project will note the exact commit in releases).  
> Platforms: desktop (Windows / macOS / Linux).

```bash
# clone
git clone https://github.com/mauro-moreno/zong.git
cd zong

# build & run (placeholder until the first tag)
zig build run
```

If you hit issues, make sure your Zig matches the nominated version for Mach (and that submodules / dependencies are set per the repo instructions once they land).

---

## Roadmap & milestones

- **Roadmap:** see [`ROADMAP.md`](./ROADMAP.md) for planned versions:
  - `v0.1.0` Playable core (two players, scoring to 11)
  - `v0.2.0` UX & SFX
  - `v0.3.0` Single-player
  - `v1.0.0` Polish & packaging
- **Project board:** *Zong Roadmap* (GitHub Projects) tracks milestones **M1--M10** and weekly iterations.

---

## Project structure

```
/src/              # Zig source
/shaders/          # WGSL/GLSL shader programs (treated as code)
/assets/
  /audio/          # SFX (WAV/OGG)
  /images/         # bitmap digits, logos, etc.
ROADMAP.md
CONTRIBUTING.md
LICENSE            # code license (MIT)
assets/LICENSE     # assets license (CC0)

```

---

## Design notes

- **Virtual resolution** (e.g., 800×600) decouples gameplay/physics from window size.
- **Physics:** fixed step (e.g., 120 Hz accumulator), render at display refresh; clamp long frames.
- **Paddle bounce law:** hit farther from the center → larger outgoing angle (with optional carry from paddle `vy`).
- **AI:** predict intercept `y` at the AI paddle's `x` (account for up to two wall bounces), then PD-control to target.

---

## Tiger Style

**Why:** clarity, safety, and determinism—so the code stays tiny and robust as we grow.

**Principles we adopt (adapted from TigerBeetle’s Tiger Style):**
- **ReleaseSafe by default:** runtime safety checks and assertions stay on.
- **Two-sided contracts:** the caller validates inputs; the callee asserts invariants and post-conditions.
- **Limits everywhere:** hard caps for counts/sizes/speeds (e.g., max ball speed, max SFX voices, max frame delta).
- **Static after init:** no dynamic allocation inside the hot game loop; preallocate pools at startup.
- **Deterministic sim & snapshots:** tests drive fixed-seed simulations and compare stable outputs (e.g., HUD).
- **Simple control flow:** small functions, early returns, straightforward data structures.
- **Minimal dependencies:** keep the surface area small (Mach + the essentials).

**What this means for Zong:**
- Build mode targets **ReleaseSafe** during development and early releases.
- A “no-alloc after init” guard panics if anything allocates in the loop.
- Preallocated pools for frame memory, physics state, sprite batches, audio voices, and input buffers.
- Invariants are asserted (e.g., speed never exceeds cap; ball never leaves arena bounds).
- Tests run deterministic simulations (fixed seed/inputs) and snapshot the HUD/arena for regressions.

---

## Shaders

Zong treats **shaders as code** (MIT/Apache-2.0)---so they can be reused across projects without CC ambiguities.

- **Full-screen fx** (prefix `fx_`): CRT/scanline, vignette, palette mix, subtle bloom.
- **Sprite materials** (prefix `mat_`): simple color grading / tinting knobs.
- **Uniforms (suggested):** `time`, `resolution`, `bloom_amount`, `vignette_amount`, `crt_amount`, `scanline_thickness`, `palette_mix`.

*If you contribute shaders, please include an `SPDX-License-Identifier` header and a short docstring describing uniforms & defaults.*

---

## Contributing

Contributions are very welcome---especially **small, focused PRs**.

- Read [`CONTRIBUTING.md`](./CONTRIBUTING.md) for build notes, workflow, and the manual test runbook.
- Look for issues labeled **good first issue** and **P1**.
- Use labels: `type:*`, `area:*`, `P0|P1|P2`.
- Keep gameplay deterministic; avoid new dependencies unless they're clearly justified.

> Code of Conduct: Contributor Covenant (short and simple).

---

## Releasing

- Use semver: `0.1.0` (playable core), `0.2.0` (UX/SFX), `0.3.0` (single-player), `1.0.0` (polish).
- Each release notes the **pinned Zig** and **Mach** versions and can include desktop binaries.

---

## License

- **Code (including shaders):** **MIT** (see [`LICENSE`](./LICENSE)).
- **Game assets** (images/audio in `/assets`): **CC0 1.0** by default (see [`/assets/LICENSE`](./assets/LICENSE)).
  - If you submit assets under **CC BY-4.0**, say so in the asset's folder README.

> "Pong" is a classic genre; **Zong** is original work and not affiliated with any trademark holder.

---

## Acknowledgments

- The **Mach** project and maintainers.
- The **Zig** community for tooling and examples.

---

## FAQ

**Why Zig + Mach instead of Godot/Unity/etc.?**\
To learn & keep control. This project favors **clarity and minimalism** over features.

**Will Zong run in the browser or on mobile?**\
Desktop first. Web/mobile may come later depending on Mach's trajectory.

**How can I suggest features?**\
Open a GitHub Discussion or a labeled issue (`type:feature`, include acceptance criteria).

