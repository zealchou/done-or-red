#!/usr/bin/env bash
# install.sh — 把這一套裝進你的專案。
#
# 用法（叫你的 AI 助手替你跑就好，你不必自己打）：
#   bash scripts/install.sh /你的專案資料夾
#
# 它會做四件事，每一件都會印出來：
#   1. 把規則檔放好——**四家 AI 助手的檔名一次全放**，所以你用哪一個都通
#   2. 把模板複製到你的 docs/
#   3. 把兩支自查工具放到 .done-or-red/
#   4. 把閘門掛在「存版本」那一步（存版本＝把這批改動正式記錄下來）
#
# 🔴 它刻意不會覆蓋你已經有的檔案。撞名的時候它會另存一份並告訴你，
#    因為那些檔案裡可能有你自己寫的規矩，覆蓋掉是不可逆的。
#
# 退出碼：0 裝好了／1 沒裝成（訊息會說是哪一步）

set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET="${1:-}"

say() { echo "[done-or-red] $*"; }
die() { echo "[done-or-red] ✗ $*" >&2; exit 1; }

# 🔴 有步驟失敗卻照樣印「✓ 裝好了」＋回 0，是這支腳本第一版真的犯過的錯
#    （在沒有 python3 的電腦上實測：九個步驟失敗、退出碼 0、訊息說裝好了）。
#    所以現在每一個會失敗的動作都要走 fail()，收尾按這個數字決定退出碼。
FAILED=0
fail() { echo "[done-or-red] ✗ $*" >&2; FAILED=$((FAILED + 1)); }

[ -n "$TARGET" ] || die "請告訴我要裝到哪個資料夾：bash scripts/install.sh /你的專案資料夾"
[ -d "$TARGET" ] || die "找不到這個資料夾：$TARGET"
TARGET="$(cd "$TARGET" && pwd -P)"
[ "$TARGET" != "$SRC" ] || die "不要裝到這個包自己身上。請指定你自己的專案資料夾。"

say "要裝到：$TARGET"

# ---------- 1. 確認有版本控制（閘門要掛在那上面） ----------
if [ ! -d "$TARGET/.git" ]; then
  say "這個資料夾還沒有版本控制，先幫你開一個（這樣才有地方掛閘門，而且你之後改壞了可以回頭）"
  git -C "$TARGET" init -q || die "開版本控制失敗。你的電腦上可能還沒有 git。"
fi

# ---------- 2. 規則檔：四家檔名一次放好 ----------
RULES_SRC="$SRC/AI_RULES.md"
[ -f "$RULES_SRC" ] || die "找不到規則檔正本：$RULES_SRC"

REPO_URL="https://github.com/zealchou/done-or-red/blob/main"

# 🔴 複製進使用者專案的檔案，裡面指向「這個包其他文件」的相對連結會全部斷掉
#    ——因為那些文件不在他的專案裡。裝出一堆斷連結，正是這個包自己在罵的「幽靈」。
#    修法：那些連結改成公開網址（不會斷，而且永遠是最新版）；
#    指向「他自己專案裡會有的那幾份」的連結改成同一層的相對路徑。
#    這個缺陷是被這個包自己的閘門抓到的，不是想出來的。
OWN_FILES="ACCEPTANCE_FIRST.md PROJECT_NOTEBOOK.md RULINGS.md DEFERRED_DEFECTS.md SKILL_CARD.md"

# 🔴 這一段刻意只用 sed，不用 python3。理由不是潔癖：這個包自己的驗收條件寫著
#    「不准新增任何外部依賴」，而第一版用了 python3——在沒有 python3 的電腦上，
#    九個步驟會安靜地失敗，而它照樣印「裝好了」。要求使用者先裝 python3，
#    對「完全沒有程式基礎」的人等於這個包不能用。
# 🔴 它只改開頭是 ./ 或 ../ 的連結。開頭沒有點的相對連結（例：`](docs/x.md)`）
#    它不動——那一種會被連結檢查抓到並要求你修，不會安靜壞掉。
fix_links() {                  # fix_links <檔案>
  local f="$1"
  local t="$f.dor-tmp"
  sed -e "s|](\.\./\.\./|]($REPO_URL/|g" \
      -e "s|](\.\./|]($REPO_URL/|g" \
      -e "s|](\./|]($REPO_URL/|g" "$f" >"$t" && mv "$t" "$f" || {
    rm -f "$t"; return 1
  }
  local n
  for n in $OWN_FILES; do      # 這幾份他自己專案裡也會有 ⇒ 指回同一層
    sed "s|](\([^)]*/\)*$n|](./$n|g" "$f" >"$t" && mv "$t" "$f" || {
      rm -f "$t"; return 1
    }
  done
}

