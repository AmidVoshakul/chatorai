# ChatORAI Windows Installation Script (end users, no Flutter required)
# Run as Administrator: Right-click -> "Run with PowerShell"
#
# Downloads the latest prebuilt Windows bundle from GitHub Releases and
# installs it to C:\Program Files\ChatORAI with a Start Menu shortcut.
#
# Usage:
#   .\install_chatorai.ps1                 # latest stable release
#   .\install_chatorai.ps1 -Version 1.2.3  # specific version

#Requires -RunAsAdministrator

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$repo = "AmidVoshakul/chatorai"

function Resolve-Version {
    param([string]$InputVersion)
    if ($InputVersion -ne "") {
        if ($InputVersion -notmatch '^v') { return "v$InputVersion" }
        return $InputVersion
    }
    $api = "https://api.github.com/repos/$repo/releases/latest"
    $release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "chatorai-installer" }
    return $release.tag_name
}

Write-Host "ChatORAI Windows Installation" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

$versionTag = Resolve-Version -InputVersion $Version
Write-Host "Installing ChatORAI $versionTag ..." -ForegroundColor Yellow

$arch = "x64"
$url = "https://github.com/$repo/releases/download/$versionTag/chatorai-windows-$arch.zip"
$tmpDir = Join-Path $env:TEMP ("chatorai-install-" + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $zipPath = Join-Path $tmpDir "bundle.zip"

    Write-Host "Downloading $url ..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $url -OutFile $zipPath -Headers @{ "User-Agent" = "chatorai-installer" }

    Write-Host "Extracting..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

    $installDir = "C:\Program Files\ChatORAI"
    Write-Host "Installing to $installDir ..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Copy-Item -Path (Join-Path $tmpDir "*") -Destination $installDir -Recurse -Force

    # Start Menu shortcut
    Write-Host "Creating Start Menu shortcut..." -ForegroundColor Yellow
    $startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($startMenuPath)
    $Shortcut.TargetPath = "$installDir\chatorai.exe"
    $Shortcut.WorkingDirectory = $installDir
    $Shortcut.Save()

    # Desktop shortcut
    $desktopPath = "$env:USERPROFILE\Desktop\ChatORAI.lnk"
    $Shortcut = $WshShell.CreateShortcut($desktopPath)
    $Shortcut.TargetPath = "$installDir\chatorai.exe"
    $Shortcut.WorkingDirectory = $installDir
    $Shortcut.Save()

    # PATH
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (-not $currentPath.Contains($installDir)) {
        [Environment]::SetEnvironmentVariable('Path', "$currentPath;$installDir", 'Machine')
        Write-Host "Added to PATH. Restart terminal to use 'chatorai'." -ForegroundColor Green
    }

    # Uninstaller
    $uninstallScript = @"
`$installDir = "$installDir"
Write-Host "Uninstalling ChatORAI..."
Remove-Item -Path "$startMenuPath" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$desktopPath" -Force -ErrorAction SilentlyContinue
`$currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
`$newPath = `$currentPath -replace [regex]::Escape(";`$installDir"), ""
`$newPath = `$newPath -replace [regex]::Escape("`$installDir;"), ""
`$newPath = `$newPath -replace [regex]::Escape("`$installDir"), ""
[Environment]::SetEnvironmentVariable('Path', `$newPath, 'Machine')
Remove-Item -Path `$installDir -Recurse -Force
Write-Host "ChatORAI has been uninstalled."
"@
    $uninstallScript | Out-File -FilePath "$installDir\Uninstall-ChatORAI.ps1" -Encoding UTF8

    Write-Host ""
    Write-Host "==============================" -ForegroundColor Green
    Write-Host "Installation complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run from Start Menu or: chatorai" -ForegroundColor White
    Write-Host "To uninstall: PowerShell -ExecutionPolicy Bypass -File '$installDir\Uninstall-ChatORAI.ps1'" -ForegroundColor Yellow
} finally {
    Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
