#!/bin/bash

# renpy-launcher.sh
# Ren'Py launcher with automatic SDK versioning, save sync, and screenshot handling

set -e  # Exit on critical errors

USB_PATH="/storage/BCB7-BF80/Games"
RUNTIME_PATH="/data/data/com.termux/files/home/renpy-arm64-runtime"
GAME_FOLDER="game"
VERSION_FILE_NAME=".renpy-version"

# ----------------------------------------------------------------------
# Helper: show menu and get user selection
# ----------------------------------------------------------------------
select_game() {
    local dirs=()
    local i=1

    while IFS= read -r dir; do
        dirs+=("$dir")
        echo "$i. $(basename "$dir")"
        ((i++))
    done < <(find "$USB_PATH" -maxdepth 1 -type d -not -name "." -not -name ".." | sort)

    if [ ${#dirs[@]} -eq 0 ]; then
        echo "Error: No game folders found in $USB_PATH"
        exit 1
    fi

    echo -n "Selection > "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#dirs[@]} ]; then
        echo "Invalid selection"
        exit 1
    fi

    selected_dir="${dirs[$((choice-1))]}"
    echo "- Selected: $(basename "$selected_dir")"
}

# ----------------------------------------------------------------------
# Step 1: Select game
# ----------------------------------------------------------------------
select_game

# ----------------------------------------------------------------------
# Step 2: Read engine version from script_version.txt
# ----------------------------------------------------------------------
VERSION_FILE="$selected_dir/$GAME_FOLDER/script_version.txt"
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: $VERSION_FILE not found. Cannot determine Ren'Py version."
    exit 1
fi

version_content=$(cat "$VERSION_FILE")
version=$(echo "$version_content" | grep -oE '[0-9]+' | tr '\n' '.' | sed 's/\.$//')
echo "- Detected Ren'Py version: $version"

# ----------------------------------------------------------------------
# Step 3: Prepare Ren'Py SDK (reuse if version matches)
# ----------------------------------------------------------------------
cd "$RUNTIME_PATH" 2>/dev/null || mkdir -p "$RUNTIME_PATH" && cd "$RUNTIME_PATH"

if [ -f "$VERSION_FILE_NAME" ] && [ "$(cat "$VERSION_FILE_NAME")" = "$version" ]; then
    echo "- SDK version matches, keeping runtime environment."
    # Remove old game folder and screenshots (if any)
    rm -rf "$GAME_FOLDER"
    rm -f screenshot*.png
else
    echo "- Preparing Ren'Py SDK $version..."
    rm -rf "$RUNTIME_PATH"/*
    mkdir -p "$RUNTIME_PATH"
    cd "$RUNTIME_PATH"

    SDK_URL="https://www.renpy.org/dl/$version/renpy-${version}-sdkarm.tar.bz2"
    echo "- Downloading SDK from $SDK_URL"
    curl -L --progress-bar "$SDK_URL" | tar -xj --strip-components=1 \
        "renpy-${version}-sdkarm/lib" \
        "renpy-${version}-sdkarm/renpy" \
        "renpy-${version}-sdkarm/renpy.sh" \
        "renpy-${version}-sdkarm/renpy.py"
    chmod +x renpy.sh
    echo "$version" > "$VERSION_FILE_NAME"
    echo "- SDK ready."
fi

# ----------------------------------------------------------------------
# Step 4: Copy game folder and screenshots to runtime
# ----------------------------------------------------------------------
echo "- Copying game files and screenshots..."

# Copy game folder
if command -v rsync >/dev/null 2>&1; then
    rsync -a --progress "$selected_dir/$GAME_FOLDER/" "$RUNTIME_PATH/$GAME_FOLDER/"
else
    cp -r "$selected_dir/$GAME_FOLDER" "$RUNTIME_PATH/"
fi

# Copy screenshots from game root to runtime root (if any)
shopt -s nullglob
screenshots=( "$selected_dir"/screenshot*.png )
if [ ${#screenshots[@]} -gt 0 ]; then
    cp "${screenshots[@]}" "$RUNTIME_PATH/"
fi
shopt -u nullglob

echo "- Copy success. Starting game..."

# ----------------------------------------------------------------------
# Step 5: Record modification times of all tracked files
# ----------------------------------------------------------------------
cd "$RUNTIME_PATH"

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# Store mtime for all files in game/ and root screenshots
find "$GAME_FOLDER" -type f -print0 > "$TEMP_FILE.files"
find . -maxdepth 1 -name "screenshot*.png" -type f -print0 >> "$TEMP_FILE.files"

while IFS= read -r -d '' file; do
    mtime=$(stat -c %Y "$file")
    printf "%s\t%s\n" "$mtime" "$file" >> "$TEMP_FILE"
done < "$TEMP_FILE.files"
rm -f "$TEMP_FILE.files"

# ----------------------------------------------------------------------
# Step 6: Run Ren'Py
# ----------------------------------------------------------------------
./renpy.sh

# ----------------------------------------------------------------------
# Step 7: Detect changed / newly created files
# ----------------------------------------------------------------------
clear
echo "Game has been closed. These are all the files that have changed/created:"

declare -A old_mtimes
while IFS=$'\t' read -r mtime file; do
    old_mtimes["$file"]="$mtime"
done < "$TEMP_FILE"

changed_files=()
# Check files in game/ and root screenshots
find "$GAME_FOLDER" -type f -print0 > "$TEMP_FILE.files2"
find . -maxdepth 1 -name "screenshot*.png" -type f -print0 >> "$TEMP_FILE.files2"

while IFS= read -r -d '' file; do
    current_mtime=$(stat -c %Y "$file")
    if [ -z "${old_mtimes[$file]}" ] || [ "${old_mtimes[$file]}" -ne "$current_mtime" ]; then
        changed_files+=("$file")
    fi
done < "$TEMP_FILE.files2"
rm -f "$TEMP_FILE.files2"

if [ ${#changed_files[@]} -eq 0 ]; then
    echo "(none)"
else
    for i in "${!changed_files[@]}"; do
        echo "$((i+1)). ${changed_files[$i]}"
    done
fi

# ----------------------------------------------------------------------
# Step 8: Ask to copy back
# ----------------------------------------------------------------------
echo -n "Do you wish to copy these files back to your USB drive? (yes/no) > "
read -r answer

if [[ "$answer" =~ ^[Yy](es)?$ ]]; then
    set +e  # allow per‑file errors to continue

    dest_root="$selected_dir"
    for file in "${changed_files[@]}"; do
        if [[ "$file" == "$GAME_FOLDER/"* ]]; then
            # Files inside game/ – copy to USB/game/
            rel="${file#$GAME_FOLDER/}"
            dest_file="$dest_root/$GAME_FOLDER/$rel"
        else
            # Screenshots – copy directly to USB root
            dest_file="$dest_root/$(basename "$file")"
        fi
        mkdir -p "$(dirname "$dest_file")"
        if cp "$file" "$dest_file"; then
            echo "Copied $file"
        else
            echo "Error copying $file" >&2
        fi
    done

    # Clean up: delete game folder and screenshots from runtime
    echo "Cleaning up runtime (game folder and screenshots)..."
    rm -rf "$RUNTIME_PATH/$GAME_FOLDER"
    rm -f "$RUNTIME_PATH"/screenshot*.png
    echo "Done."
else
    echo "No files copied. Exiting."
fi