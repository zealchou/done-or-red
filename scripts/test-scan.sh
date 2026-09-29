#!/usr/bin/env bash
# test-scan.sh — 自我測試 scan-for-real-content.sh。
#
# 對四種結構不同的違規各做一次「先紅後綠」＋一次「拔除演練」：
#   樣本 A：絕對路徑違規（靠正規表達式）
#   樣本 B：denylist 詞違規（靠清單逐字比對）
#   樣本 C：機器產生的資料夾要被跳過，但普通檔案裡的同一個字串還是要抓到（靠目錄排除）
#   樣本 D：文件之間的指路還在不在（靠 check-links.sh；分 D1 正向／D2 反向／D3 失效方向三份）
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

# ---------- 樣本 D：文件之間的指路還在不在（check-links.sh） ----------
# 這一組補的是這個包自己欠的一條：在這之前，把任何一份文件的連結刪掉或改錯，
# 這支自我測試都不會變紅——而那正是本包 GDD 那一節在講的「幽靈文件」。
#
# 🔴 這一組刻意分成三份互不混用的樣本，因為**只驗「有沒有抓到」驗不到誤報**：
#   D1 只有壞連結  ⇒ 驗正向：抓到，而且筆數剛好對
#   D2 全部是好連結（含 title／角括號／%20／參考式／圖片五種寫法）⇒ 驗反向：一筆都不准報
#   D3 有一個讀不到的檔案 ⇒ 驗失效方向：不准回報乾淨，要回 2
# 只做 D1 的話，「把每一條連結都當成壞的」也會通過。
LINKER="$SCRIPT_DIR/check-links.sh"

# --- D1：只有壞連結 ---
mkdir -p "$TMP/sampleD1/docs"
printf '看 [這一份](./docs/does-not-exist.md) 還有 [那一份](./docs/also-missing.md)\n' >"$TMP/sampleD1/a.md"

D1_OUT="$(bash "$LINKER" "$TMP/sampleD1" 2>&1)"
check "樣本D1 正向：指不到東西的連結要被抓到（紅）" 1 $?
D1_HITS="$(printf '%s\n' "$D1_OUT" | grep -c '^\[link\]' || true)"
check "樣本D1 筆數：兩條壞連結要報 2 筆，不是只報 1 筆（少報就是斷言太鬆）" 2 "$D1_HITS"

D2_DRILL="$(LINKCHECK_DISABLE_EXISTS=1 bash "$LINKER" "$TMP/sampleD1" 2>&1)"
D2_DRILL_RC=$?
check "樣本D1 拔除演練：關掉「目標存不存在」這條判斷後，同一份壞連結應變成放行" 0 "$D2_DRILL_RC"

# --- D2：全部是好連結，五種寫法都不准被誤報 ---
mkdir -p "$TMP/sampleD2/d"
echo ok >"$TMP/sampleD2/d/x.md"
echo ok >"$TMP/sampleD2/d/x y.md"
printf 'x' >"$TMP/sampleD2/d/pic.png"
cat >"$TMP/sampleD2/a.md" <<'EOF'
[帶標題](./d/x.md "標題")
[角括號](<./d/x y.md>)
[編碼空白](./d/x%20y.md)
[參考式][id]
[id]: ./d/x.md
![圖片](./d/pic.png)
EOF
D2_OUT="$(bash "$LINKER" "$TMP/sampleD2" 2>&1)"
D2_RC=$?
check "樣本D2 反向：五種合法寫法且目標都存在，一筆都不准報（綠）" 0 "$D2_RC"
D2_HITS="$(printf '%s\n' "$D2_OUT" | grep -c '^\[link\]' || true)"
check "樣本D2 筆數：誤報數必須是 0" 0 "$D2_HITS"
D2_CHECKED="$(printf '%s\n' "$D2_OUT" | grep -c '個相對連結，全部指得到' || true)"
check "樣本D2 覆蓋：它真的走完了（不是因為一條都沒抽到才全綠）" 1 "$D2_CHECKED"

