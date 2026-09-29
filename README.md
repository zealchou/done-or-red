# done-or-red

**一件事只有兩種狀態：有證據說它做完了，或者它現在是紅的——沒有「快好了」。**

「已經派出去做」「架子搭好了」「測試跑過一次」都不等於「做完了」，這個工具包收的是
一套逼自己誠實回答「到底完不完成」的紀律。它不是框架、不需要連網、不需要任何額外的執行環境——
純文字模板、幾支 bash 腳本，加**一道會真的擋住你的閘門**。

## 30 秒看懂：跟「感覺做完了」比起來，這套東西多問了什麼

```
一般的做法                          done-or-red 的做法
──────────────────────           ──────────────────────────
「規格寫完了」                      驗收條件第一段先問「既有的在哪」，
                                    不是「這次要蓋什麼」
「測試都綠燈」                      測試要先證明拔掉實作會變紅，
                                    綠燈才算數（不然可能是裝飾品）
「決定拍板了，寫進文件了」            裁決登記簿逼你搜一次施工排程，
                                    搜不到承接批次就不能寫「進行中」
「這批先不做，記著就好」              延後缺陷清單規定狀態欄要寫
                                    「停在哪一格＋接續要什麼」，不准只寫「延後」
「系統接線圖畫過」                    圖要能被拔除演練檢查：拔掉一個模組，
                                    **它自己的驗收沒有變紅**，那張圖就是幽靈
「我方測試全綠」                    如果那個值是送出去給別人收的，全綠只證明
                                    你猜的規則自己相容——測試裡的對方是假的
```

## 🔴 這個包主要是給 AI 讀的，不是給你讀的

**你不必把這些檔案讀完。** 每一份的開頭都有一段「給 AI 的指示」——
那是寫給你的 AI 助手看的，讓它在該用的那一刻自己照做。

⇒ **你只要做一件事：叫你的 AI 跑一次安裝。**

```
bash scripts/install.sh /你的專案資料夾
```

它會把規則檔用**四家 AI 助手的檔名一次全放好**（所以你用哪一個都通）、把模板放進你的
`docs/`、並且**把一道閘門掛在「存版本」那一步**——之後你的 AI 每次要把改動存起來，
都會先被檢查一次。

🔴 **被擋下來的是你的 AI，不是你。** 它自己看得懂訊息、自己去修；
你只會看到它跟你說「我剛才差點把密碼存進去，已經處理掉了」。

想知道它到底裝了什麼、或不想用腳本 ⇒ 看 [`AI_RULES.md`](./AI_RULES.md) 開頭那張對照表。
開新專案想先把方向講清楚 ⇒ 跟 AI 一起走 [`START_HERE.md`](./START_HERE.md)（十題，不知道的都有預設）。

其餘每一份都對應一個特定時刻，什麼時候該讀哪一份看
[`READ_THIS_WHEN.md`](./READ_THIS_WHEN.md)（那張表也是給 AI 看的）。

## 60 秒上手

1. **跑一次安裝**：`bash scripts/install.sh /你的專案資料夾`
   （模板、四家的規則檔、閘門，它一次弄好。不想用腳本就手動複製
   [`templates/`](./templates) 到你的 `docs/`，並照 [`AI_RULES.md`](./AI_RULES.md) 改檔名。）
2. 開工前把你專案裡的 `docs/ACCEPTANCE_FIRST.md` 四段填完，**現在跑一次驗收指令，它應該是紅的**。
3. 第一版要做什麼，用 [`docs/starter-five.md`](./docs/starter-five.md) 封頂在五件事，
   其餘全部進「不做清單」。每一件動手前填一張
   [`docs/feature-one-pager.md`](./docs/feature-one-pager.md)。
4. 收工前打開 [`docs/three-track-checklist.md`](./docs/three-track-checklist.md)，
   TDD／BDD／GDD 三軌逐條走一遍——**外加最後那一節**：
   這批有沒有任何值是送出去給別人收的？有的話，**對方是替身的那種測試驗不到它**，
   走 [`docs/cross-system-numbers.md`](./docs/cross-system-numbers.md)。