place() {                      # place <目標相對路徑>
  local rel="$1"
  local dst="$TARGET/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then
    if grep -q 'done-or-red' "$dst" 2>/dev/null; then
      say "· $rel 已經裝過了，跳過"
    else
      cp "$RULES_SRC" "$dst.done-or-red.md" && fix_links "$dst.done-or-red.md" \
        || { fail "$rel.done-or-red.md 沒放成功"; return; }
      say "⚠ $rel 你已經有了，**沒有覆蓋**。新的放在 $rel.done-or-red.md，請把它的內容併進去"
    fi
  else
    cp "$RULES_SRC" "$dst" && fix_links "$dst" || { fail "$rel 沒放成功"; return; }
    say "· 放好 $rel"
  fi
}

place "CLAUDE.md"                              # Claude Code
place "AGENTS.md"                              # 多數工具認這個
place ".github/copilot-instructions.md"        # GitHub Copilot
place ".cursor/rules/done-or-red.mdc"          # Cursor

# ---------- 3. 模板複製到 docs/ ----------
mkdir -p "$TARGET/docs"
for t in "$SRC"/templates/*.md; do
  b="$(basename "$t")"
  if [ -e "$TARGET/docs/$b" ]; then
    say "· docs/$b 已存在，跳過（不覆蓋你寫過的內容）"
  else
    cp "$t" "$TARGET/docs/$b" && fix_links "$TARGET/docs/$b" \
      || { fail "docs/$b 沒放成功"; continue; }
    say "· 放好 docs/$b"
  fi
done

# ---------- 4. 自查工具與你的私密名單 ----------
# 🔴 這些東西**刻意不放在你的專案資料夾裡**，而是放進版本控制自己的內部資料夾。
#    理由是實測出來的，不是設計潔癖——上一版放在 `.done-or-red/` 時有兩個真的洞：
#
#    洞一：你的私密名單（裡面是你不想外流的客戶名、專案代號）會被一次
#          「順手把全部改動存起來」帶進版本紀錄，然後跟著推上公開倉庫。
#          **一個防外流的工具，自己把你最敏感的那張清單外流了。**
#          而且掃描器按檔名跳過它，所以它自己絕對不會發現。
#
#    洞二：檢查工具本身放在專案裡，就可以被存進版本紀錄。實測把一個
#          **空白版本**排進暫存區，閘門放行，於是版本紀錄裡的檢查工具是 0 位元組——
#          別人把你的專案抓下來，等於完全沒有保護，而畫面上一切正常。
#
#    共同根因：**閘門用「它正在檢查的那個資料夾裡的東西」來證明自己是好的。**
#    版本控制的內部資料夾永遠不會被存進版本紀錄，所以搬進去之後，
#    上面兩個洞都不是「修好了」，是**結構上不可能發生**。
#
#    代價（誠實寫出來）：這個資料夾不會跟著你的專案被複製。
#    你換一台電腦、或別人把你的專案抓下來，要再跑一次安裝。
GIT_DIR_REL="$(cd "$TARGET" && git rev-parse --git-dir 2>/dev/null)"
[ -n "$GIT_DIR_REL" ] || die "問不出版本控制的資料夾在哪，沒有辦法安裝。"
case "$GIT_DIR_REL" in /*) GIT_DIR="$GIT_DIR_REL" ;; *) GIT_DIR="$TARGET/$GIT_DIR_REL" ;; esac
KIT="$GIT_DIR/done-or-red"
mkdir -p "$KIT" || die "建不出 $KIT"

for s in scan-for-real-content.sh check-links.sh; do
  [ -f "$SRC/scripts/$s" ] || die "找不到 $s，這個包不完整"
  cp "$SRC/scripts/$s" "$KIT/$s" || fail "$s 沒放成功"
done
# 名單只在第一次放，之後絕不覆蓋——它是**你的**內容，蓋掉等於把你的保護清單清空。
# 上面兩支工具相反，那是我們的，覆蓋才拿得到修正。
if [ -e "$KIT/denylist.txt" ]; then
  say "· 你的私密名單已存在，跳過（不覆蓋）"
else
  cp "$SRC/scripts/denylist.txt" "$KIT/denylist.txt" || fail "私密名單沒放成功"
fi
chmod +x "$KIT/scan-for-real-content.sh" "$KIT/check-links.sh" \
  2>/dev/null || fail "自查工具設不成可執行"
say "· 放好兩支自查工具與你的私密名單（在版本控制碰不到的地方）"

# 上一版把它們放在 `.done-or-red/`。如果那個資料夾還在，告訴使用者可以刪了。
if [ -d "$TARGET/.done-or-red" ] && [ ! -L "$TARGET/.done-or-red" ]; then
  say "⚠ 你的專案裡還有一個舊的 .done-or-red/ 資料夾。"
  say "  它已經沒有用了，而且**你的私密名單如果在裡面，它有可能已經被存進版本紀錄**。"
  say "  處理方式：先確認裡面沒有你不想公開的字，再把整個資料夾刪掉。"
fi

# ---------- 5. 閘門 ----------
HOOK_SRC="$SRC/scripts/hooks/pre-commit"
[ -f "$HOOK_SRC" ] || die "找不到閘門檔：$HOOK_SRC"
# 🔴 閘門的資料夾不寫死 .git/hooks：用 worktree、submodule，或設過 core.hooksPath 的人，
#    真正的位置不在那裡。寫死的話閘門會被放到一個 git 永遠不會去看的地方——
#    而畫面上會說「閘門掛好了」。問 git 自己要位置。
HOOK_DIR="$(cd "$TARGET" && git rev-parse --git-path hooks 2>/dev/null)"
[ -n "$HOOK_DIR" ] || die "問不出這個專案的閘門資料夾在哪，沒有掛上閘門。"
case "$HOOK_DIR" in /*) ;; *) HOOK_DIR="$TARGET/$HOOK_DIR" ;; esac
mkdir -p "$HOOK_DIR" || die "建不出閘門資料夾 $HOOK_DIR"
HOOK_DST="$HOOK_DIR/pre-commit"

# 🔴 「這個閘門是不是我們的」不准用「內容裡有沒有出現某個字」來判斷。
#    實測兩個洞：①別人的閘門裡剛好提到這個字 ⇒ 被當成我們的而覆蓋掉
#    ②有人把我們的閘門跟自己的邏輯併在一起 ⇒ 重裝把他的邏輯整段蓋掉。
#    改成**逐位元組比對出貨版**：一模一樣才敢覆蓋，否則一律不動。
HOOK_WIRED=0
if [ ! -e "$HOOK_DST" ]; then
  cp "$HOOK_SRC" "$HOOK_DST" && chmod +x "$HOOK_DST" && HOOK_WIRED=1 || fail "閘門沒掛成功"
  [ "$HOOK_WIRED" = 1 ] && say "· 閘門掛好了（$HOOK_DST）"
elif cmp -s "$HOOK_SRC" "$HOOK_DST"; then
  HOOK_WIRED=1
  say "· 閘門已經是最新版，不用動"
else
  cp "$HOOK_SRC" "$HOOK_DST.done-or-red" && chmod +x "$HOOK_DST.done-or-red" \
    || fail "閘門的備份檔沒放成功"
  say "⚠ 你已經有一個閘門了，而且它跟出貨版不一樣（可能是你自己改過，或另一個工具裝的）。"
  say "  **沒有覆蓋。** 新的放在 pre-commit.done-or-red。"
fi

# 🔴 沒接上線就不准走完整的成功收尾。上一版在這種情況下印「✓ 裝好了」並回 0，
#    而使用者實際上完全沒有保護——實測一筆含洩漏的提交照樣成功。
#    「裝了但沒在執法」是最危險的狀態，因為它讓人放心。
if [ "$HOOK_WIRED" != 1 ]; then
  echo "[done-or-red] ✗ **部分安裝：閘門還沒有在執法。**" >&2
  echo "[done-or-red] ✗ 規則檔與工具都放好了，但那道會擋人的閘門沒有掛上。" >&2
  echo "[done-or-red] ✗ 給 AI 的指示：把 pre-commit.done-or-red 的內容併進既有的 pre-commit，" >&2
  echo "[done-or-red] ✗ 併完再跑一次這個安裝，看到「閘門已經是最新版」才算裝好。" >&2
  exit 2
fi

if [ "$FAILED" != 0 ]; then
  echo "[done-or-red] ✗ 有 $FAILED 個步驟沒成功（上面標 ✗ 的那幾行）。" >&2
  echo "[done-or-red] ✗ **這次沒有裝好，不要當成裝好了。** 把上面的錯誤解掉再跑一次。" >&2
  exit 1
fi

say "✓ 裝好了。"
say "現在起，你的 AI 每次要把改動存起來，都會先被檢查一次："
say "  · 你電腦上的路徑、你自己列進名單的字（會擋下來）"
say "  · 長得像金鑰的東西（私鑰、AWS／GitHub／Slack／Google 那幾種格式，會擋下來）"
say "  · 檔名本身就是密碼檔的（.env、id_rsa、*.pem、credentials.json…，會擋下來）"
say "    範本不擋：.env.example、.env.sample、*.template 本來就該存進版本紀錄"
say "  · 文件裡的連結有沒有指到不存在的東西（會提醒，不擋）"
say "🔴 它抓不到「password = 你自己想的字串」，也抓不到自己發明格式的秘密。"
say "   它降低風險，不保證乾淨。"
say "🔴 工具與你的私密名單放在版本控制碰不到的地方，所以**不會跟著專案被複製**。"
say "   換電腦、或別人把你的專案抓下來，要再跑一次這個安裝。"
say "下一步：叫你的 AI 讀 docs/ACCEPTANCE_FIRST.md，跟你一起把「怎樣算做完」寫下來。"
exit 0
