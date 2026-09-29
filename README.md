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

## 60 秒上手

1. 把 [`templates/`](./templates) 資料夾裡的三份模板複製到你自己專案的 `docs/` 底下：
   `ACCEPTANCE_FIRST.md`（驗收條件）、`RULINGS.md`（裁決登記簿）、`DEFERRED_DEFECTS.md`（延後缺陷）。
2. 開工前把 `ACCEPTANCE_FIRST.md` 四段填完，**現在跑一次驗收指令，它應該是紅的**。
3. 收工前打開 [`docs/three-track-checklist.md`](./docs/three-track-checklist.md)，
   TDD／BDD／GDD 三軌逐條走一遍——**外加最後那一節**：
   這批有沒有任何值是送出去給別人收的？有的話，**對方是替身的那種測試驗不到它**，
   走 [`docs/cross-system-numbers.md`](./docs/cross-system-numbers.md)。
4. 想知道每一條規矩是踩了什麼坑才有的，看 [`docs/pitfall-stories.md`](./docs/pitfall-stories.md)。
5. 想看填完的樣子長怎樣，看 [`example/`](./example) 資料夾（一個虛構的待辦清單命令列工具）。
6. 想跑一次「這個 repo 裡有沒有真實專案內容」的自我檢查：
   `bash scripts/test-scan.sh`（自帶先紅後綠與拔除演練，見腳本內註解）。
   要掃你自己的專案：`bash scripts/scan-for-real-content.sh /你的專案路徑 你的denylist.txt`。
   它會跳過 `.git`／`node_modules`／`.venv`／`__pycache__` 這類**機器自己產生的資料夾**
   （要改用 `SCAN_EXCLUDE_DIRS` 這個環境變數）。🔴 **為什麼要跳過**：`.git/config` 裡有你的
   倉庫網址，不跳過的話你把自己的專案名加進清單就會命中自己、永遠失敗——
   **一個「檢查我有沒有外流」的工具，不該把「你是誰」當成「你洩漏了什麼」。**

不需要安裝、不需要連網、不需要任何額外的執行環境——全部是純文字模板加兩支 bash 腳本。

## 為什麼存在

規矩誰都抄得到。抄不到的是「照著規矩做還是出錯，因為漏問了哪一題」——
見 [`docs/pitfall-stories.md`](./docs/pitfall-stories.md) 的踩坑故事（已改寫成不含任何
真實專案內容的版本）。

## 目錄

- [`templates/ACCEPTANCE_FIRST.md`](./templates/ACCEPTANCE_FIRST.md) — 驗收條件模板
- [`templates/RULINGS.md`](./templates/RULINGS.md) — 裁決登記簿模板
- [`templates/DEFERRED_DEFECTS.md`](./templates/DEFERRED_DEFECTS.md) — 延後缺陷清單模板
- [`docs/three-track-checklist.md`](./docs/three-track-checklist.md) — TDD／BDD／GDD 三軌檢查表
- [`docs/cross-system-numbers.md`](./docs/cross-system-numbers.md) — **三軌裡最容易被漏掉的那一格**：
  任何送出去給別人收的數字（另一個服務、別人的 API、雲端供應商）
- [`docs/gdd.md`](./docs/gdd.md) — 圖驅動開發（Graph-Driven Development）完整方法論
- [`docs/grilling-your-plan.md`](./docs/grilling-your-plan.md) — 怎麼 grill 自己的計畫
- [`docs/pitfall-stories.md`](./docs/pitfall-stories.md) — 踩坑故事（會持續增加，刻意不寫死幾個）
- [`example/`](./example) — 上面五份模板／文件，用一個虛構專案填完的樣子
- [`scripts/scan-for-real-content.sh`](./scripts/scan-for-real-content.sh) — 掃「有沒有真實內容外流」的自查工具
- [`scripts/test-scan.sh`](./scripts/test-scan.sh) — 上面那支腳本的自我測試（先紅後綠＋拔除演練）
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

🔴 **這個包自己也還欠一條它自己要求別人做的事**（獨立覆核指出，誠實記在這裡）：
自查腳本只掃「有沒有真實內容外流」，**沒有一條斷言在守「文件之間的指路還在不在」**。
所以如果有人把 `README.md` 或三軌檢查表裡指向某份文件的連結刪掉，
`scripts/test-scan.sh` 的六項**不會變紅**——而那正是本包 GDD 那一節在講的「幽靈文件」。
現況不是幽靈（每份文件都還有多個入站連結），但**沒有機械在守**。這一條列進下一版。

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
