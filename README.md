# The Windows 11 Voice Typing Auto-Punctuation Bug Challenge 🛠️🤖

Welcome to the **Windows 11 Voice Typing Auto-Punctuation Bug Challenge**. 

*This repository and its findings were deeply analyzed, compiled, and published by **AntiGravity** (the desktop version of opencode), an AI Coding Assistant designed by Google DeepMind.*

This repository documents a persistent, system-level bug in **Windows 11 (specifically Build 26200, version 25H2)** where the "Auto-punctuation" setting in the Voice Typing toolbar (`Win + H`) automatically reverts to "Off" whenever you start dictating.

We have tried 15+ different methods (registry modifications, ACL write-locks, CBS package re-registration) and they all failed. **We are open-sourcing this issue as a challenge for software engineers, reverse engineers, and AI Coding Agents to solve.**

---

## 🖥️ System Environment

- **OS**: Windows 11 Home / Pro (Version 25H2)
- **OS Build**: 26200 or later
- **Language**: Traditional Chinese (zh-TW)
- **Active App Package**: `MicrosoftWindows.Client.CBS_cw5n1h2txyewy` (which runs `TextInputHost.exe`)

---

## 🔑 The Core Discovery (Why traditional fixes fail)

The registry key `HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceTyping\AutoPunctuation` **is NOT the actual source of truth** for the Voice Typing UI.

Even when the registry value is programmatically set and locked to `1` (Enabled), the Voice Typing toolbar UI still shows "Off" and refuses to auto-punctuate:
- Registry: `AutoPunctuation = 1`
- UI Toolbar: `AutoPunctuation = Off`

### Where is the real setting stored?
We suspect the actual setting is stored inside the UWP ApplicationData binary database:
```
C:\Users\<Username>\AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat
```
This file is **permanently locked** by multiple system processes (`explorer.exe`, `SearchHost.exe`, `sihost.exe`, `svchost.exe`, etc.). Even if you kill `TextInputHost.exe`, you cannot read or modify this file directly.

Another possible location is the WebView2 local storage of the CBS package:
```
C:\Users\<Username>\AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalState\EBWebView\
```

---

## ❌ Failed Attempts (Do NOT repeat these)

If you (or your AI Agent) are attempting to solve this, **do not waste time on the following methods**:

1. **Registry Toggles**: Changing `AutoPunctuation` or `LauncherEnabled` to `1`. (Ignored by the UI)
2. **Registry Write-Locks (ACL Deny)**: Denying `SetValue` permission to the registry key. (Causes UWP app crashes or silent failures)
3. **IME Modifications**: Setting `Enable Punctuation Auto Finalize` to `1` under `IME\15.0\IMETC`. (Works for a few hours, then gets overwritten)
4. **Settings Sync**: Turning off Windows Settings Backup "Remember my preferences". (No effect)
5. **Privacy Settings**: Toggling Optional Diagnostic Data, or Inking & Typing Personalization. (No effect)
6. **Package Re-registration**: Re-registering `MicrosoftWindows.Client.CBS` package via `Add-AppxPackage`. (Resets the UI, but setting still reverts)
7. **Voice Access**: Toggling the new Windows 11 Voice Access. (Voice Access does not support auto-punctuation locally in zh-TW anyway)

---

## 🎯 The Challenge: How to Solve It?

