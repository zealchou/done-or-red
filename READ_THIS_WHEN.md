# 什麼時候該讀哪一份

> 這份是路由表。**這個包的檔案不是要一次讀完的**——每一份都對應一個特定時刻。

## 給 AI 的指示（這一段不要刪）

**你在這個專案裡每次要開始一段工作之前，先在下表找出你現在在哪一格，讀那一格指到的檔案。**
讀完要能回答該格「回讀題」——答不出來就是你沒有真的讀進去，回去讀。

🔴 **這一份自己也是一條規矩的實例**：一份無限長的規則會被忽略，
所以核心短、其餘按需要讀。判準：**現在這一刻，哪一份文件會改變我接下來的動作？**
只有那一份要讀。

---

| 你現在在做什麼 | 讀這份 | 🔴 回讀題（答不出來就是沒讀進去） |
|---|---|---|
| **第一次開這個專案** | [`START_HERE.md`](./START_HERE.md) | 十題裡哪兩題不准跳過？為什麼？ |
| **設定 AI 助手** | [`AI_RULES.md`](./AI_RULES.md) | 檔名要改成什麼？怎麼驗它真的讀到了？ |
| **要決定第一版做什麼** | [`docs/starter-five.md`](./docs/starter-five.md) | 五件裡哪一件是第 1 件？判準是什麼？ |
| **要加一個功能** | [`docs/feature-one-pager.md`](./docs/feature-one-pager.md) | 第 2 格與第 4 格必須指向什麼？對不起來代表什麼？ |
| **要開始蓋一個東西** | [`templates/ACCEPTANCE_FIRST.md`](./templates/ACCEPTANCE_FIRST.md) | 第三段那一行現在應該是紅的還是綠的？如果已經是綠的，代表什麼？ |
| **做完一段工作** | [`templates/PROJECT_NOTEBOOK.md`](./templates/PROJECT_NOTEBOOK.md) | 六個欄位裡哪一個留空等於在宣稱全部完成？ |
| **做了一個選擇（選 A 不選 B）** | [`templates/RULINGS.md`](./templates/RULINGS.md) | 什麼情況下狀態不可以寫「進行中」？ |
| **發現問題但這批不修** | [`templates/DEFERRED_DEFECTS.md`](./templates/DEFERRED_DEFECTS.md) | 狀態欄只寫「延後」為什麼不算填完？ |
| **覺得快要做完了** | [`docs/three-track-checklist.md`](./docs/three-track-checklist.md) | 三軌分別檢查什麼？哪一軌最容易被漏掉？ |
| **要說「做完了」之前** | [`docs/evidence-ledger.md`](./docs/evidence-ledger.md) | 哪些事情一律是「人」驗、不准歸給機器？ |
| **這批有一個值要送給別的服務收** | [`docs/cross-system-numbers.md`](./docs/cross-system-numbers.md) | 為什麼「我方測試全綠」在這一格沒有證明力？ |
| **要改動一個比較大的東西** | [`docs/change-size-gate.md`](./docs/change-size-gate.md) | 三題都答「不」的時候該做什麼？替代案那一格為什麼不准寫「沒有別的做法」？ |
| **動工前想找出沒想清楚的地方** | [`docs/grilling-your-plan.md`](./docs/grilling-your-plan.md) | 一個問題要滿足什麼條件才值得問？ |
| **要畫或要改系統接線圖** | [`docs/gdd.md`](./docs/gdd.md) | 怎麼判斷一張圖是不是幽靈？ |
| **要給別人用了／要發布** | [`docs/launch-card.md`](./docs/launch-card.md) | 十二項裡哪些 AI 不准代勾？ |
| **要加一個 skill／自動化（要人去用的）** | [`templates/SKILL_CARD.md`](./templates/SKILL_CARD.md) | 什麼情況下「不要做這個 skill」才是正確答案？ |
| **要加一個會自動擋住人的檢查** | [`docs/hook-contract.md`](./docs/hook-contract.md) | 壞掉的時候是放行還是擋住？這個選擇的代價是什麼？ |
| **這是網站／網頁的東西** | [`scenarios/web.md`](./scenarios/web.md) | 為什麼「網址回 200」不算證據？ |
| **這批會碰到別人的資料** | [`scenarios/data-and-privacy.md`](./scenarios/data-and-privacy.md) | 送給第三方之前該列哪一張清單？為什麼不是另一張？ |
| **產出物是給人讀的文字** | [`scenarios/writing-and-docs.md`](./scenarios/writing-and-docs.md) | 足跡比對零足跡代表什麼？ |
| **想知道某條規矩是踩了什麼坑才有的** | [`docs/pitfall-stories.md`](./docs/pitfall-stories.md) | — |
| **想確認自己沒把真實內容推上公開倉庫** | [`scripts/scan-for-real-content.sh`](./scripts/scan-for-real-content.sh) | 它為什麼要跳過 `.git`？ |
| **想確認文件之間的指路沒斷** | [`scripts/check-links.sh`](./scripts/check-links.sh) | 它守不到哪三層？ |

---

## 🔴 兩件容易搞錯的事

**一、「開工前讀」跟「收工前讀」是兩批，不要合併。**
開工前那批（驗收條件、延後缺陷清單、改動大小）是要**改變你打算怎麼做**；
收工前那批（三軌、證據帳本）是要**擋住你說做完了**。
把它們合在收工一起讀，等於開工前那批沒有作用——這個包的起因案例就是這件事：
**病不在「沒寫」，在「寫了卻沒人在該讀的時候讀」。**

**二、回讀題不是考試，是偵測器。**
它偵測的是「我以為我讀了，其實只是掃過」。答不出來很正常，回去讀那一段就好。
🔴 但**不准自己編一個聽起來合理的答案**——那比答不出來糟，因為它會讓你（和使用者）
以為這一格已經過了。
