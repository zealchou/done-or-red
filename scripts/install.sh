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

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-}"

say() { echo "[done-or-red] $*"; }
die() { echo "[done-or-red] ✗ $*" >&2; exit 1; }

[ -n "$TARGET" ] || die "請告訴我要裝到哪個資料夾：bash scripts/install.sh /你的專案資料夾"
[ -d "$TARGET" ] || die "找不到這個資料夾：$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
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

fix_links() {                  # fix_links <檔案>
  local f="$1"
  python3 - "$f" "$REPO_URL" "$OWN_FILES" <<'PY'
import re, sys, os
path, base, own = sys.argv[1], sys.argv[2], set(sys.argv[3].split())
s = open(path, encoding='utf-8').read()
def repl(m):
    target = m.group(1)
    if re.match(r'^(https?:|mailto:|tel:|#)', target):
        return m.group(0)
    clean = target.split('#')[0]
    name = os.path.basename(clean)
    if name in own:                       # 他自己專案裡也會有這一份
        return '](./%s)' % name
    norm = os.path.normpath(clean).lstrip('./')
    return '](%s/%s)' % (base, norm)
s = re.sub(r'\]\(([^)]*)\)', repl, s)
open(path, 'w', encoding='utf-8').write(s)
PY
}

place() {                      # place <目標相對路徑>
  local rel="$1"
  local dst="$TARGET/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then
    if grep -q 'done-or-red' "$dst" 2>/dev/null; then
      say "· $rel 已經裝過了，跳過"
    else
      cp "$RULES_SRC" "$dst.done-or-red.md"
      fix_links "$dst.done-or-red.md"
      say "⚠ $rel 你已經有了，**沒有覆蓋**。新的放在 $rel.done-or-red.md，請把它的內容併進去"
    fi
  else
    cp "$RULES_SRC" "$dst"
    fix_links "$dst"
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
    cp "$t" "$TARGET/docs/$b"
    fix_links "$TARGET/docs/$b"
    say "· 放好 docs/$b"
  fi
done

# ---------- 4. 自查工具 ----------
mkdir -p "$TARGET/.done-or-red"
for s in scan-for-real-content.sh check-links.sh denylist.txt; do
  [ -f "$SRC/scripts/$s" ] || die "找不到 $s，這個包不完整"
  cp "$SRC/scripts/$s" "$TARGET/.done-or-red/$s"
done
chmod +x "$TARGET/.done-or-red/scan-for-real-content.sh" "$TARGET/.done-or-red/check-links.sh"
say "· 放好兩支自查工具"

# ---------- 5. 閘門 ----------
HOOK_SRC="$SRC/scripts/hooks/pre-commit"
[ -f "$HOOK_SRC" ] || die "找不到閘門檔：$HOOK_SRC"
HOOK_DST="$TARGET/.git/hooks/pre-commit"
if [ -e "$HOOK_DST" ] && ! grep -q 'done-or-red' "$HOOK_DST" 2>/dev/null; then
  cp "$HOOK_SRC" "$HOOK_DST.done-or-red"
  chmod +x "$HOOK_DST.done-or-red"
  say "⚠ 你已經有一個閘門了，**沒有覆蓋**。新的放在 pre-commit.done-or-red，請把它併進去"
else
  cp "$HOOK_SRC" "$HOOK_DST"
  chmod +x "$HOOK_DST"
  say "· 閘門掛好了"
fi

say "✓ 裝好了。"
say "現在起，你的 AI 每次要把改動存起來，都會先被檢查一次："
say "  · 有沒有把密碼、金鑰、你電腦上的路徑寫進檔案（會擋下來）"
say "  · 文件裡的連結有沒有指到不存在的東西（會提醒，不擋）"
say "下一步：叫你的 AI 讀 docs/ACCEPTANCE_FIRST.md，跟你一起把「怎樣算做完」寫下來。"
exit 0
