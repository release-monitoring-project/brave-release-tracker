#!/bin/bash

OWNER="brave"
REPO="brave-browser"
API_URL="https://api.github.com/repos/$OWNER/$REPO/releases/latest"
LOG_FILE="brave_release_fetch.log"
OUTPUT_JSON="brave_download_links.json"

echo "[$(date)] Starting Brave ZIP release fetch..." > "$LOG_FILE"

# Fetch latest release info and assets
RELEASE_JSON=$(curl -s "$API_URL")
TAG_NAME=$(echo "$RELEASE_JSON" | jq -r .tag_name)
RELEASE_URL=$(echo "$RELEASE_JSON" | jq -r .html_url)
ASSETS=$(echo "$RELEASE_JSON" | jq -c '.assets[]')

echo "[$(date)] Latest release tag: $TAG_NAME" >> "$LOG_FILE"

# Collect Downloads
declare -A ZIPS
declare -A SHAS

while IFS= read -r asset; do
    NAME=$(echo "$asset" | jq -r .name)
    URL=$(echo "$asset" | jq -r .browser_download_url)

    if [[ "$NAME" == *.zip ]]; then
        case "$NAME" in
            *win32-x64.zip) ZIPS["windows_x64"]="$URL" ;;
            *win32-arm64.zip) ZIPS["windows_arm64"]="$URL" ;;
            *darwin-x64.zip) ZIPS["macos_x64"]="$URL" ;;
            *darwin-arm64.zip) ZIPS["macos_arm64"]="$URL" ;;
            *linux-amd64.zip) ZIPS["linux_x64"]="$URL" ;;
            *linux-arm64.zip) ZIPS["linux_arm64"]="$URL" ;;
        esac
    elif [[ "$NAME" == *.zip.sha256 ]]; then
        BASE="${NAME%.sha256}"
        for key in "${!ZIPS[@]}"; do
            if [[ "${ZIPS[$key]}" == *"$BASE" ]]; then
                SHAS["$key"]="$URL"
            fi
        done
    fi
done <<< "$ASSETS"

# Build json structure
WINDOWS_JSON=""
MACOS_JSON=""
LINUX_JSON=""

for key in "${!ZIPS[@]}"; do
    OS="${key%%_*}"
    ARCH="${key##*_}"
    ZIP="${ZIPS[$key]}"
    SHA="${SHAS[$key]}"

    ENTRY="\"$ARCH\": {\"zip\": \"$ZIP\", \"sha256\": \"$SHA\"}"

    case "$OS" in
        windows) WINDOWS_JSON="${WINDOWS_JSON}${ENTRY}," ;;
        macos)   MACOS_JSON="${MACOS_JSON}${ENTRY}," ;;
        linux)   LINUX_JSON="${LINUX_JSON}${ENTRY}," ;;
    esac
done

WINDOWS_JSON="{${WINDOWS_JSON%,}}"
MACOS_JSON="{${MACOS_JSON%,}}"
LINUX_JSON="{${LINUX_JSON%,}}"

# Create and write output
jq -n \
  --arg tag "$TAG_NAME" \
  --arg releasePage "$RELEASE_URL" \
  --argjson windows "$WINDOWS_JSON" \
  --argjson macos "$MACOS_JSON" \
  --argjson linux "$LINUX_JSON" \
  '{
    tag: $tag,
    releasePage: $releasePage,
    downloads: {
      windows: $windows,
      macos: $macos,
      linux: $linux
    }
  }' > "$OUTPUT_JSON"

echo "[$(date)] JSON written to $OUTPUT_JSON" >> "$LOG_FILE"
echo "[$(date)] Script completed." >> "$LOG_FILE"