# --- D3：讀不到檔案時不准回報乾淨（失效方向） ---
mkdir -p "$TMP/sampleD3"
printf '[x](./missing.md)\n' >"$TMP/sampleD3/locked.md"
chmod 000 "$TMP/sampleD3/locked.md"
bash "$LINKER" "$TMP/sampleD3" >/dev/null 2>&1
check "樣本D3 失效方向：有檔案讀不到時要回 2（不是 0 也不是 1）" 2 $?
chmod 644 "$TMP/sampleD3/locked.md"

# --- 對整個 repo 實跑 ---
LINK_OUT="$(bash "$LINKER" "$SCRIPT_DIR/.." 2>&1)"
LINK_RC=$?
echo "$LINK_OUT"
check "整個 repo 連結檢查：每一份文件的指路都還指得到（綠）" 0 "$LINK_RC"

# ---------- 樣本 E：安裝動作與閘門（這個包的第三條腿） ----------
# 前兩條腿（規則檔、記錄檔）都是文字，靠人記得去看。這一組驗的是**會真的擋人**的那條腿。
#
# 🔴 四條刻意配成兩組對照，只做 E2 的話「把每一個提交都擋下來」也會過關——
# 而那種閘門的真實結局是使用者把它整個刪掉。
#   E1 裝得起來      E2 髒的要被擋      E3 乾淨的不准被擋      E4 自己壞掉時不准放行
INSTALLER="$SCRIPT_DIR/install.sh"

E_HOME="$TMP/sampleE"
mkdir -p "$E_HOME"
bash "$INSTALLER" "$E_HOME" >"$TMP/install.log" 2>&1
E_RC=$?

# E1：裝得起來，而且四家的規則檔、模板、閘門都到位
E1_OK=0
if [ "$E_RC" = 0 ]; then
  E1_OK=1
  for f in CLAUDE.md AGENTS.md .github/copilot-instructions.md .cursor/rules/done-or-red.mdc \
           docs/ACCEPTANCE_FIRST.md docs/PROJECT_NOTEBOOK.md docs/RULINGS.md \
           docs/DEFERRED_DEFECTS.md docs/SKILL_CARD.md .git/hooks/pre-commit; do
    [ -e "$E_HOME/$f" ] || { E1_OK=0; echo "  （E1 缺：$f）"; }
  done
fi
check "樣本E1 安裝：四家規則檔＋模板＋閘門都到位" 1 "$E1_OK"

# 準備一個能提交的環境
git -C "$E_HOME" config user.email "test@example.invalid" >/dev/null 2>&1
git -C "$E_HOME" config user.name "test" >/dev/null 2>&1

# E2：含違規內容的提交要被擋（正向）
# 🔴 這一條刻意**不只看退出碼**。第一版只看退出碼時它是綠的，
# 但綠的原因是那個資料夾當時根本還不是版本控制倉庫、提交本來就會失敗——
# 也就是說閘門不存在它也會綠，零證明力。所以改成必須同時看到閘門自己印的記號。
echo "設定檔路徑寫死在 /home/testuser/secret.json 裡" >"$E_HOME/dirty.txt"
git -C "$E_HOME" add dirty.txt >/dev/null 2>&1
git -C "$E_HOME" commit -m "髒的" >"$TMP/e2.log" 2>&1
E2_RC=$?
E2_OK=0
if [ "$E2_RC" -ne 0 ] && grep -q '\[done-or-red\]' "$TMP/e2.log"; then E2_OK=1; fi
check "樣本E2 正向：含違規內容的提交要被閘門擋下（且訊息出自閘門本身）" 1 "$E2_OK"

# E3：乾淨的提交不准被誤擋（反向，跟 E2 同一批存在）
rm -f "$E_HOME/dirty.txt"
git -C "$E_HOME" rm --cached dirty.txt >/dev/null 2>&1
echo "這是一份完全乾淨的說明文字。" >"$E_HOME/clean.txt"
git -C "$E_HOME" add -A >/dev/null 2>&1
git -C "$E_HOME" commit -m "乾淨的" >"$TMP/e3.log" 2>&1
check "樣本E3 反向：乾淨的提交不准被誤擋（0）" 0 $?

