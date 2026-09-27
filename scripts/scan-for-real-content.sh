#!/usr/bin/env bash
# scan-for-real-content.sh — 掃一個目錄，確認裡面沒有絕對路徑、也沒有出現在
# 「不准出現的名字清單」（denylist）裡的字串。
#
# 用法：
#   ./scan-for-real-content.sh [掃描目錄，預設 repo 根目錄] [denylist 檔，預設同目錄的 denylist.txt]
#
# 命中即失敗（exit 1，並印出命中的檔案與行）；乾淨則 exit 0。
#
# 這支腳本刻意不內建任何真實專案名、網域、人名——denylist.txt 出貨時只放一個
# 自我測試用的假字串，你要用在自己專案上時，把自己不想外流的名字加進 denylist.txt
# （那份檔案本身不會被送出去給別人，是你自己專案裡的私有清單）。
#
# 測試專用旋鈕（不是給正式使用的功能）：
#   SCAN_DISABLE_ABSPATH=1   跳過絕對路徑檢查
#   SCAN_DISABLE_DENYLIST=1  跳過 denylist 檢查
# 這兩個旋鈕只給 test-scan.sh 做「拔除演練」用，正式使用不要設定它們。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN_ROOT="${1:-"$SCRIPT_DIR/.."}"
DENYLIST_FILE="${2:-"$SCRIPT_DIR/denylist.txt"}"

# 掃描時排除的檔案（自己與自己的資料檔，否則規則本身的字串會誤觸發）
EXCLUDE_NAMES=("scan-for-real-content.sh" "test-scan.sh" "denylist.txt")

should_skip() {
  local f="$1"
  local base
  base="$(basename "$f")"
  for ex in "${EXCLUDE_NAMES[@]}"; do
    [ "$base" = "$ex" ] && return 0
  done
  return 1
}

HITS=0

# 1) 絕對路徑檢查：/home/<使用者>/... 或 /Users/<使用者>/...
if [ "${SCAN_DISABLE_ABSPATH:-0}" != "1" ]; then
  while IFS= read -r -d '' f; do
    should_skip "$f" && continue
    if /usr/bin/grep -nE '/home/[A-Za-z0-9_.-]+|/Users/[A-Za-z0-9_.-]+' "$f" >/tmp/.scan-hit.$$ 2>/dev/null; then
      echo "[絕對路徑] $f"
      sed 's/^/    /' /tmp/.scan-hit.$$
      HITS=$((HITS + 1))
    fi
    rm -f /tmp/.scan-hit.$$
  done < <(find "$SCAN_ROOT" -type f -print0)
fi

# 2) denylist 檢查
if [ "${SCAN_DISABLE_DENYLIST:-0}" != "1" ] && [ -f "$DENYLIST_FILE" ]; then
  while IFS= read -r term; do
    # 跳過空行與註解行
    [ -z "$term" ] && continue
    case "$term" in \#*) continue ;; esac
    while IFS= read -r -d '' f; do
      should_skip "$f" && continue
      if /usr/bin/grep -ni -F "$term" "$f" >/tmp/.scan-hit.$$ 2>/dev/null; then
        echo "[denylist: $term] $f"
        sed 's/^/    /' /tmp/.scan-hit.$$
        HITS=$((HITS + 1))
      fi
      rm -f /tmp/.scan-hit.$$
    done < <(find "$SCAN_ROOT" -type f -print0)
  done < "$DENYLIST_FILE"
fi

if [ "$HITS" -gt 0 ]; then
  echo "掃描結果：命中 $HITS 筆，失敗。"
  exit 1
fi

echo "掃描結果：命中 0 筆，乾淨。"
exit 0
