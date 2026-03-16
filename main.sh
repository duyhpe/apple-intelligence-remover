#!/bin/bash

set -e

MODEL_PATHS=(
"/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels"
"/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual"
"/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels"
"/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual"
"/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels"
"/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual"
)

CACHE_PATHS=(
"$HOME/Library/Caches/com.apple.intelligence"
"$HOME/Library/Caches/com.apple.siri"
"/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels"
"/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual"
)

FOUND_PATHS=()

echo
echo "Apple Intelligence Remover"
echo "--------------------------------------"
echo

check_status() {
echo "Checking Apple Intelligence status..."
STATUS=$(defaults read com.apple.Siri AppleIntelligenceEnabled 2>/dev/null || echo "0")

if [[ "$STATUS" == "1" ]]; then
echo "Apple Intelligence: ENABLED"
else
echo "Apple Intelligence: DISABLED"
fi
echo
}

scan_models() {

echo "Scanning for AI model files..."
echo

FOUND_PATHS=()
TOTAL_SIZE=0

for path in "${MODEL_PATHS[@]}" "${CACHE_PATHS[@]}"
do
if [ -d "$path" ]; then
SIZE=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
if [[ -n "$SIZE" ]]; then
SIZE_BYTES=$((SIZE*1024))
FOUND_PATHS+=("$path")
TOTAL_SIZE=$((TOTAL_SIZE+SIZE_BYTES))
echo "Found: $path"
du -sh "$path"
echo
fi
fi
done

if [[ ${#FOUND_PATHS[@]} -eq 0 ]]; then
echo "No removable files found."
else
echo "Total size:"
echo $TOTAL_SIZE | awk '{ printf "%.2f GB\n", $1/1024/1024/1024 }'
fi

echo
}

disable_ai() {
echo "Disabling Apple Intelligence..."

defaults write com.apple.Siri AppleIntelligenceEnabled -bool false
defaults write com.apple.Siri LLMEnable -bool false

echo "Done."
echo
}

remove_models() {

if [[ ${#FOUND_PATHS[@]} -eq 0 ]]; then
echo "Nothing to remove."
return
fi

echo
echo "The following directories will be removed:"
printf '%s\n' "${FOUND_PATHS[@]}"
echo

read -p "Continue? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
echo "Cancelled."
return
fi

for path in "${FOUND_PATHS[@]}"
do
echo "Removing $path"

if sudo rm -rf "$path" 2>/dev/null; then
echo "Removed."
else
echo "Could not remove (likely SIP protected)."
fi

echo
done
}

generate_recovery_script() {

SCRIPT="$HOME/Desktop/remove_apple_intelligence.sh"

echo "Generating recovery script..."

cat <<EOF > "$SCRIPT"
#!/bin/bash

echo "Apple Intelligence Removal"

diskutil mount "Macintosh HD - Data" 2>/dev/null || diskutil mount "Data"

rm -rf /Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels
rm -rf /Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual

echo "Done."
EOF

chmod +x "$SCRIPT"

echo "Saved to:"
echo "$SCRIPT"
echo
}

menu() {

echo "Select an option:"
echo
echo "1) Check Apple Intelligence status"
echo "2) Scan for AI models"
echo "3) Disable Apple Intelligence"
echo "4) Remove model files"
echo "5) Generate Recovery script"
echo "6) Exit"
echo

read -p "Choice: " CHOICE

case $CHOICE in
1) check_status ;;
2) scan_models ;;
3) disable_ai ;;
4) remove_models ;;
5) generate_recovery_script ;;
6) exit ;;
*) echo "Invalid option" ;;
esac

}

while true
do
menu
done