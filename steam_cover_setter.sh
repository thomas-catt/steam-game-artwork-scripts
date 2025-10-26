#!/bin/bash
# find_steam_nonsteam_path.sh
# Finds Steam grid folder and shortcut ID for a non-Steam game
# Uses the first userdata directory as Steam user ID

STEAM_DIR="$HOME/.steam/steam"
USERDATA_DIR="$STEAM_DIR/userdata"

ART_PATH="$1"
GAME_NAME="$2"


if [ ! -d "$USERDATA_DIR" ]; then
  echo "❌ Steam userdata folder not found."
  exit 1
fi

# Pick the first Steam user folder
STEAM_ID=$(ls "$USERDATA_DIR" | grep -E '^[0-9]+$' | head -n 1)

if [ -z "$STEAM_ID" ]; then
  echo "❌ No valid Steam user directories found."
  exit 1
fi

GRID_DIR="$USERDATA_DIR/$STEAM_ID/config/grid"
mkdir -p "$GRID_DIR"

# Find shortcut ID from shortcuts.vdf (requires Python)
if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 required to parse Steam shortcuts."
  exit 1
fi

SHORTCUT_ID=$(GAME_NAME="$GAME_NAME" ICON_PATH="$ART_PATH/icon.png" python - <<'PYCODE'
import json, os, vdf, struct
home = os.path.expanduser("~/.steam/steam/userdata")
folders = [d for d in os.listdir(home) if d.isdigit()]
if not folders: exit(1)
user = folders[0]  # Pick f irst user directory
path = f"{home}/{user}/config/shortcuts.vdf"
game_name = os.environ.get("GAME_NAME", "").lower()
icon_path = os.environ.get("ICON_PATH", "").lower()
with open(path, "rb") as f:
    data = vdf.binary_loads(f.read())
    i = 0
    while str(i) in data['shortcuts']:
        app = data['shortcuts'][str(i)]
        if app['AppName'].lower() == game_name:
            signed_id = int(app['appid'])
            unsigned_id = signed_id & 0xFFFFFFFF
            print(unsigned_id)
            app['icon'] = icon_path
            with open(path, "wb") as fw:
                fw.write(vdf.binary_dumps(data))
            break
        i += 1
PYCODE
)

if [ -z "$SHORTCUT_ID" ]; then
  echo "❌ Could not find a matching non-Steam game. Check name in Steam."
  exit 1
fi

# Move or copy images into correct Steam grid filenames
[ -f "$ART_PATH/cover.png" ] && cp "$ART_PATH/cover.png" "$GRID_DIR/${SHORTCUT_ID}p.png"
[ -f "$ART_PATH/wide_cover.png" ] && cp "$ART_PATH/wide_cover.png" "$GRID_DIR/${SHORTCUT_ID}.png"
[ -f "$ART_PATH/background.png" ] && cp "$ART_PATH/background.png" "$GRID_DIR/${SHORTCUT_ID}_hero.png"
[ -f "$ART_PATH/logo.png" ] && cp "$ART_PATH/logo.png" "$GRID_DIR/${SHORTCUT_ID}_logo.png"
# [ -f "$ART_PATH/icon.png" ] && cp "$ART_PATH/icon.png" "$GRID_DIR/${SHORTCUT_ID}_icon.png"

echo "✅ Successfully set steam game artwork for $GAME_NAME. [$SHORTCUT_ID]"
echo "📁 Artwork directory:"
echo "$GRID_DIR"
