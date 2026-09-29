#!/usr/bin/env bash
# check-links.sh — 檢查 markdown 文件之間的相對連結是不是都還指得到東西。
#
# 為什麼需要這支：這個包自己有一節叫「幽靈文件」——一張指向不存在的東西的圖／連結，
# 比沒有那張圖危險，因為它讓人以為那件事有人在管。而在這支腳本存在之前，
# 這個包**自己沒有任何機械在守它自己的連結**（README 曾誠實把這件事列為已知缺口）。
#
# 用法：
#   bash scripts/check-links.sh [要檢查的資料夾，預設是目前資料夾]
# 退出碼：0 全部指得到／1 有連結指不到／2 沒辦法完整檢查（此時刻意不回報乾淨）
#
# 拔除演練用的開關（只給自我測試用，正常使用不要設）：
#   LINKCHECK_DISABLE_EXISTS=1  關掉「目標存不存在」這條判斷
#
# ── 它看得懂哪些寫法（這一段就是它的契約，不要只寫「支援 markdown 連結」）──
#   [文字](./x.md)                 ✅
#   [文字](./x.md "標題")          ✅（會把 title 拿掉）
#   [文字](<./有 空白.md>)         ✅（會把角括號拿掉）
#   [文字](./有%20空白.md)         ✅（會把 %20 還原成空白）
#   ![圖](./x.png)                 ✅（圖片跟連結同一個形狀）
#   [文字][代號] ＋ [代號]: ./x.md ✅（檢查的是下面那行定義指到哪）
#
# ── 🔴 它看不懂、會判錯的寫法（老實列出來）──
#   [文字](./目標裡有(括號).md)
#       ⇒ **會誤報**。它只認到第一個 `)`。目前這個包裡沒有這種連結；
#         真的需要用的時候，把檔名改掉比改這支腳本便宜。
#   `[文字](./x.md)` 寫在反引號裡
#       ⇒ **一樣會被檢查**（它不是 markdown 解析器，分不出程式碼區段）。
#         所以文件裡舉例用的連結，要指向真的存在的檔案，或者寫成不含 `](` 的形狀。
#   #錨點
#       ⇒ 只比對到檔案層級，指向一個已經改名的標題不會紅。
#   http／https 外部連結
#       ⇒ 刻意不檢查：要連網，而且對方暫時掛掉會變成假紅。

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

LIST="$(mktemp)"
LOG="$(mktemp)"
trap 'rm -f "$LIST" "$LOG"' EXIT

# 🔴 檔案列舉要先落地再檢查它成不成功。
# 放在 process substitution 裡的話，它失敗了主程序收不到——那會讓「掃不到」
# 長得跟「掃過了，很乾淨」一模一樣，而這支腳本的整個立場就是不准這樣。
find "$ROOT" \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ \) \
     -prune -o -name '*.md' -print0 >"$LIST"
FIND_RC=$?
if [ "$FIND_RC" != 0 ]; then
  echo "列舉檔案失敗（find 回 $FIND_RC），無法完整檢查。刻意不回報乾淨。" >&2
  exit 2
fi

SCAN_ERROR=0
FILES=0

# 把抽出來的目標正規化成一個真的可以拿去對檔案的路徑
normalize_target() {
  local t="$1"
  t="${t%%\"*}"                       # 砍掉 "標題"
  t="${t%%\'*}"                       # 砍掉 '標題'
  while [ "${t# }" != "$t" ]; do t="${t# }"; done
  while [ "${t#	}" != "$t" ]; do t="${t#	}"; done
  while [ "${t% }" != "$t" ]; do t="${t% }"; done
  while [ "${t%	}" != "$t" ]; do t="${t%	}"; done
  case "$t" in '<'*'>') t="${t#<}"; t="${t%>}" ;; esac
  t="${t//%20/ }"                     # 還原被編碼的空白
  t="${t%%#*}"                        # 去掉 #錨點
  printf '%s' "$t"
}

record() {
  local f="$1" line="$2" target="$3" dir="$4" resolved
  [ -z "$target" ] && return 0
  case "$target" in
    http://*|https://*|mailto:*|tel:*|'#'*) return 0 ;;
  esac
  case "$target" in
    /*) resolved="$target" ;;
     *) resolved="$dir/$target" ;;
  esac
  echo "[ok] $f:$line $target" >>"$LOG"
  if [ "${LINKCHECK_DISABLE_EXISTS:-0}" != "1" ] && [ ! -e "$resolved" ]; then
    echo "[link] $f:$line → $target（指不到東西）" >>"$LOG"
  fi
}

# 從一支 grep 的輸出（每行 `行號:片段`）取出目標並登記
harvest() {
  local f="$1" dir="$2" mode="$3" out="$4" hit line target
  [ -z "$out" ] && return 0
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    line="${hit%%:*}"
    if [ "$mode" = inline ]; then
      target="${hit#*:](}"
      target="${target%)}"
    else
      target="${hit#*]:}"
    fi
    target="$(normalize_target "$target")"
    record "$f" "$line" "$target" "$dir"
  done <<EOF
$out
EOF
}

while IFS= read -r -d '' f; do
  FILES=$((FILES + 1))
  dir="$(dirname "$f")"

  # ① 一般連結與圖片：[文字](目標) / ![文字](目標)
  out="$("$GREP" -n -o '](\([^)]*\))' "$f")"; rc=$?
  if [ "$rc" -ge 2 ]; then
    echo "讀不到 $f（grep 回 $rc）" >&2
    SCAN_ERROR=1
  else
    harvest "$f" "$dir" inline "$out"
  fi

  # ② 參考式連結的定義行：[代號]: 目標
  #    漏抓這一種比誤報危險——它的失效方向是假綠。
  out="$("$GREP" -n -o '^[ ]*\[[^]]*\]:[ ]*[^ ]*' "$f")"; rc=$?
  if [ "$rc" -ge 2 ]; then
    echo "讀不到 $f（grep 回 $rc）" >&2
    SCAN_ERROR=1
  else
    harvest "$f" "$dir" refdef "$out"
  fi
done <"$LIST"

CHECKED="$("$GREP" -c '^\[ok\]' "$LOG" || true)"
MISSING="$("$GREP" -c '^\[link\]' "$LOG" || true)"

if [ "$SCAN_ERROR" != 0 ]; then
  [ "$MISSING" != "0" ] && "$GREP" '^\[link\]' "$LOG"
  echo "----"
  echo "有檔案讀不到，這一次的檢查不完整（已檢查 $CHECKED 個連結、指不到 $MISSING 個）。"
  echo "刻意不回報乾淨——讀不到的那些檔案裡有沒有壞連結，這次沒有答案。"
  exit 2
fi

if [ "$MISSING" != "0" ]; then
  "$GREP" '^\[link\]' "$LOG"
  echo "----"
  echo "範圍：$ROOT 底下 $FILES 個 markdown 檔、$CHECKED 個相對連結。指不到的：$MISSING 個。"
  exit 1
fi

echo "範圍：$ROOT 底下 $FILES 個 markdown 檔、$CHECKED 個相對連結，全部指得到。"
exit 0
