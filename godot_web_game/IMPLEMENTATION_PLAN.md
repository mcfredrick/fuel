# Godot Web Game Implementation Plan

## Overview
This document breaks down the TODO list into actionable workstreams with suggested tooling, asset needs, and validation criteria. Tackle the items roughly in the order shown, but feel free to parallelize independent tasks (e.g., audio design versus CI/CD setup).

---

## 1. Core Quality & Testing
### 1.1 Add unit tests for core mechanics
- **Scope mechanics**: player movement, fuel depletion, collisions, objective tracking, win/lose transitions.
- **Approach**:
  1. Identify existing GDScript classes (e.g., `player.gd`, `main.gd`) and extract logic into testable scripts where necessary.
  2. Use Godot's built-in `GUT` or `WAT` test framework; add to project as an addon.
  3. Write tests covering deterministic behaviors (physics-free logic, resource counters), mock signals for scene events.
  4. Integrate tests into CI so they run automatically.
- **Exit criteria**: Tests run via CLI (`godot --headless --test`) with >80% coverage on critical scripts.

### 1.2 Keep tests up to date
- Add "tests required" checklist in PR template or `CONTRIBUTING.md`.
- Enable coverage badge or status in CI dashboard to keep visibility high.

---

## 2. Gameplay Additions
### 2.1 Add cats that scratch you and deplete fuel
- **Design**: Define cat behaviors (patrol, chase, idle). Decide scratch damage amount & cooldown.
- **Implementation**:
  1. Create `Cat` scene inheriting from `KinematicBody2D`/`CharacterBody2D` with animation states.
  2. Add Area2D hitbox to detect overlap with player; on contact emit signal to reduce fuel.
  3. Update HUD to reflect sudden fuel drops and add temporary screen shake or SFX.
- **Testing**: Unit-test fuel reduction logic; playtest to balance cat speed/damage.

### 2.2 Add objectives to collect items
- Create `Collectible` base scene with metadata (type, value, related quest).
- Implement objective tracker UI (list of active goals, progress).
- Hook into score/fuel systems for rewards; trigger completion signal when count met.

### 2.3 Add objectives to travel to locations
- Define location markers on a world map; use Area2D triggers.
- Tie into same objective tracker: e.g., "Reach The Bakery".
- Provide mini-map or arrow guidance if screen scrolls.

### 2.4 Add obstacles to avoid
- Inventory possible obstacle types: stationary hazards, moving projectiles, environmental blockers.
- Create modular obstacle scenes with configurable difficulty (damage, speed) for reuse across levels.

### 2.5 Add levels with increasing difficulty
- Build a `LevelConfig` resource describing layout, objectives, obstacle density, cat behavior intensity.
- Update main scene loader to advance levels after objectives complete.
- Persist progression (in-memory for now; later save to local storage).

### 2.6 Add scrolling background & offscreen travel
- Convert main scene camera to `Camera2D` with smoothing and limits.
- Replace static background with parallax layers; extend tilemap/world to support larger play area.
- Ensure spawning of entities is dynamic based on viewport.

### 2.7 Add different locations with unique themes
- Create theme presets (palette, background art, enemy/obstacle mix, food types).
- Build content pipeline: `themes/<name>/` folder with textures, audio cues, JSON config.
- Update level configs to reference theme presets.

### 2.8 Add leaderboard with top-ten initials entry
- **Data model**: Define `LeaderboardEntry` with fields: initials (3 chars), score, timestamp, level/difficulty.
- **Persistence**: Use browser `localStorage` for client-side storage; consider JSON format for easy inspection.
- **UI flow**:
  1. On game over, check if score qualifies for top 10.
  2. Show initials entry screen (3-character limit, alphanumeric only).
  3. Insert into sorted list and display updated leaderboard.
- **Validation**: Prevent duplicate initials manipulation; sanitize input; enforce max 10 entries.
- **Optional future**: Server-side leaderboard via GitHub API or a free backend if cheating concerns arise.

---

## 3. Distribution & Tooling
### 3.1 Host game online (GitHub Pages)
- Build web export preset in Godot (`HTML5`).
- Add export script (e.g., `export_web.sh`) that outputs to `build/web/`.
- Use GitHub Actions to run export and copy to `gh-pages` branch (or `/docs` folder for user site).
- Document manual publish steps for fallback.

### 3.2 Set up CI/CD pipeline
- Choose GitHub Actions workflow:
  1. Install Godot Headless + templates.
  2. Run unit tests.
  3. Perform web export artifact upload.
  4. On main branch, deploy to Pages.
- Include cache for Godot download to speed up builds.

### 3.3 Test on different browsers/devices
- Prepare test matrix: Chrome, Firefox, Safari; iOS Safari, Android Chrome.
- Automate basic smoke tests using Playwright or BrowserStack (optional) and document manual checklist for touch controls.
- Capture known issues in README.

---

## 4. Documentation & UX Enhancements
### 4.1 Create README with instructions
- Sections: Overview, Controls, Objective, Development setup, Running tests, Deployment.
- Include screenshots/GIFs and link to playable build.

### 4.2 Add sound effects & background music
- Outline audio style per theme (fun, whimsical, etc.).
- Source or compose assets (ensure licensing).
- Integrate via Godot `AudioStreamPlayer` nodes; add global audio manager for mixing and settings (volume sliders).
- Provide mute toggle in UI; test for overlapping sounds.

### 4.3 Optimize performance & memory usage
- Profile with Godot profiler in browser export.
- Optimize textures (atlas, compressed formats) and limit draw calls with sprite sheets.
- Pool frequently spawned objects (bullets, collectibles).
- Verify GC pressure in HTML5 export; avoid unnecessary allocations in `_process`.

---

## 5. Tracking & Validation
- Maintain Kanban board or GitHub Projects column for each workstream.
- Add milestones aligned to sections above (Gameplay Core, Hosting, Polish).
- After each milestone, run full regression (tests + manual play) and update README/CHANGELOG.

---

## Suggested Order of Execution
1. **Testing foundation** – ensures future work stays stable.
2. **Gameplay features (cats, objectives, obstacles, levels, scrolling, themes, leaderboard)** – iteratively add and balance.
3. **Tooling & hosting (CI/CD, GitHub Pages)** – once game loop playable.
4. **Documentation, audio, performance polish** – final quality pass.

Use this plan as a living document; update sections with decisions, asset links, and timing estimates as work progresses.