5. 要說「做完了」之前，把驗收條件一條一條填進
   [`docs/evidence-ledger.md`](./docs/evidence-ledger.md)，標清楚哪一格**只有你自己看得出來**。
   要給別人用之前走 [`docs/launch-card.md`](./docs/launch-card.md) 十二項。
6. 想知道每一條規矩是踩了什麼坑才有的，看 [`docs/pitfall-stories.md`](./docs/pitfall-stories.md)。
7. 想看填完的樣子長怎樣，看 [`example/`](./example) 資料夾（一個虛構的待辦清單命令列工具）。
8. 想跑一次「這個 repo 裡有沒有真實專案內容」的自我檢查：
   `bash scripts/test-scan.sh`（自帶先紅後綠與拔除演練，見腳本內註解）。
   要掃你自己的專案：`bash scripts/scan-for-real-content.sh /你的專案路徑 你的denylist.txt`。
   它會跳過 `.git`／`node_modules`／`.venv`／`__pycache__` 這類**機器自己產生的資料夾**
   （要改用 `SCAN_EXCLUDE_DIRS` 這個環境變數）。🔴 **為什麼要跳過**：`.git/config` 裡有你的
   倉庫網址，不跳過的話你把自己的專案名加進清單就會命中自己、永遠失敗——
   **一個「檢查我有沒有外流」的工具，不該把「你是誰」當成「你洩漏了什麼」。**

🔴 **交出去之前**：讓**另一顆模型**挑一次錯（沒有第二顆的話，至少開一個全新對話——做法見 [`docs/second-opinion.md`](./docs/second-opinion.md)），
並且把你的檢查**故意弄壞一次**證明它真的會紅（[`docs/break-it-on-purpose.md`](./docs/break-it-on-purpose.md)）。
這兩件事是整包最有效的兩條，而且都不需要你會任何技術。

## 為什麼存在

規矩誰都抄得到。抄不到的是「照著規矩做還是出錯，因為漏問了哪一題」——
見 [`docs/pitfall-stories.md`](./docs/pitfall-stories.md) 的踩坑故事（已改寫成不含任何
真實專案內容的版本）。

## 目錄

**入口（先看這三份）**

- [`START_HERE.md`](./START_HERE.md) — 開新專案的十題，每題附「不知道就填這個」的預設
- [`AI_RULES.md`](./AI_RULES.md) — 🔴 **唯一一份會被 AI 自動讀到的**，含各家助手的檔名對照表
- [`READ_THIS_WHEN.md`](./READ_THIS_WHEN.md) — 路由表：什麼時候該讀哪一份（附回讀題）

**模板（複製到你自己的專案）**

- [`templates/ACCEPTANCE_FIRST.md`](./templates/ACCEPTANCE_FIRST.md) — 驗收條件模板
- [`templates/RULINGS.md`](./templates/RULINGS.md) — 裁決登記簿模板
- [`templates/DEFERRED_DEFECTS.md`](./templates/DEFERRED_DEFECTS.md) — 延後缺陷清單模板
- [`templates/PROJECT_NOTEBOOK.md`](./templates/PROJECT_NOTEBOOK.md) — 工作日誌模板（邊做邊寫，不是收尾才補）
- [`templates/SKILL_CARD.md`](./templates/SKILL_CARD.md) — 要收一個 skill／自動化進來時填的六格卡

**開工前**

- [`docs/starter-five.md`](./docs/starter-five.md) — 第一版只准做五件事＋不做清單
- [`docs/feature-one-pager.md`](./docs/feature-one-pager.md) — 每個功能動手前的一頁紙
- [`docs/change-size-gate.md`](./docs/change-size-gate.md) — 三問分流：哪些事要慎重，哪些直接做
- [`docs/grilling-your-plan.md`](./docs/grilling-your-plan.md) — 怎麼 grill 自己的計畫

