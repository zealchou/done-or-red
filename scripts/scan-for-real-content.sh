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
#   SCAN_DISABLE_SECRETS=1   跳過密碼／金鑰特徵檢查
#   SCAN_DISABLE_DIRPRUNE=1  不跳過任何資料夾（連 .git 也掃）
# 這四個旋鈕只給 test-scan.sh 做「拔除演練」用，正式使用不要設定它們。
#
# 🔴 它查三種東西，三種的把握程度不一樣，不要混為一談：
#   1. 絕對路徑（你電腦上的使用者名稱）—— 形狀固定，抓得準。
#   2. denylist —— 你自己列的字，列了就抓得到，沒列就抓不到。
#   3. 密碼／金鑰特徵 —— **只抓得到長得像的那幾種**（見下方 SECRET_STRONG／WEAK）。
#      一個你自己發明的格式、或一段被切成兩半拼起來的金鑰，它抓不到。
#      ⇒ 它降低風險，不是保證乾淨。真正該做的是一開始就不要把秘密寫進檔案。

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
# SCAN_GREP 是測試專用旋鈕（讓 test-scan.sh 餵一支「一定會回出錯」的假 grep，
# 證明出錯時真的不會回報乾淨）。正式使用不要設定它。
[ -n "${SCAN_GREP:-}" ] && GREP="$SCAN_GREP"
[ -n "$GREP" ] || for candidate in /usr/bin/grep /bin/grep; do
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
SCAN_ERROR=0

# ---------------------------------------------------------------------------
# 🔴 grep 回 0 是「找到了」、回 1 是「沒找到」、回 2 以上是「出錯了」。
#    把 2 當成 1（沒找到）＝把「檢查壞了」講成「很乾淨」——這支腳本整個存在的理由
#    就是不准那樣。實際踩過：有一條規則的開頭是連字號，grep 把它當成選項而回 2，
#    整支檢查安靜地回報乾淨。所以①一律用 -e 餵規則，②回 2 就記下來，最後大聲失敗。
# ---------------------------------------------------------------------------
scan_one() {                   # scan_one <標籤> <檔案> <grep 額外選項…> -- <規則>
  local label="$1" file="$2"; shift 2
  "$GREP" "$@" "$file" >"$HITFILE" 2>/dev/null
  local rc=$?
  case "$rc" in
    0) echo "[$label] $file"; sed 's/^/    /' "$HITFILE"; HITS=$((HITS + 1)) ;;
    1) : ;;
    *) echo "檢查 $file 時出錯（grep 回 $rc），這一份沒有答案。" >&2; SCAN_ERROR=1 ;;
  esac
  : >"$HITFILE"
}

# 1) 絕對路徑檢查：/home/<使用者>/... 或 /Users/<使用者>/...
if [ "${SCAN_DISABLE_ABSPATH:-0}" != "1" ]; then
  while IFS= read -r -d '' f; do
    should_skip "$f" && continue
    scan_one "絕對路徑" "$f" -nE -e '/home/[A-Za-z0-9_.-]+|/Users/[A-Za-z0-9_.-]+'
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
      scan_one "denylist: $term" "$f" -niF -e "$term"
    done < <(list_files)
  done < "$DENYLIST_FILE"
fi

# ---------------------------------------------------------------------------
# 3) 密碼／金鑰特徵
#
# 分成兩組，理由是**誤報的代價不一樣**：
#   STRONG — 只有真的金鑰才長這樣（私鑰開頭、AWS 的 AKIA、GitHub 的 ghp_…）。
#            這一組不做任何「看起來像範例就放過」的例外，因為一個真金鑰裡剛好
#            出現 example 這個字，不代表它不是真的。
#   WEAK   — `password = 一串東西` 這種形狀。它很容易誤報（教學文件、.env.example、
#            預設值都長這樣），而**一個什麼都擋的閘門會被使用者刪掉**——所以這一組
#            會先把明顯是佔位符的那幾種放過（＿＿＿、xxx、your_、${VAR}、TODO…）。
#
# 🔴 這是刻意做的取捨，不是疏漏：WEAK 這組往「少擋一點」的方向偏。
#    它換來的代價是 `password = hunter2example` 這種真密碼會被放過。
# ---------------------------------------------------------------------------
SECRET_STRONG='-----BEGIN[A-Z ]*PRIVATE KEY-----|(^|[^A-Za-z0-9])AKIA[0-9A-Z]{16}|(^|[^A-Za-z0-9])(sk|rk)-[A-Za-z0-9_-]{20,}|(^|[^A-Za-z0-9])gh[pousr]_[A-Za-z0-9]{20,}|(^|[^A-Za-z0-9])github_pat_[A-Za-z0-9_]{20,}|(^|[^A-Za-z0-9])xox[baprs]-[A-Za-z0-9-]{10,}|(^|[^A-Za-z0-9])AIza[0-9A-Za-z_-]{30,}'
SECRET_WEAK='(password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key)[[:space:]]*[=:][[:space:]]*["'"'"']?[^[:space:]"'"'"']{8,}'
SECRET_PLACEHOLDER='＿|_{3,}|[xX]{3,}|\.\.\.|<|\$\{|\$[A-Za-z_]|[Yy]our[_-]|[Cc]hangeme|CHANGEME|[Ee]xample|EXAMPLE|placeholder|PLACEHOLDER|TODO|FIXME|請填|填入|process\.env|os\.environ|getenv|import\.meta\.env|\{\{'

if [ "${SCAN_DISABLE_SECRETS:-0}" != "1" ]; then
  while IFS= read -r -d '' f; do
    should_skip "$f" && continue
    scan_one "金鑰特徵" "$f" -nE -e "$SECRET_STRONG"
    # WEAK 那組：命中之後再濾掉明顯的佔位符行
    "$GREP" -niE -e "$SECRET_WEAK" "$f" >"$HITFILE" 2>/dev/null
    WEAK_RC=$?
    case "$WEAK_RC" in
      0) if "$GREP" -vE -e "$SECRET_PLACEHOLDER" "$HITFILE" >"$HITFILE.keep" 2>/dev/null \
           && [ -s "$HITFILE.keep" ]; then
           echo "[疑似密碼] $f"
           sed 's/^/    /' "$HITFILE.keep"
           HITS=$((HITS + 1))
         fi
         rm -f "$HITFILE.keep" ;;
      1) : ;;
      *) echo "檢查 $f 的密碼形狀時出錯（grep 回 $WEAK_RC），這一份沒有答案。" >&2
         SCAN_ERROR=1 ;;
    esac
    : >"$HITFILE"
  done < <(list_files)
fi

# 🔴 出錯優先於「乾淨」報告：有任何一份檔案沒檢查完，就不准說乾淨。
if [ "$SCAN_ERROR" != 0 ]; then
  echo "有檔案沒有檢查完（上面有出錯訊息），刻意不回報乾淨。" >&2
  exit 2
fi

if [ "$HITS" -gt 0 ]; then
  echo "掃描結果：命中 $HITS 筆，失敗。"
  exit 1
fi

echo "掃描結果：命中 0 筆，乾淨。"
exit 0
