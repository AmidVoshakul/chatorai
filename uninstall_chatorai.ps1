# ChatORAI uninstaller (user-level, no elevation required)
#
# Supports: -KeepConfig, -KeepData, -Force, -DryRun
# Called by `chatorai uninstall` on Windows. Installs to the current user's
# %LOCALAPPDATA% (no Administrator / RunAs needed).

#Requires -Version 5.1
param(
    [switch]$KeepConfig,
    [switch]$KeepData,
    [switch]$Force,
    [switch]$DryRun
)

$installDir = "$env:LOCALAPPDATA\ChatORAI"
$startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk"
$desktopPath = "$env:USERPROFILE\Desktop\ChatORAI.lnk"

if (-not $Force -and -not $DryRun) {
    $confirm = Read-Host "This will uninstall ChatORAI. Continue? [y/N]"
    if ($confirm -notmatch '^[yY]') { Write-Host "Aborted."; exit 0 }
}

if ($DryRun) {
    Write-Host "The following would be removed:"
    Write-Host "  Application: $installDir"
    Write-Host "  Start Menu shortcut: $startMenuPath"
    Write-Host "  Desktop shortcut: $desktopPath"
    if (-not $KeepData) { Write-Host "  Application data: $env:APPDATA\chatorai" }
    if (-not $KeepConfig) { Write-Host "  Config: $env:APPDATA\chatorai\config" }
    Write-Host "Dry run - no changes made"
    exit 0
}

Write-Host "Uninstalling ChatORAI..."
Remove-Item -Path "$startMenuPath" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$desktopPath" -Force -ErrorAction SilentlyContinue

# Remove user PATH entry without corrupting other entries.
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($currentPath) {
    $entries = $currentPath -split ';' | Where-Object { $_.Trim() -ne '' -and $_.Trim() -ne $installDir }
    $newPath = $entries -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class EnvNotify {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
'@
    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1a
    $result = [UIntPtr]::Zero
    [EnvNotify]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
}

Remove-Item -Path "$installDir" -Recurse -Force -ErrorAction SilentlyContinue

if (-not $KeepData) {
    Remove-Item -Path "$env:APPDATA\chatorai" -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not $KeepConfig) {
    Remove-Item -Path "$env:APPDATA\chatorai\config" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "ChatORAI has been uninstalled."
