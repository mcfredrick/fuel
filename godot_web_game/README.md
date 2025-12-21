# Godot Web Game

A simple 2D game built with Godot Engine that can be exported to web.

## Controls
- **Arrow Keys**: Move the player
- **Space**: Spend a turbo star for a short mega-fart burst

## How to Run

1. Open the project in Godot Engine
2. Click the "Play" button in the top-right corner
3. **Or from the terminal:**  
   ```bash
   cd godot_web_game
   godot --path .
   ```
   (Add `--headless` if you only need to export assets.)

## How to Export for Web

### 1. Install export templates (one-time / per-version)

```bash
# From repo root
./install_godot_export_templates.sh 4.5.1
```

This script downloads the official template archive into the OS-specific location Godot expects:

- macOS: `~/Library/Application Support/Godot/export_templates/4.5.1.stable`
- Linux: `~/.local/share/godot/export_templates/4.5.1.stable`

If you’re inside the editor, you can still use Project → Install Export Templates as usual—the script just automates it for CLI and CI.

### 2. Export using the helper script

```bash
./export_web.sh
```

What it does:

1. Ensures templates for `GODOT_VERSION` (default `4.5.1`) are present by calling the installer.
2. Runs a headless release export using the `Web` preset.
3. Outputs the build to `godot_web_game/build/web/`.

Set `GODOT_BIN` if your Godot executable isn’t on PATH. Use `SKIP_TEMPLATE_INSTALL=1` if you’ve already installed templates and want to skip the check.

### 3. Manual fallback inside the editor

1. In Godot, go to Project → Export.
2. Select the `Web` preset (or add it if missing).
3. Click “Export Project…”, choose `godot_web_game/build/web`, and save.

## Project Structure

- `scenes/` - Contains all game scenes
- `scripts/` - Contains all GDScript files
- `art/` - Placeholder for game assets

## Requirements

- Godot Engine 4.0 or later
- Web browser (for testing web export)

## Deployment (GitHub Pages)

A GitHub Actions workflow (`.github/workflows/deploy.yml`) already:

1. Checks out `main`.
2. Installs Godot headless + export templates via the same installer script.
3. Runs `./export_web.sh`.
4. Uploads `godot_web_game/build/web` and deploys to GitHub Pages.

To activate Pages, go to **Repo Settings → Pages → Build and deployment → Source: GitHub Actions**. After the first successful workflow run on `main`, Pages will serve the latest build automatically.
