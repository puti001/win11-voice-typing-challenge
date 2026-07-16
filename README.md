# The Windows 11 Voice Typing Auto-Punctuation Bug Challenge 🛠️🤖

Welcome to the **Windows 11 Voice Typing Auto-Punctuation Bug Challenge**. 

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

## 📂 Repository Structure

- `README.md`: This file.
- `watchdog.ps1`: A PowerShell script that monitors the dummy registry key `AutoPunctuation` to log when the system tries to reset it.
- `check_speech_status.ps1`: A quick diagnostic script to check your local speech packages and service states.

---

## 🤝 How to Contribute

If you find a working solution:
1. Fork this repository.
2. Add your script/tool to a new folder named after your solution (e.g., `/solutions/ui-automation-fix/`).
3. Open a Pull Request with a brief explanation of how you bypassed the `settings.dat` lock or UWP config limit.

Let's solve this annoying Windows 11 bug together! 🚀
