#!/usr/bin/env bash
# test-scan.sh — 自我測試 scan-for-real-content.sh。
#
# 對三種結構不同的違規各做一次「先紅後綠」＋一次「拔除演練」：
#   樣本 A：絕對路徑違規（靠正規表達式）
#   樣本 B：denylist 詞違規（靠清單逐字比對）
#   樣本 C：機器產生的資料夾要被跳過，但普通檔案裡的同一個字串還是要抓到（靠目錄排除）
# 拔除演練的意思是：把對應的檢查邏輯關掉，同一份原本該被擋的違規檔案
# 必須變成「放行」——藉此證明剛才擋下它的，真的是那條邏輯，不是巧合。
#
# 🔴 樣本 C 刻意同時驗正反兩個方向。改一條「該擋／不該擋」的規則只驗自己在乎的那一邊，
# 換來的是另一邊悄悄壞掉——這個包的踩坑故事裡就有這個形狀。
#
# 最後對整個 repo 跑一次真的掃描，出貨版本應該零命中。

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER="$SCRIPT_DIR/scan-for-real-content.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 註：這支測試腳本裡用普通的 `grep` 只是在數自己剛印出來的行數，不是在搜檔案，
# 所以不受「grep 可能是一層會套用忽略清單的包裝」影響——被測的那支腳本才需要謹慎挑 grep。
PASS=0
FAIL=0

check() {
  local desc="$1" expect="$2" actual="$3"
  if [ "$expect" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc（預期 exit $expect，實際 $actual）"
    FAIL=$((FAIL + 1))
  fi
}

# ---------- 樣本 A：絕對路徑違規 ----------
mkdir -p "$TMP/sampleA"
echo "設定檔路徑寫死在 /home/testuser/config.json 裡" >"$TMP/sampleA/notes.txt"

"$SCANNER" "$TMP/sampleA" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本A（絕對路徑）：正常情況下應被擋（紅）" 1 $?

SCAN_DISABLE_ABSPATH=1 "$SCANNER" "$TMP/sampleA" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本A 拔除演練：關掉絕對路徑檢查後，同一份違規檔案應變成放行（證明剛才是這條邏輯在擋）" 0 $?

# ---------- 樣本 B：denylist 詞違規（結構跟樣本A不同：靠清單比對，不是正規表達式） ----------
mkdir -p "$TMP/sampleB"
echo "EXAMPLE-SELF-TEST-PLACEHOLDER-TERM" >"$TMP/sampleB/notes.txt"

"$SCANNER" "$TMP/sampleB" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本B（denylist詞）：正常情況下應被擋（紅）" 1 $?

SCAN_DISABLE_DENYLIST=1 "$SCANNER" "$TMP/sampleB" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本B 拔除演練：關掉 denylist 檢查後，同一份違規檔案應變成放行" 0 $?

# ---------- 樣本 C：機器產生的資料夾要被跳過，但真正的違規還是要抓到 ----------
# 這一組修的是一個實際踩到的洞：掃描時如果不跳過 .git，那麼你照 denylist.txt 的說明
# 把自己的專案名或帳號加進清單（那是文件教的第一步），掃描器就會命中 .git/config 裡的
# 倉庫網址而永遠失敗——**工具在它自己教的用法上會壞**。
#
# 🔴 這一組刻意同時驗兩個方向，因為「改一條該擋／不該擋的規則」只驗自己在乎的那一邊，
# 換來的是另一邊悄悄壞掉：
#   正向：真正的違規（放在普通檔案裡）還是要被抓到 ⇒ 不是改成什麼都不擋
#   反向：機器產生的資料夾裡的同一個字串不能被算成違規 ⇒ 誤報要消失
mkdir -p "$TMP/sampleC/.git" "$TMP/sampleC/node_modules/pkg" "$TMP/sampleC/src"
echo "url = https://github.com/someone/EXAMPLE-SELF-TEST-PLACEHOLDER-TERM.git" >"$TMP/sampleC/.git/config"
echo "EXAMPLE-SELF-TEST-PLACEHOLDER-TERM" >"$TMP/sampleC/node_modules/pkg/index.js"
echo "EXAMPLE-SELF-TEST-PLACEHOLDER-TERM" >"$TMP/sampleC/src/notes.md"

C_OUT="$("$SCANNER" "$TMP/sampleC" "$SCRIPT_DIR/denylist.txt" 2>&1)"
C_RC=$?
check "樣本C 正向：普通檔案裡的違規仍要被抓到（紅）" 1 $C_RC

C_HITS="$(printf '%s\n' "$C_OUT" | grep -c '^\[denylist' || true)"
check "樣本C 反向：.git 與 node_modules 裡的同一個字串不算違規（只該命中 1 筆，不是 3 筆）" 1 "$C_HITS"

# 拔除演練：關掉「跳過資料夾」這條邏輯，同樣三個檔案應該全部被算進來（1 → 3）
D_OUT="$(SCAN_DISABLE_DIRPRUNE=1 "$SCANNER" "$TMP/sampleC" "$SCRIPT_DIR/denylist.txt" 2>&1)"
D_HITS="$(printf '%s\n' "$D_OUT" | grep -c '^\[denylist' || true)"
check "樣本C 拔除演練：關掉跳過資料夾後，命中數要從 1 變成 3（證明剛才少掉的 2 筆真的是這條邏輯擋掉的）" 3 "$D_HITS"

# ---------- 乾淨樣本：不該被誤擋（陽性對照的另一半：確認工具不是逢檔必擋） ----------
mkdir -p "$TMP/clean"
echo "這是一份完全乾淨、只講待辦清單命令列工具的文字。" >"$TMP/clean/notes.txt"

"$SCANNER" "$TMP/clean" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "乾淨樣本：不應被誤擋（綠）" 0 $?

# ---------- 對整個 repo 做一次真的掃描 ----------
REPO_OUT="$("$SCANNER" "$SCRIPT_DIR/.." "$SCRIPT_DIR/denylist.txt" 2>&1)"
REPO_RC=$?
echo "$REPO_OUT"
check "整個 repo 掃描：出貨版應該零命中" 0 "$REPO_RC"

echo "----"
echo "通過 $PASS / 失敗 $FAIL"
[ "$FAIL" -eq 0 ]