**收工前**

- [`docs/three-track-checklist.md`](./docs/three-track-checklist.md) — TDD／BDD／GDD 三軌檢查表
- [`docs/cross-system-numbers.md`](./docs/cross-system-numbers.md) — **三軌裡最容易被漏掉的那一格**：
  任何送出去給別人收的數字（另一個服務、別人的 API、雲端供應商）
- [`docs/evidence-ledger.md`](./docs/evidence-ledger.md) — 哪一格機器驗得了、哪一格只有人驗得了
- [`docs/launch-card.md`](./docs/launch-card.md) — 要給別人用之前的最後十二項
- [`docs/gdd.md`](./docs/gdd.md) — 圖驅動開發（Graph-Driven Development）完整方法論

**情境卡（這一類專案額外會踩的坑）**

- [`scenarios/web.md`](./scenarios/web.md) — 做網站或網頁的東西
- [`scenarios/data-and-privacy.md`](./scenarios/data-and-privacy.md) — 碰到別人的資料
- [`scenarios/writing-and-docs.md`](./scenarios/writing-and-docs.md) — 做文件、內容、報告

**交出去之前（這兩份最有效）**

- [`docs/second-opinion.md`](./docs/second-opinion.md) — 讓另一顆模型（或至少一個全新對話）挑一次錯，並且逐條判兩次
- [`docs/break-it-on-purpose.md`](./docs/break-it-on-purpose.md) — 故意弄壞它，證明你的檢查真的會叫

**要做自動化的時候**

- [`docs/hook-contract.md`](./docs/hook-contract.md) — 一個「會自動擋住你」的東西要先講清楚的八件事

**其他**

- [`docs/pitfall-stories.md`](./docs/pitfall-stories.md) — 踩坑故事（會持續增加，刻意不寫死幾個）
- [`example/`](./example) — 模板／文件用一個虛構專案填完的樣子
- [`scripts/scan-for-real-content.sh`](./scripts/scan-for-real-content.sh) — 掃「有沒有真實內容外流」的自查工具
- [`scripts/check-links.sh`](./scripts/check-links.sh) — 掃「文件之間的指路還在不在」
- [`scripts/install.sh`](./scripts/install.sh) — **單一安裝入口**：模板、四家規則檔、閘門一次弄好
- [`scripts/hooks/pre-commit`](./scripts/hooks/pre-commit) — 那道閘門本身（掛在「存版本」那一步）
- [`scripts/test-scan.sh`](./scripts/test-scan.sh) — 上面全部的自我測試，44 項（先紅後綠＋十七把刀的拔除演練）
- [`docs/ACCEPTANCE_FIRST.md`](./docs/ACCEPTANCE_FIRST.md) — **這個包自己的**驗收條件（不是模板、不是範例）
- [`docs/DEFERRED_DEFECTS.md`](./docs/DEFERRED_DEFECTS.md) — **這個包自己的**已知缺陷清單（含四條「刻意不做」）
- [`docs/PROJECT_NOTEBOOK.md`](./docs/PROJECT_NOTEBOOK.md) — **這個包自己的**工作日誌
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — 貢獻指南與行為準則
- [`ISSUE_TEMPLATE.md`](./ISSUE_TEMPLATE.md) — 問題回報模板
- [`LICENSE`](./LICENSE) — 授權條款

## 貢獻指南與問題回報

收陌生人的 issue，但**改動之前請先開一則 issue 討論**，避免一口氣收到一大包沒討論過方向的
修改。完整流程與行為準則見 [`CONTRIBUTING.md`](./CONTRIBUTING.md)；回報問題請照
[`ISSUE_TEMPLATE.md`](./ISSUE_TEMPLATE.md) 的欄位填。

## 這一版做不到的事（誠實劃線，不是佔位）

### ✅ 已補上：現在真的有一道會擋人的閘門了（2026-09-29）

~~這個包只有文字模板與自查腳本，沒有把「機械執法的閘門」做出來，之後另外出。~~

