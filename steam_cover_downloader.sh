#!/bin/bash
# steam_cover_setter.sh
# Automates fetching cover art from SteamGridDB for a non-Steam game

API_BASE="https://www.steamgriddb.com/api/public"
OUT_DIR="$HOME/.local/share/steam_covers"

mkdir -p "$OUT_DIR"

GAME_NAME=$1

if [ -z "$1" ]; then
  read -p "Enter game name: " GAME_NAME
fi


# 1️⃣ Search for game ID
echo "Searching SteamGridDB for '$GAME_NAME'..."
SEARCH_RESPONSE=$(curl -s -X POST "$API_BASE/search/main/games" \
  -H "Content-Type: application/json" \
  -d '{
        "asset_type": "grid",
        "term": "'"$GAME_NAME"'",
        "offset": 0,
        "filters": {
          "styles": ["all"],
          "dimensions": ["all"],
          "type": ["all"],
          "order": "score_desc"
        }
      }')

GAME_ID=$(echo "$SEARCH_RESPONSE" | jq -r '.data.games[0].game.id')
GAME_FULL_NAME=$(echo "$SEARCH_RESPONSE" | jq -r '.data.games[0].game.name')

if [ "$GAME_ID" == "null" ] || [ -z "$GAME_ID" ]; then
  echo "❌ Game not found on SteamGridDB."
  exit 1
fi

echo "✅ Found game: $GAME_FULL_NAME (id: $GAME_ID)"

# 2️⃣ Fetch art data for the game
ART_RESPONSE=$(curl -s "$API_BASE/game/$GAME_ID/home" \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: en-US,en;q=0.9,ja-JP;q=0.8,ja;q=0.7' \
  -H 'priority: u=1, i' \
  -H "referer: https://www.steamgriddb.com/game/$GAME_ID" \
  -H 'sec-ch-ua: "Google Chrome";v="141", "Not?A_Brand";v="8", "Chromium";v="141"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Linux"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36')

echo "✅ Fetched game art: $GAME_ID"

# 3️⃣ Extract URLs
COVER_URL=$(echo "$ART_RESPONSE" | jq -r '.data.grids[0].url')
WIDE_URL=$(echo "$ART_RESPONSE" | jq -r '.data.grids[] | select(.width > .height) | .url' | head -n 1)
BACKGROUND_URL=$(echo "$ART_RESPONSE" | jq -r '.data.heroes[0].url')
LOGO_URL=$(echo "$ART_RESPONSE" | jq -r '.data.logos[0].url')
ICON_URL=$(echo "$ART_RESPONSE" | jq -r '.data.icons[0].url')

# 4️⃣ Download all
GAME_DIR="$OUT_DIR/$GAME_NAME"
mkdir -p "$GAME_DIR"

download_image() {
  local url="$1"
  local filename="$2"
  if [ "$url" != "null" ] && [ -n "$url" ]; then
    echo "⬇️ Downloading $filename..."
    curl -s -L "$url" -o "$GAME_DIR/$filename"
  else
    echo "⚠️ No $filename available."
  fi
}

download_image "$COVER_URL" "cover.png"
download_image "$WIDE_URL" "wide_cover.png"
download_image "$BACKGROUND_URL" "background.png"
download_image "$LOGO_URL" "logo.png"
download_image "$ICON_URL" "icon.png"

echo ""
echo "✅ Images saved to: $GAME_DIR"
echo "  Cover Art → $GAME_DIR/cover.png"
echo "  Wide Cover → $GAME_DIR/wide_cover.png"
echo "  Background → $GAME_DIR/background.png"
echo "  Logo → $GAME_DIR/logo.png"
echo "  Icon → $GAME_DIR/icon.png"

echo "Opened in file explorer, close it to continue the script."
dolphin "$GAME_DIR" ;
echo "Proceeding to set these artworks to Steam. Press Enter to proceed, Ctrl+C to cancel.";
echo;
read;
./steam_cover_setter.sh "$GAME_DIR" "$GAME_NAME"