We need a script (PowerShell, Python, Rust, Go, C#, etc.) or tool that can **successfully force the `Win + H` auto-punctuation toggle to remain "On"** without forcing the user to switch to a local account or reinstall Windows.

Here are some potential avenues of exploration:

### 1. UWP ApplicationData API (.NET / C#)
Since `settings.dat` is managed by the Windows Runtime, can we use the `ApplicationDataManager` API in a script to programmatically write to the settings container of the CBS package?
```csharp
// Example concept:
var manager = ApplicationDataManager.CreateForPackageFamily("MicrosoftWindows.Client.CBS_cw5n1h2txyewy");
manager.LocalSettings.Values["AutoPunctuation"] = true;
```

### 2. UI Automation
Use the Windows UI Automation API to detect when `Win + H` is active, find the settings cog, and programmatically toggle the auto-punctuation checkbox to "On" whenever it reverts to "Off".

### 3. Chromium Local Storage Hack
Since the new Voice Typing UI runs on WebView2, inspect and modify the IndexedDB or LocalStorage files inside:
`...\LocalState\EBWebView\Local Storage\leveldb\`

### 4. Process Monitor (Sysinternals)
Run a deep trace on `TextInputHost.exe` to find the exact file offset or registry key it queries when the user clicks the "Auto-punctuation" toggle.

---

## 🤝 How to Contribute

If you find a working solution:
1. Fork this repository.
2. Add your script/tool to a new folder named after your solution (e.g., `/solutions/ui-automation-fix/`).
3. Open a Pull Request with a brief explanation of how you bypassed the `settings.dat` lock or UWP config limit.

Let's solve this annoying Windows 11 bug together! 🚀

---

## 🇹🇼 繁體中文版說明 (Traditional Chinese Description)

歡迎來到 **Windows 11 語音輸入自動標點符號 Bug 挑戰**。

*本專案的排錯分析、記錄與發佈，均由 Google DeepMind 開發的 AI 程式助理 **AntiGravity (opencode 桌面版)** 在與人類工程師協作的過程中自動整理與推播。*

本專案記錄了 **Windows 11 (特別是 Build 26200，版本 25H2)** 中一個極為頑固的系統級 Bug：當你按下 `Win + H` 開啟語音輸入，並在齒輪設定中手動開啟「自動標點符號」後，只要一開始說話，該設定就會自動彈回「關閉」。

我們已經嘗試了 15 種以上的方法（包括修改登錄檔、鎖定權限、重新註冊 CBS 套件等），但全部宣告失敗。**我們將此問題開源，邀請所有軟體工程師、反向工程專家，以及 AI 程式助理 (Agent) 一起挑戰並解決這個問題！**

---

### 🖥️ 系統環境
- **作業系統**：Windows 11 家用版 / 專業版 (Version 25H2)
- **組建 (Build)**：26200 或更新版本
- **系統語言**：繁體中文 (zh-TW)
- **核心元件**：`MicrosoftWindows.Client.CBS_cw5n1h2txyewy` (執行 `TextInputHost.exe`)

---

### 🔑 核心發現（為什麼傳統修復方法無效？）
登錄檔機碼 `HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceTyping\AutoPunctuation` **根本不是語音輸入面板設定的真正儲存位置**。

即使我們用程式強制把登錄檔的值寫入並鎖定為 `1`（開啟），語音輸入面板的 UI 依然會顯示「關閉」且無法自動加上標點符號：
- 登錄檔：`AutoPunctuation = 1`
- 語音工具列 UI：`自動標點符號 = 關閉`

#### 真正的設定儲存在哪裡？
我們推測真正的設定儲存在 UWP 應用程式的二進位資料庫中：
`C:\Users\<使用者名稱>\AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings\settings.dat`
此檔案被多個系統處理程序（如 `explorer.exe`、`SearchHost.exe` 等）**永久鎖定**。即使你終止了 `TextInputHost.exe`，也無法直接讀取或修改它。

另一個可能的位置是 CBS 套件內的 WebView2 本地儲存：
`C:\Users\<使用者名稱>\AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalState\EBWebView\`

---

### ❌ 已證實無效的嘗試（請勿重複嘗試）
1. **單改登錄檔**：修改 `AutoPunctuation` 或 `LauncherEnabled` 登錄檔值。（UI 會直接無視）
2. **鎖定登錄檔權限 (Deny ACL)**：拒絕變更登錄檔。（會導致 UWP 程式崩潰或靜默失敗）
3. **修改輸入法設定**：修改 `IME\15.0\IMETC` 下的 `Enable Punctuation Auto Finalize`。（僅短暫有效幾小時，隨後失效）
4. **關閉同步**：關閉 Windows 帳戶同步中的「記住我的喜好設定」。（無效果）
5. **隱私權限**：開啟選用診斷資料或墨跡鍵入個人化。（無效果）
6. **重新註冊套件**：使用 `Add-AppxPackage` 重新註冊 `Client.CBS`。（會重置 UI，但設定依然會彈回）
7. **改用語音存取 (Voice Access)**：語音存取本地端目前不支援繁體中文的自動標點。

---

### 🎯 挑戰目標：如何解決它？
我們需要一個腳本（PowerShell、Python、Rust、Go、C# 等）或工具，能**成功強制讓 `Win + H` 的「自動標點符號」保持在「開啟」狀態**，且不需要使用者切換至本機帳戶或重灌系統。

#### 推薦的突破方向：
1. **UWP ApplicationData API (.NET / C#)**：使用 Windows Runtime 的 `ApplicationDataManager` API 程式化寫入 CBS 套件的設定容器。
2. **UI Automation**：使用 Windows UI 自動化 API 監控 `Win + H` 視窗，並在其彈回關閉時自動點選開啟。
3. **Chromium 本地儲存修改**：修改 `EBWebView\Local Storage\leveldb\` 下的資料庫。
4. **Process Monitor 追蹤**：使用 Sysinternals 的 Procmon 深入追蹤 `TextInputHost.exe` 在使用者手動點選開關時，寫入了哪些檔案偏移量或機碼。

讓我們一起解決這個煩人的 Windows 11 Bug 吧！ 🚀
