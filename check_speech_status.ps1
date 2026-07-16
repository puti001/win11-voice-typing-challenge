# Windows 11 Voice Typing Environment Diagnostic Tool

Write-Host "=== System Information ===" -ForegroundColor Yellow
[System.Environment]::OSVersion.Version
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild

Write-Host "`n=== Voice Typing Registry Settings ===" -ForegroundColor Yellow
$vtPath = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceTyping"
if (Test-Path $vtPath) {
    Get-ItemProperty $vtPath | Select-Object AutoPunctuation, LauncherEnabled | Format-List
} else {
    Write-Host "VoiceTyping key not found" -ForegroundColor Red
}

Write-Host "`n=== Installed OneCore Language Packages ===" -ForegroundColor Yellow
$enginesPath = "C:\Windows\Speech_OneCore\Engines\SR"
if (Test-Path $enginesPath) {
    Get-ChildItem $enginesPath | Select-Object Name, LastWriteTime
} else {
    Write-Host "OneCore Speech engines path not found" -ForegroundColor Red
}

Write-Host "`n=== MicrosoftWindows.Client.CBS Package Status ===" -ForegroundColor Yellow
Get-AppxPackage -Name MicrosoftWindows.Client.CBS | Select-Object Name, Version, InstallLocation

Write-Host "`n=== Diagnostic completed ===" -ForegroundColor Green