# E4：閘門自己壞掉的時候不准放行（失效方向）
# 🔴 這一條的第一版也是空綠，而且比 E2 那次更隱蔽：
#   提交確實失敗了、輸出裡確實有閘門的記號，但**失敗原因不是閘門擋住**——
#   把檢查工具鎖成不可讀之後，版本控制自己就無法把檔案排進暫存區，
#   於是變成「沒有東西要提交」而失敗，而閘門那一輪其實是印「✓ 檢查通過」的。
#   ⇒ 兩個修法都必要：①先排好暫存再鎖檔，別讓鎖檔影響排檔
#                    ②斷言改成認閘門**拒絕時才會講的那句話**，不是任何一個記號
E4_OK=0
if [ -f "$E_HOME/.done-or-red/scan-for-real-content.sh" ]; then
  echo "再一筆乾淨的文字。" >"$E_HOME/clean2.txt"
  git -C "$E_HOME" add -A >/dev/null 2>&1          # 先排好，再鎖
  chmod 000 "$E_HOME/.done-or-red/scan-for-real-content.sh"
  git -C "$E_HOME" commit -m "檢查壞掉時" >"$TMP/e4.log" 2>&1
  E4_RC=$?
  chmod 644 "$E_HOME/.done-or-red/scan-for-real-content.sh"
  if [ "$E4_RC" -ne 0 ] && grep -q '刻意不放行' "$TMP/e4.log"; then E4_OK=1; fi
fi
check "樣本E4 失效方向：檢查工具讀不到時要由閘門擋下提交，不准放行" 1 "$E4_OK"

# E5：裝出來的東西自己不准有斷連結
# 🔴 這一條是**補一個真的發生過的缺陷**，不是想像出來的：
#    第一版安裝腳本直接複製檔案，於是規則檔裡指向這個包其他文件的連結全部斷掉，
#    一裝完就有 6 條幽靈連結——而且是被這個包自己的閘門在提交時抓到的。
bash "$LINKER" "$E_HOME" >/dev/null 2>&1
check "樣本E5 裝出來的成品：不准有指不到東西的連結" 0 $?

# 🔴 E5 光看退出碼是**空綠**：安裝腳本把連結全部改成公開網址之後，裝出來的成品
#    相對連結是 0 條，而「0 條相對連結，全部指得到」也是綠的——把六個來源檔清空
#    一樣會綠，零證明力。所以要另外斷言「改寫真的發生過」。
E5_REWRITTEN=$(grep -rl 'github.com/zealchou/done-or-red/blob/main' "$E_HOME" 2>/dev/null | wc -l | tr -d ' ')
[ "${E5_REWRITTEN:-0}" -ge 3 ] && E5_COV=1 || E5_COV=0
check "樣本E5 覆蓋：裝出來的檔案裡真的有被改寫過的連結（不是因為一條都沒有才全綠）" 1 "$E5_COV"

# E6：先把髒的排進暫存、再把手上的檔案改乾淨 —— 不准放行（實測繞得過，已修）
# 🔴 這是本批最嚴重的那個洞：閘門檢查「資料夾現在的樣子」而不是「要存進去的那一份」，
#    所以資料夾看起來乾淨就放行，而版本紀錄裡存的是有密碼那一份。
E6_OK=0
if [ -d "$E_HOME/.git" ]; then
  echo "設定檔在 /home/testuser/sneaky.json" >"$E_HOME/sneak.txt"
  git -C "$E_HOME" add sneak.txt >/dev/null 2>&1
  echo "已經改乾淨了。" >"$E_HOME/sneak.txt"      # 手上的檔案乾淨，暫存區是髒的
  git -C "$E_HOME" commit -m "偷渡" >"$TMP/e6.log" 2>&1
  E6_RC=$?
  [ "$E6_RC" -ne 0 ] && grep -q '不該被存進版本紀錄' "$TMP/e6.log" && E6_OK=1
  git -C "$E_HOME" rm -q -f --cached sneak.txt >/dev/null 2>&1
  rm -f "$E_HOME/sneak.txt"
fi
check "樣本E6 偷渡：暫存的是髒的、手上的是乾淨的，仍然要被擋下" 1 "$E6_OK"

