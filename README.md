# done-or-red

**一件事只有兩種狀態：有證據說它做完了，或者它現在是紅的——沒有「快好了」。**

「已經派出去做」「架子搭好了」「測試跑過一次」都不等於「做完了」，這個工具包收的是
一套逼自己誠實回答「到底完不完成」的紀律模板與判準，不是一套框架、不是一個要安裝的系統。

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
                                    其他地方的測試還全綠，那張圖就是幽靈
「我方測試全綠」                    如果那個值是送出去給別人收的，全綠只證明
                                    你猜的規則自己相容——測試裡的對方是假的
```

## 🔴 這個包主要是給 AI 讀的，不是給你讀的

**你不必把這些檔案讀完。** 每一份的開頭都有一段「給 AI 的指示」——
那是寫給你的 AI 助手看的，讓它在該用的那一刻自己照做。

⇒ **你只要做兩件事**：

1. 開新專案時，跟 AI 一起走 [`START_HERE.md`](./START_HERE.md)（十題，不知道的都有預設答案）。
2. 把 [`AI_RULES.md`](./AI_RULES.md) 複製到你專案最上層，**改成你的助手認得的檔名**
   （Claude Code 是 `CLAUDE.md`、Cursor 是 `.cursorrules`，對照表在那份檔案裡）。
   這是整包唯一一份「你不必記得打開」的檔案——它會被 AI 每一輪自動讀到。

其餘每一份都對應一個特定時刻，什麼時候該讀哪一份看
[`READ_THIS_WHEN.md`](./READ_THIS_WHEN.md)（那張表也是給 AI 看的）。

## 60 秒上手

1. 把 [`templates/`](./templates) 資料夾裡的模板複製到你自己專案的 `docs/` 底下：
   `ACCEPTANCE_FIRST.md`（驗收條件）、`RULINGS.md`（裁決登記簿）、
   `DEFERRED_DEFECTS.md`（延後缺陷）、`PROJECT_NOTEBOOK.md`（工作日誌）。
2. 開工前把 `ACCEPTANCE_FIRST.md` 四段填完，**現在跑一次驗收指令，它應該是紅的**。
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

不需要安裝、不需要連網、不需要任何額外的執行環境——全部是純文字模板加三支 bash 腳本。

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

**要做自動化的時候**

- [`docs/hook-contract.md`](./docs/hook-contract.md) — 一個「會自動擋住你」的東西要先講清楚的八件事

**其他**

- [`docs/pitfall-stories.md`](./docs/pitfall-stories.md) — 踩坑故事（會持續增加，刻意不寫死幾個）
- [`example/`](./example) — 模板／文件用一個虛構專案填完的樣子
- [`scripts/scan-for-real-content.sh`](./scripts/scan-for-real-content.sh) — 掃「有沒有真實內容外流」的自查工具
- [`scripts/check-links.sh`](./scripts/check-links.sh) — 掃「文件之間的指路還在不在」
- [`scripts/test-scan.sh`](./scripts/test-scan.sh) — 上面兩支腳本的自我測試（先紅後綠＋拔除演練）
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — 貢獻指南與行為準則
- [`ISSUE_TEMPLATE.md`](./ISSUE_TEMPLATE.md) — 問題回報模板
- [`LICENSE`](./LICENSE) — 授權條款

## 貢獻指南與問題回報

收陌生人的 issue，但**改動之前請先開一則 issue 討論**，避免一口氣收到一大包沒討論過方向的
修改。完整流程與行為準則見 [`CONTRIBUTING.md`](./CONTRIBUTING.md)；回報問題請照
[`ISSUE_TEMPLATE.md`](./ISSUE_TEMPLATE.md) 的欄位填。

## 這一版刻意沒做的事（第二版再補）

第一版只有文字模板與一支自查腳本，**沒有**把「機械執法的閘門」做成可以直接掛進你自己
CI 的腳本（例如：真的擋下一個沒填驗收條件的提交、真的擋下一個過期的接線圖）。
這不是空殼佔位——是誠實劃線：這一版給的是紀律本身跟怎麼判斷，執法腳本需要配合
各專案自己的工具鏈（Git hook、CI 設定）才有意義，之後另外出。

### ✅ 已補上：文件之間的指路現在有機械在守（2026-09-29）

~~自查腳本只掃「有沒有真實內容外流」，沒有一條斷言在守「文件之間的指路還在不在」。~~
~~所以如果有人把指向某份文件的連結刪掉，`scripts/test-scan.sh` 的六項不會變紅。~~

**已改**：新增 [`scripts/check-links.sh`](./scripts/check-links.sh)，
並接進 `scripts/test-scan.sh` 當樣本 D（正向＋拔除演練＋對整個 repo 實跑）。
現在把任何一份文件的連結改壞，自我測試會變紅。

🔴 **它仍然守不到的三層**（老實列出來，不要以為這件事已經全包了）：

1. **反引號裡的路徑不算連結**——`` `docs/x.md` `` 這樣寫它不檢查。要被守就寫成 markdown 連結。
2. **`#錨點` 只比到檔案層級**，指向一個已經被改名的標題不會紅。
3. **每一份文件開頭「給 AI 的指示」有沒有真的被照做，沒有任何機械判得了。**
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
