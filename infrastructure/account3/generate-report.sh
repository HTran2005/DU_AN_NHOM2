#!/usr/bin/env bash
# ============================================================
# generate-report.sh — Gộp dữ liệu inventory của TẤT CẢ account
# thành 1 báo cáo Markdown thống nhất (dùng cho báo cáo đồ án).
#
# Yêu cầu: jq (choco install jq / winget install jq / apt install jq)
#
# Cách dùng:
#   bash generate-report.sh -i reports/inventory -o reports/REPORT.md
# ============================================================
set -euo pipefail

IN_DIR="reports/inventory"
OUT_FILE="reports/REPORT.md"

while getopts "i:o:h" opt; do
  case "$opt" in
    i) IN_DIR="$OPTARG" ;;
    o) OUT_FILE="$OPTARG" ;;
    h)
      echo "Dùng: generate-report.sh -i <thư mục inventory> -o <file báo cáo md>"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ Thiếu jq. Cài: choco install jq (Windows) / sudo apt install jq (Linux)" >&2
  exit 1
fi

if [ ! -d "$IN_DIR" ]; then
  echo "❌ Không tìm thấy thư mục inventory: $IN_DIR" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"
REPORT_DATE=$(date "+%Y-%m-%d %H:%M")

# ------------------------------------------------------------
# Gộp tất cả resources-*.json để tính thống kê toàn cục
# ------------------------------------------------------------
ALL_JSON=""
COUNT=0
for f in "$IN_DIR"/resources-*.json; do
  [ -e "$f" ] || continue
  ALL_JSON="${ALL_JSON}${ALL_JSON:+ }${f}"
  COUNT=$((COUNT + 1))
done

if [ -z "$ALL_JSON" ]; then
  echo "❌ Không có file resources-*.json nào trong $IN_DIR" >&2
  exit 1
fi

TOTAL_RESOURCES=$(cat $ALL_JSON | jq -s 'add | length')
TOTAL_TYPES=$(cat $ALL_JSON | jq -s 'add | map(.type) | unique | length')

# ------------------------------------------------------------
# Bắt đầu viết báo cáo
# ------------------------------------------------------------
{
  echo "# 📊 BÁO CÁO TỔNG HỢP TOÀN BỘ DỊCH VỤ AZURE — TRIPTO"
  echo ""
  echo "> Org: **DuAnNhom2** · Project: **BAO_CAO** · Liên kết qua Service Connection Azure Resource Manager"
  echo "> Thời điểm tạo báo cáo: **$REPORT_DATE**"
  echo ""
  echo "---"
  echo ""

  # ===================== PHẦN 1: TỔNG QUAN =====================
  echo "## 1️⃣ Tổng quan"
  echo ""
  echo "| Account | Subscription ID | Số tài nguyên | Loại dịch vụ |"
  echo "|---------|----------------|---------------|--------------|"

  ACCOUNT_TOTAL=0
  for f in "$IN_DIR"/resources-*.json; do
    [ -e "$f" ] || continue
    KEY=$(basename "$f" | sed 's/resources-\(.*\)\.json/\1/')
    RES_COUNT=$(jq 'length' "$f")
    TYPES=$(jq 'map(.type) | unique | length' "$f")
    ACCOUNT_TOTAL=$((ACCOUNT_TOTAL + RES_COUNT))

    SUB_NAME="-"
    [ -f "$IN_DIR/meta-$KEY.json" ] && SUB_NAME=$(jq -r '.name // "-"' "$IN_DIR/meta-$KEY.json")
    SUB_ID="-"
    [ -f "$IN_DIR/meta-$KEY.json" ] && SUB_ID=$(jq -r '.id // "-"' "$IN_DIR/meta-$KEY.json")
    echo "| **$KEY** ($SUB_NAME) | \`$SUB_ID\` | $RES_COUNT | $TYPES |"
  done

  echo ""
  echo "**Tổng cộng: $TOTAL_RESOURCES tài nguyên · $TOTAL_TYPES loại dịch vụ · $COUNT account**"
  echo ""

  # ===================== PHẦN 2: CHI TIẾT TỪNG ACCOUNT =====================
  echo "## 2️⃣ Chi tiết theo account"
  echo ""

  for f in "$IN_DIR"/resources-*.json; do
    [ -e "$f" ] || continue
    KEY=$(basename "$f" | sed 's/resources-\(.*\)\.json/\1/')

    SUB_NAME="-"
    [ -f "$IN_DIR/meta-$KEY.json" ] && SUB_NAME=$(jq -r '.name // "-"' "$IN_DIR/meta-$KEY.json")
    RES_COUNT=$(jq 'length' "$f")

    echo "### $KEY — $SUB_NAME"
    echo ""
    echo "_$RES_COUNT tài nguyên_"
    echo ""
    echo "| # | Tên tài nguyên | Loại dịch vụ | Region | Resource Group | SKU |"
    echo "|---|----------------|--------------|--------|----------------|-----|"

    jq -r '.[] | [.name, .type, (.location // "-"), (.resourceGroup // "-"), (.sku.name // "-")] | @tsv' "$f" \
      | awk -F '\t' '{ printf "| %d | %s | %s | %s | %s | %s |\n", NR, $1, $2, $3, $4, $5 }'

    echo ""
  done

  # ===================== PHẦN 3: TOP LOẠI DỊCH VỤ =====================
  echo "## 3️⃣ Top loại dịch vụ (toàn hệ thống)"
  echo ""
  echo "| # | Loại dịch vụ (resource type) | Số lượng |"
  echo "|---|------------------------------|----------|"

  cat $ALL_JSON | jq -sr 'add | group_by(.type) | map({type: .[0].type, count: (length|tostring)}) | sort_by(-(.count|tonumber)) | .[] | [.type, .count] | @tsv' \
    | awk -F '\t' '{ printf "| %d | `%s` | %s |\n", NR, $1, $2 }'

  echo ""
  echo "---"
  echo ""
  echo "_Báo cáo được tạo tự động bởi pipeline Azure DevOps hoặc script local của Account 3 (DevOps & Security)._"
} > "$OUT_FILE"

echo "✅ Báo cáo đã tạo: $OUT_FILE"
echo "   ($TOTAL_RESOURCES tài nguyên, $TOTAL_TYPES loại dịch vụ, $COUNT account)"