# E7：檢查工具被清空（檔案還在、還跑得動、還回 0）—— 不准當成乾淨
# 🔴 E4 管的是「讀不到」，這一條管的是「讀得到但被掏空」。兩者長得完全不一樣：
#    一個空檔案被 bash 執行會安安靜靜回 0，於是閘門把它當成「檢查過很乾淨」。
E7_OK=0
if [ -f "$E_HOME/.done-or-red/scan-for-real-content.sh" ]; then
  cp "$E_HOME/.done-or-red/scan-for-real-content.sh" "$TMP/scanner.bak"
  echo "又一筆乾淨的文字。" >"$E_HOME/clean3.txt"
  git -C "$E_HOME" add -A >/dev/null 2>&1
  : >"$E_HOME/.done-or-red/scan-for-real-content.sh"      # 掏空，不是刪掉
  git -C "$E_HOME" commit -m "掏空檢查工具" >"$TMP/e7.log" 2>&1
  E7_RC=$?
  cp "$TMP/scanner.bak" "$E_HOME/.done-or-red/scan-for-real-content.sh"
  [ "$E7_RC" -ne 0 ] && grep -q '刻意不放行' "$TMP/e7.log" && E7_OK=1
fi
check "樣本E7 失效方向：檢查工具被掏空（回 0 但沒做事）時不准放行" 1 "$E7_OK"

# E8：安裝腳本不准需要 python3
# 🔴 這個包自己的驗收條件寫著「不准新增任何外部依賴」，而第一版用了 python3：
#    在沒有 python3 的電腦上九個步驟失敗，它照樣印「✓ 裝好了」並回 0。
#    做法是餵一個「一定會失敗的 python3」——還會用到它的話，安裝就會失敗。
E8_HOME="$TMP/e8"; mkdir -p "$E8_HOME" "$TMP/nopy"
printf '#!/bin/sh\nexit 127\n' >"$TMP/nopy/python3"
printf '#!/bin/sh\nexit 127\n' >"$TMP/nopy/python"
chmod +x "$TMP/nopy/python3" "$TMP/nopy/python"
PATH="$TMP/nopy:$PATH" bash "$SCRIPT_DIR/install.sh" "$E8_HOME" >"$TMP/e8.log" 2>&1
E8_RC=$?
E8_FAILS="$(grep -c '✗' "$TMP/e8.log" 2>/dev/null || true)"
if [ "$E8_RC" = 0 ] && [ "${E8_FAILS:-99}" = 0 ]; then E8_OK=1; else E8_OK=0; cat "$TMP/e8.log"; fi
check "樣本E8 零依賴：python3 壞掉時安裝仍要整套成功（一個 ✗ 都不准有）" 1 "$E8_OK"

# E9：再裝一次，不准把使用者自己的名單蓋掉
# 🔴 文件教使用者「把自己不想外流的名字加進 denylist」，所以那是他的內容。
#    第一版再裝一次就把它蓋回出貨版，畫面上一切正常，而他的保護清單被清空了。
echo "MY-OWN-SECRET-WORD-FOR-TEST" >>"$E_HOME/.done-or-red/denylist.txt"
bash "$INSTALLER" "$E_HOME" >"$TMP/e9.log" 2>&1
grep -q 'MY-OWN-SECRET-WORD-FOR-TEST' "$E_HOME/.done-or-red/denylist.txt" && E9_OK=1 || E9_OK=0
check "樣本E9 重裝：使用者自己加進名單的字不准被蓋掉" 1 "$E9_OK"

# E10：有步驟失敗時，不准印「裝好了」也不准回 0
# 🔴 第一版真的這樣：九個步驟失敗、訊息說「✓ 裝好了」、退出碼 0。
#    做法是把工具資料夾改成寫不進去，逼一個步驟失敗。
E10_HOME="$TMP/e10"; mkdir -p "$E10_HOME/.done-or-red"
: >"$E10_HOME/.done-or-red/scan-for-real-content.sh"
chmod 500 "$E10_HOME/.done-or-red"
bash "$INSTALLER" "$E10_HOME" >"$TMP/e10.log" 2>&1
E10_RC=$?
chmod 755 "$E10_HOME/.done-or-red"
if [ "$E10_RC" -ne 0 ] && ! grep -q '✓ 裝好了' "$TMP/e10.log"; then E10_OK=1; else E10_OK=0; fi
check "樣本E10 誠實回報：有步驟失敗時要回非 0，而且不准說「裝好了」" 1 "$E10_OK"

