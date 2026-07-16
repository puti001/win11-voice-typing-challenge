# Windows 11 AutoPunctuation Watchdog / Diagnostic Script
# This script monitors the registry key to show when it gets reset to 0 by TextInputHost.exe.

$path = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceTyping"
$logFile = Join-Path $PSScriptRoot "watchdog_log.txt"
$startTime = Get-Date

function Log-Message($msg) {
    $ts = (Get-Date).ToString("HH:mm:ss.fff")
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor Cyan
    Add-Content -Path $logFile -Value $line
}

Log-Message "========================================="
Log-Message "AutoPunctuation Watchdog Started"
Log-Message "Log file: $logFile"
Log-Message "Press Ctrl+C to stop"
Log-Message "========================================="

$lastValue = $null

while ($true) {
    try {
        if (-not (Test-Path $path)) {
            Log-Message "[Warning] VoiceTyping key not found!"
        } else {
            $val = (Get-ItemProperty $path -ErrorAction Stop).AutoPunctuation
            if ($val -ne $lastValue) {
                Log-Message "[Change] AutoPunctuation value changed: $lastValue -> $val"
                $lastValue = $val
            }
        }
    } catch {
        Log-Message "[Error] $_"
    }
    Start-Sleep -Milliseconds 500
}
