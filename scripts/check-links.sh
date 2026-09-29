#!/usr/bin/env bash
# check-links.sh — 檢查 markdown 文件之間的相對連結是不是都還指得到東西。
#
# 為什麼需要這支：這個包自己有一節叫「幽靈文件」——一張指向不存在的東西的圖／連結，
# 比沒有那張圖危險，因為它讓人以為那件事有人在管。而在這支腳本存在之前，
# 這個包**自己沒有任何機械在守它自己的連結**（README 曾誠實把這件事列為已知缺口）。
#
# 用法：
#   bash scripts/check-links.sh [要檢查的資料夾，預設是目前資料夾]
# 退出碼：0 全部指得到／1 有連結指不到／2 沒辦法檢查（此時刻意不回報乾淨）
#
# 拔除演練用的開關（只給自我測試用，正常使用不要設）：
#   LINKCHECK_DISABLE_EXISTS=1  關掉「目標存不存在」這條判斷
#
# 刻意不做的事：
#   - 不檢查 http/https 外部連結（要連網、會因為對方暫時掛掉而假紅）
#   - 不檢查 `反引號` 裡的路徑（那是文字不是連結；要被檢查就寫成 markdown 連結）
#   - 不檢查 #錨點 指到的標題存不存在（只比對到檔案層級）

set -u

# 挑一支沒有被包裝過的 grep。某些環境的 grep 是一層會自動套用忽略清單的替身，
# 用它下「沒有找到」的結論會得到假乾淨。
GREP=""
for candidate in /usr/bin/grep /bin/grep; do
  [ -x "$candidate" ] && { GREP="$candidate"; break; }
done
if [ -z "$GREP" ]; then GREP="$(command -v grep || true)"; fi
if [ -z "$GREP" ]; then
  echo "找不到可用的 grep，無法執行連結檢查。這支腳本刻意不在這種情況下回報乾淨。" >&2
  exit 2
fi

ROOT="${1:-.}"
if [ ! -d "$ROOT" ]; then
  echo "找不到要檢查的資料夾：$ROOT" >&2
  exit 2
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

while IFS= read -r -d '' f; do
  dir="$(dirname "$f")"
  while IFS= read -r hit; do
    line="${hit%%:*}"
    target="${hit#*:](}"
    target="${target%)}"
    case "$target" in
      http://*|https://*|mailto:*|tel:*|'#'*|'') continue ;;
    esac
    target="${target%%#*}"
    [ -z "$target" ] && continue
    case "$target" in
      /*) resolved="$target" ;;
       *) resolved="$dir/$target" ;;
    esac
    echo "[ok] $f:$line $target" >>"$LOG"
    if [ "${LINKCHECK_DISABLE_EXISTS:-0}" != "1" ] && [ ! -e "$resolved" ]; then
      echo "[link] $f:$line → $target（指不到東西）" >>"$LOG"
    fi
  done < <("$GREP" -n -o '](\([^)]*\))' "$f")
done < <(find "$ROOT" \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ \) -prune -o -name '*.md' -print0)

FILES="$(find "$ROOT" \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ \) -prune -o -name '*.md' -print | wc -l | tr -d ' ')"
CHECKED="$("$GREP" -c '^\[ok\]' "$LOG" || true)"
MISSING="$("$GREP" -c '^\[link\]' "$LOG" || true)"

if [ "$MISSING" != "0" ]; then
  "$GREP" '^\[link\]' "$LOG"
  echo "----"
  echo "範圍：$ROOT 底下 $FILES 個 markdown 檔、$CHECKED 個相對連結。指不到的：$MISSING 個。"
  exit 1
fi

echo "範圍：$ROOT 底下 $FILES 個 markdown 檔、$CHECKED 個相對連結，全部指得到。"
exit 0
