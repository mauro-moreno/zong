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

