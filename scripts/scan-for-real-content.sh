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
# 可以調的旋鈕：
#   SCAN_EXCLUDE_DIRS="a b c"  改掉預設跳過的資料夾清單（空白分隔的目錄名，不是路徑）
#
# 測試專用旋鈕（不是給正式使用的功能）：
#   SCAN_DISABLE_ABSPATH=1   跳過絕對路徑檢查
#   SCAN_DISABLE_DENYLIST=1  跳過 denylist 檢查
#   SCAN_DISABLE_DIRPRUNE=1  不跳過任何資料夾（連 .git 也掃）
# 這三個旋鈕只給 test-scan.sh 做「拔除演練」用，正式使用不要設定它們。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN_ROOT="${1:-"$SCRIPT_DIR/.."}"
DENYLIST_FILE="${2:-"$SCRIPT_DIR/denylist.txt"}"

# ---------------------------------------------------------------------------
# grep 的位置不寫死：/usr/bin/grep 在 Linux 與 macOS 都存在，但 Alpine 放在
# /bin/grep、NixOS 根本不在固定路徑。**同時刻意不直接用 `grep`**——有些環境的
# `grep` 是一層包裝（會靜默套用忽略清單），而這支腳本是洩漏檢查，靜默漏掉的代價
# 遠大於誤報。所以：優先用常見的絕對路徑，都沒有才退回 PATH 查詢，一個都找不到
# 就**大聲失敗**（fail-closed），不准回報「乾淨」。
# ---------------------------------------------------------------------------
GREP=""
for candidate in /usr/bin/grep /bin/grep; do
  [ -x "$candidate" ] && { GREP="$candidate"; break; }
done
if [ -z "$GREP" ]; then
  GREP="$(command -v grep || true)"
fi
if [ -z "$GREP" ]; then
  echo "找不到可用的 grep，無法執行洩漏檢查。這支腳本刻意不在這種情況下回報乾淨。" >&2
  exit 2
fi

# 掃描時排除的檔案（自己與自己的資料檔，否則規則本身的字串會誤觸發）
EXCLUDE_NAMES=("scan-for-real-content.sh" "test-scan.sh" "denylist.txt")

# ---------------------------------------------------------------------------
# 跳過「機器自己產生／別人給的」資料夾。理由不是效率，是**正確性**：
# 這些目錄裡的內容不是使用者寫的，卻會讓檢查結果變成假警報。
#   .git         版本控制的中介資料。`.git/config` 裡有你的倉庫網址 ⇒ 你把自己的
#                專案名或帳號加進 denylist（文件教的第一步）就會命中自己，永遠失敗。
#   node_modules 第三方套件，裡面的執行檔外殼與 source map 常帶別人機器的絕對路徑。
#   .venv        同上，Python 虛擬環境。
#   __pycache__  編譯產物。
# 判準：**一個「檢查我有沒有外流」的工具，不該把「你是誰」當成「你洩漏了什麼」。**
# 要自己決定跳過哪些，設 SCAN_EXCLUDE_DIRS（空白分隔的目錄名）。
# ---------------------------------------------------------------------------
read -r -a EXCLUDE_DIRS <<<"${SCAN_EXCLUDE_DIRS:-.git node_modules .venv __pycache__}"

# 組出 find 的排除參數；SCAN_DISABLE_DIRPRUNE=1 時完全不排除（給拔除演練用）
# 🔴 空陣列一律寫成 ${arr[@]+"${arr[@]}"}：macOS 內建的 bash 是 3.2，在 set -u 下
# 直接展開一個空陣列會被當成「未定義變數」而中止。這個寫法在 3.2 與 5.x 都安全。
PRUNE_ARGS=()
if [ "${SCAN_DISABLE_DIRPRUNE:-0}" != "1" ] && [ -n "${EXCLUDE_DIRS[*]+x}" ]; then
  PRUNE_ARGS=(\()
  first=1
  for d in ${EXCLUDE_DIRS[@]+"${EXCLUDE_DIRS[@]}"}; do
    [ -z "$d" ] && continue
    [ "$first" = 1 ] || PRUNE_ARGS+=(-o)
    PRUNE_ARGS+=(-name "$d")
    first=0
  done
  PRUNE_ARGS+=(\) -prune -o)
  [ "$first" = 1 ] && PRUNE_ARGS=()   # 清單其實是空的 ⇒ 不加任何排除
fi

# 列出要掃的檔案（唯一的檔案來源，兩個檢查共用，避免兩邊的範圍走鐘）
list_files() {
  find "$SCAN_ROOT" ${PRUNE_ARGS[@]+"${PRUNE_ARGS[@]}"} -type f -print0
}

should_skip() {
  local f="$1"
  local base
  base="$(basename "$f")"
  for ex in "${EXCLUDE_NAMES[@]}"; do
    [ "$base" = "$ex" ] && return 0
  done
  return 1
}

# 命中暫存檔放在 mktemp 給的安全位置（原本寫死 /tmp/.scan-hit.$$，在唯讀或沒有 /tmp
# 的環境會壞，而且 $$ 可預測）。離場時一定清掉。
HITFILE="$(mktemp)"
trap 'rm -f "$HITFILE"' EXIT

HITS=0

# 1) 絕對路徑檢查：/home/<使用者>/... 或 /Users/<使用者>/...
if [ "${SCAN_DISABLE_ABSPATH:-0}" != "1" ]; then
  while IFS= read -r -d '' f; do
    should_skip "$f" && continue
    if "$GREP" -nE '/home/[A-Za-z0-9_.-]+|/Users/[A-Za-z0-9_.-]+' "$f" >"$HITFILE" 2>/dev/null; then
      echo "[絕對路徑] $f"
      sed 's/^/    /' "$HITFILE"
      HITS=$((HITS + 1))
    fi
    : >"$HITFILE"
  done < <(list_files)
fi

# 2) denylist 檢查
if [ "${SCAN_DISABLE_DENYLIST:-0}" != "1" ] && [ -f "$DENYLIST_FILE" ]; then
  while IFS= read -r term; do
    # 跳過空行與註解行
    [ -z "$term" ] && continue
    case "$term" in \#*) continue ;; esac
    while IFS= read -r -d '' f; do
      should_skip "$f" && continue
      if "$GREP" -ni -F "$term" "$f" >"$HITFILE" 2>/dev/null; then
        echo "[denylist: $term] $f"
        sed 's/^/    /' "$HITFILE"
        HITS=$((HITS + 1))
      fi
      : >"$HITFILE"
    done < <(list_files)
  done < "$DENYLIST_FILE"
fi

if [ "$HITS" -gt 0 ]; then
  echo "掃描結果：命中 $HITS 筆，失敗。"
  exit 1
fi

echo "掃描結果：命中 0 筆，乾淨。"
exit 0