**已改**：[`scripts/install.sh`](./scripts/install.sh) 會把
[一道閘門](./scripts/hooks/pre-commit) 掛在「存版本」那一步。三種情況硬度刻意不一樣：

| 情況 | 硬度 | 為什麼 |
|---|---|---|
| 你電腦上的路徑（`/home/你的名字/…`） | **硬擋** | 形狀固定，抓得準 |
| 你自己列進名單的字（專案代號、客戶名、網域） | **硬擋** | 列了就抓得到 |
| 長得像金鑰的東西：私鑰開頭、AWS、GitHub、Slack、Google 那幾種格式 | **硬擋** | 這幾種形狀只有真金鑰才長這樣 |
| **檔名本身就是密碼檔**：`.env`、`id_rsa`、`*.pem`、`credentials.json`… | **硬擋** | 不看內容只看名字，所以沒有誤判內容的空間 |
| 文件裡的連結指不到東西 | **大聲提醒，放行** | 擋下來只會讓人覺得煩，然後把整個閘門刪掉 |
| 閘門自己壞掉（工具不見、讀不到、被掏空、搜尋出錯、暫存檔建不出來） | **擋住** | 「沒檢查」跟「檢查過很乾淨」長得一模一樣，後者是假的 |

`.env.example`、`.env.sample`、`*.template` **不會**被擋——那是教別人怎麼設定的範本，
本來就該存進版本紀錄。**誤擋正確做法的閘門，最後會被刪掉。**

要自己再加一道會擋人的，先填 [`docs/hook-contract.md`](./docs/hook-contract.md) 八格。

### 🔴 這道閘門擋不到的六層（實測過才寫的）

1. **`password = 你自己想的字串` 抓不到，而且是刻意的。**
   🔴 這一條原本寫成「硬擋密碼、金鑰」，那是過度承諾——實測直接放行。
   後來真的加了一條規則去抓它，**三輪獨立覆核各找出一個新洞**：
   後面加一句 `# TODO` 就讓整行豁免、值裡有空白根本沒抓到、
   而真的 `.env.example` 卻被誤擋。**兩個方向同時錯。**
   ⇒ 根因不是規則寫得不好，是**「這串字是真密碼還是教學範例」本身是判斷題**，
   而一條搜尋規則沒有判斷力。**規則整組刪掉**，改成上面那條看檔名的。
   **判準：你正在寫的是機械規則，還是一個判斷？需要知道作者意圖的，不要寫進腳本。**
2. **把真的密碼檔改名成 `secrets.example` 再存進去，它擋不到。**
   範本豁免是按檔名給的，按檔名就繞得過。這是換來「不誤擋正確做法」的代價。
3. **金鑰檢查只認得列出來的那幾種形狀。** 自己發明的前綴、被切成兩半再拼起來的字串抓不到。
   ⇒ **它降低風險，不保證乾淨。** 真正該做的是一開始就不要把秘密寫進檔案。
4. **它在「存版本」那一步才擋，不是在 AI 寫檔案的當下。**
   要在寫的當下攔，需要各家 AI 助手自己的機制，每家不一樣——這個包刻意不綁任何一家。
5. **如果你從來不存版本，它永遠不會觸發。**（實務上你的 AI 會替你存。）
6. **`git commit --no-verify` 可以整段跳過它。** 這是版本控制本身的性質。
   ⇒ **它防的是忙中忘記，不是防蓄意繞過。**

### 🔴 三個已經修掉、但最值得你知道的洞

這三個是**實測繞得過**才改的，寫在這裡因為它們是同一個教訓的三種長相。

**一、閘門原本檢查「你資料夾現在的樣子」，不是「你要存進去的那一份」。**
先把有密碼的版本排進去、再把手上的檔案改乾淨，資料夾看起來就是乾淨的，
而**存進版本紀錄的仍然是有密碼那份**。