# ---------- 樣本 F：密碼／金鑰特徵，兩個方向都要量 ----------
# 🔴 只測 F1 的話，「把每個檔案都當成有金鑰」也會滿分——而那種閘門會被使用者刪掉。
F_DIR="$TMP/secret"; mkdir -p "$F_DIR"
printf 'AKIAIOSFODNN7EXAMPLE1\n'                 >"$F_DIR/a.txt"
printf -- '-----BEGIN RSA PRIVATE KEY-----\n'    >"$F_DIR/b.txt"
printf 'k = ghp_abcdefghijklmnopqrstuvwxyz12\n'  >"$F_DIR/c.txt"
printf 'x = xoxb-1234567890-abcdefgh\n'          >"$F_DIR/d.txt"
printf 'password = hunter2supersecret\n'         >"$F_DIR/e.txt"
F1_OUT="$(bash "$SCANNER" "$F_DIR" "$SCRIPT_DIR/denylist.txt" 2>&1)"
check "樣本F1 正向：五種金鑰／密碼形狀要被抓到（紅）" 1 $?
F1_HITS="$(printf '%s' "$F1_OUT" | sed -n 's/^掃描結果：命中 \([0-9]*\) 筆.*/\1/p')"
check "樣本F1 筆數：五個檔案要報 5 筆，少報就是斷言太鬆" 5 "${F1_HITS:-0}"

rm -f "$F_DIR"/*.txt
printf 'API_KEY=\nDB_PASSWORD=${DB_PASSWORD}\n'  >"$F_DIR/f.txt"
printf 'password = your_password_here\n'         >"$F_DIR/g.txt"
printf 'token: ＿＿＿＿＿＿＿＿\n'                >"$F_DIR/h.txt"
printf 'const key = process.env.API_KEY\n'       >"$F_DIR/i.txt"
printf '不要把密碼、金鑰寫進檔案裡。\n'           >"$F_DIR/j.txt"
bash "$SCANNER" "$F_DIR" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本F2 反向：空值、佔位符、環境變數、教學句子，一筆都不准報（綠）" 0 $?

# F3：搜尋工具本身出錯時不准回報乾淨（失效方向）
# 🔴 這一條補的是一個真的犯過的錯：金鑰規則開頭是連字號，搜尋工具把它當成選項而
#    回「出錯」，而程式把「出錯」當成「沒找到」——整支檢查安靜地回報乾淨。
F3_DIR="$TMP/greperr"; mkdir -p "$F3_DIR"
echo "一行普通文字" >"$F3_DIR/x.txt"
# 🔴 實測記錄：這一條被**兩處**程式碼守著（scan_one 裡一處、密碼那組裡一處），
#    所以只砍一處的拔除演練會得到 0 紅——那不代表這條測試是裝飾品，代表刀不夠。
#    兩處一起砍才恰好紅 1 條。數紅的時候要知道這件事，不要急著改預期數字去對答案。
printf '#!/bin/sh\nexit 2\n' >"$TMP/fakegrep"; chmod +x "$TMP/fakegrep"
SCAN_GREP="$TMP/fakegrep" bash "$SCANNER" "$F3_DIR" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本F3 失效方向：搜尋工具回「出錯」時要回 2，不准回 0 說乾淨" 2 $?

# F3b 反向：同一支假 grep 改成「乾淨地回沒找到」時，就該正常放行——
# 證明 F3 紅的原因是「出錯」，不是「換了一支 grep」。
printf '#!/bin/sh\nexit 1\n' >"$TMP/fakegrep_clean"; chmod +x "$TMP/fakegrep_clean"
SCAN_GREP="$TMP/fakegrep_clean" bash "$SCANNER" "$F3_DIR" "$SCRIPT_DIR/denylist.txt" >/dev/null 2>&1
check "樣本F3b 對照：同一支假工具回「沒找到」時要正常放行（證明剛才紅的是出錯，不是換工具）" 0 $?

echo "----"
echo "通過 $PASS / 失敗 $FAIL"
[ "$FAIL" -eq 0 ]
