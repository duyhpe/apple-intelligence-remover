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
echo "Gỡ bỏ Apple Intelligence"
echo "--------------------------------------"
echo

check_status() {
echo "Đang kiểm tra trạng thái Apple Intelligence ..."
STATUS=$(defaults read com.apple.Siri AppleIntelligenceEnabled 2>/dev/null || echo "0")

if [[ "$STATUS" == "1" ]]; then
echo "Apple Intelligence: ENABLED"
else
echo "Apple Intelligence: DISABLED"
fi
echo
}

scan_models() {

echo "Đang quét tệp mô hình AI ..."
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
echo "Không có file tìm thấy."
else
echo "Tổng dung lượng:"
echo $TOTAL_SIZE | awk '{ printf "%.2f GB\n", $1/1024/1024/1024 }'
fi

echo
}

disable_ai() {
echo "Đang hủy kích hoạt Apple Intelligence..."

defaults write com.apple.Siri AppleIntelligenceEnabled -bool false
defaults write com.apple.Siri LLMEnable -bool false

echo "Done."
echo
}

remove_models() {

if [[ ${#FOUND_PATHS[@]} -eq 0 ]]; then
echo "Không có gì xóa bỏ."
return
fi

echo
echo "Danh mục sẽ gỡ bỏ:"
printf '%s\n' "${FOUND_PATHS[@]}"
echo

read -p "Tiếp tục? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
echo "Đã hủy."
return
fi

for path in "${FOUND_PATHS[@]}"
do
echo "Đang xóa $path"

if sudo rm -rf "$path" 2>/dev/null; then
echo "Đã xóa."
else
echo "Không thể xóa (có bảo vệ SIP )."
fi

echo
done
}

generate_recovery_script() {

SCRIPT="$HOME/Desktop/remove_apple_intelligence.sh"

echo "Đang tạọ recovery script..."

cat <<EOF > "$SCRIPT"
#!/bin/bash

echo "Gỡ bỏ Apple Intelligence"

diskutil mount "Macintosh HD - Data" 2>/dev/null || diskutil mount "Data"

rm -rf /Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels
rm -rf /Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual

echo "Hoàn thành."
EOF

chmod +x "$SCRIPT"

echo "Lưu vào:"
echo "$SCRIPT"
echo
}

menu() {

echo "Lựa chọn:"
echo
echo "1) Kiểm tra trạng thái Apple Intelligence 
echo "2) Quét mô hiình AI Scan"
echo "3) Hủy kích hoạt Apple Intelligence"
echo "4) Xóa file mô hình AI"
echo "5) Tạo Recovery script"
echo "6) Thoát"
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
