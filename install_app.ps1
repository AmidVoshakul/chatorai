# ChatORAI Windows Installation Script
# Run as Administrator: Right-click → "Run with PowerShell"

#Requires -RunAsAdministrator

Write-Host "ChatORAI Windows Installation" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if application is built
$chatoraiExe = Join-Path $PSScriptRoot "build\windows\runner\Release\chatorai.exe"
if (-not (Test-Path $chatoraiExe)) {
    Write-Host "ERROR: Application not built!" -ForegroundColor Red
    Write-Host "Please run first: flutter build windows --release" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Define installation directory
$installDir = "C:\Program Files\ChatORAI"

# Create installation directory
Write-Host "Creating installation directory: $installDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# Copy application files
Write-Host "Copying application files..." -ForegroundColor Yellow
Copy-Item -Path (Join-Path $PSScriptRoot "build\windows\runner\Release\*") -Destination $installDir -Recurse -Force

# Create Start Menu shortcut
Write-Host "Creating Start Menu shortcut..." -ForegroundColor Yellow
$startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($startMenuPath)
$Shortcut.TargetPath = "$installDir\chatorai.exe"
$Shortcut.WorkingDirectory = $installDir
$Shortcut.Save()

# Ask for Desktop shortcut
Write-Host ""
$createDesktop = Read-Host "Create Desktop shortcut? (Y/N)"
if ($createDesktop -eq 'Y' -or $createDesktop -eq 'y') {
    $desktopPath = "$env:USERPROFILE\Desktop\ChatORAI.lnk"
    $Shortcut = $WshShell.CreateShortcut($desktopPath)
    $Shortcut.TargetPath = "$installDir\chatorai.exe"
    $Shortcut.WorkingDirectory = $installDir
    $Shortcut.Save()
    Write-Host "Desktop shortcut created." -ForegroundColor Green
}

# Ask for PATH addition
Write-Host ""
$addToPath = Read-Host "Add ChatORAI to system PATH? (Y/N)"
if ($addToPath -eq 'Y' -or $addToPath -eq 'y') {
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (-not $currentPath.Contains($installDir)) {
        [Environment]::SetEnvironmentVariable('Path', "$currentPath;$installDir", 'Machine')
        Write-Host "Added to PATH. You may need to restart terminal." -ForegroundColor Green
    } else {
        Write-Host "Already in PATH." -ForegroundColor Yellow
    }
}

# Create uninstaller
Write-Host ""
Write-Host "Creating uninstaller..." -ForegroundColor Yellow
$uninstallScript = @"
# ChatORAI Uninstaller
# Run as Administrator

`$installDir = "$installDir"

Write-Host "Uninstalling ChatORAI..." -ForegroundColor Red

# Remove Start Menu shortcut
Remove-Item -Path "$startMenuPath" -Force -ErrorAction SilentlyContinue

# Remove Desktop shortcut (if exists)
`$desktopPath = "$env:USERPROFILE\Desktop\ChatORAI.lnk"
Remove-Item -Path `$desktopPath -Force -ErrorAction SilentlyContinue

# Remove from PATH
`$currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
`$newPath = `$currentPath -replace [regex]::Escape(";$installDir"), ""
`$newPath = `$newPath -replace [regex]::Escape("$installDir;"), ""
`$newPath = `$newPath -replace [regex]::Escape("$installDir"), ""
[Environment]::SetEnvironmentVariable('Path', `$newPath, 'Machine')

# Remove installation directory
Remove-Item -Path `$installDir -Recurse -Force

Write-Host "ChatORAI has been uninstalled." -ForegroundColor Green
Write-Host "Press Enter to exit..."
Read-Host
"@

$uninstallScript | Out-File -FilePath "$installDir\Uninstall-ChatORAI.ps1" -Encoding UTF8

Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run ChatORAI from:" -ForegroundColor White
Write-Host "  • Start Menu: Search for 'ChatORAI'" -ForegroundColor White
Write-Host "  • Command Line: chatorai" -ForegroundColor White
Write-Host "  • Or from: $installDir\chatorai.exe" -ForegroundColor White
Write-Host ""
Write-Host "To uninstall, run:" -ForegroundColor Yellow
Write-Host "  PowerShell -ExecutionPolicy Bypass -File '$installDir\Uninstall-ChatORAI.ps1'" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"