**二、你的私密名單原本放在專案資料夾裡**，於是一次「順手把全部改動存起來」
就會把它推上公開倉庫——而掃描器按檔名跳過它，所以它自己絕對不會發現。
**一個防外流的工具，自己把你最敏感的那張清單外流了。**

**三、檢查工具原本也放在專案資料夾裡**，所以一個**空白版本**可以被存進版本紀錄。
別人把你的專案抓下來，等於完全沒有保護，而畫面上一切正常。

🔴 **三個是同一個病：閘門用「它正在檢查的那個資料夾裡的東西」來證明自己是好的。**
修法不是補三個洞，是把工具跟名單搬到**版本控制碰不到的地方**（版本控制自己的內部
資料夾）。搬完之後第二、三個洞不是「修好了」，是**結構上不可能發生**。

**代價（誠實寫出來）**：那個位置不會跟著你的專案被複製。**換一台電腦、或別人把你的
專案抓下來，要再跑一次安裝**；沒跑的話閘門會直接擋下所有存檔並告訴你原因（不會安靜放行）。

**判準：你檢查的那個東西，跟真正會被送出去的那個東西，是同一個嗎？
而你用來檢查的工具，會不會也在被檢查的那一堆裡面？**

### ✅ 已補上：文件之間的指路現在有機械在守（2026-09-29）

~~自查腳本只掃「有沒有真實內容外流」，沒有一條斷言在守「文件之間的指路還在不在」。~~
~~所以如果有人把指向某份文件的連結刪掉，`scripts/test-scan.sh` 的六項不會變紅。~~

**已改**：新增 [`scripts/check-links.sh`](./scripts/check-links.sh)，
並接進 `scripts/test-scan.sh` 當樣本 D。樣本 D 刻意分三份：
**D1 驗抓得到**（而且筆數要剛好對）、**D2 驗不誤報**（五種合法寫法一筆都不准報）、
**D3 驗失效方向**（有檔案讀不到時要回「檢查不完整」，不准回報乾淨）。
現在把任何一份文件的連結改壞，自我測試會變紅。

🔴 **它仍然守不到的四層**（實測過才寫的，不是猜的）：

1. **目標路徑裡有括號會誤報**（例如檔名叫「有(括號).md」）——它只認到第一個右括號。
   目前包裡沒有這種連結；真要用的時候改檔名比改腳本便宜。
2. **反引號裡的連結一樣會被檢查。** 它不是 markdown 解析器，分不出程式碼區段。
   ⇒ 文件裡舉例用的連結要指向真的存在的檔案，或者把中括號跟小括號拆開寫。
   🔴 這一條是**實際被自己抓到的**：上面第 1 點原本把範例寫成完整的連結形狀，
   放在反引號裡，結果 `scripts/test-scan.sh` 當場變紅。**這條限制不是推測，是實測。**
3. **`#錨點` 只比到檔案層級**，指向一個已經被改名的標題不會紅。
4. **每一份文件開頭「給 AI 的指示」有沒有真的被照做，沒有任何機械判得了。**
   那一層只能靠你在對話裡當場抓——這個包從第一頁就在講的那件事。

## 授權與著作權

Copyright (c) 2026 Zeal Chou。授權條款是 **PolyForm Noncommercial 1.0.0**——白話講：
**可以自由讀、用、改、分享，但不可以商用。**

🔴 誠實講清楚三件事：

1. **這樣不算「開源」**——開源的定義本身包含「允許商用」，這份授權不符合，所以
   有些公司的內部政策會直接禁止員工使用這類授權的東西，用之前自己確認一下。
2. 「非商用」的邊界本身是模糊的（例如：顧問拿這套模板用在收費的客戶專案上算不算？）——
   這裡沒有標準答案，拿不準就先問。
3. 公開發布之後很難收回——已經抓下去的人，依當時那份授權繼續使用是合法的。

`LICENSE` 檔已經貼上 **PolyForm Noncommercial License 1.0.0 的官方英文條文逐字全文**
（2026-09-27 自官方純文字版本取得，一字未改、未翻譯）。有疑義時以官方英文原文為準。
