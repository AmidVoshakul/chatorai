@echo off
setlocal enabledelayedexpansion

echo ChatORAI Windows Installation
echo ==============================

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: This script requires administrator privileges.
    echo Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

set REPO=AmidVoshakul/chatorai
set VERSION=
set ARCH=x64

:: Parse --version X.Y.Z
set PREV=
for %%a in (%*) do (
    if "!PREV!"=="--version" set VERSION=%%a
    set PREV=%%a
)

echo Resolving latest release...
if "%VERSION%"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest' -Headers @{'User-Agent'='chatorai-installer'}).tag_name"') do set VERSION=%%i
)
if "%VERSION%"=="" (
    echo ERROR: Could not determine latest version.
    pause
    exit /b 1
)
echo Installing ChatORAI %VERSION% ...

set URL=https://github.com/%REPO%/releases/download/%VERSION%/chatorai-windows-%ARCH%.zip
set TMPDIR=%TEMP%\chatorai-install-%RANDOM%
set ZIP=%TMPDIR%\bundle.zip

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

echo Downloading %URL% ...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%ZIP%' -Headers @{'User-Agent'='chatorai-installer'}"

echo Extracting...
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%TMPDIR%' -Force"

set INSTALL_DIR=C:\Program Files\ChatORAI
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Copying application files...
xcopy /s /y "%TMPDIR%\*" "%INSTALL_DIR%\"

:: Start Menu shortcut
set SCRIPT="%TEMP%\CreateShortcut.vbs"
echo Set WshShell = CreateObject("WScript.Shell") > %SCRIPT%
echo Set Shortcut = WshShell.CreateShortcut("%APPDATA%\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk") >> %SCRIPT%
echo Shortcut.TargetPath = "%INSTALL_DIR%\chatorai.exe" >> %SCRIPT%
echo Shortcut.WorkingDirectory = "%INSTALL_DIR%" >> %SCRIPT%
echo Shortcut.Save >> %SCRIPT%
cscript //nologo %SCRIPT%
del %SCRIPT%

:: Desktop shortcut
set SCRIPT="%TEMP%\CreateDesktopShortcut.vbs"
echo Set WshShell = CreateObject("WScript.Shell") > %SCRIPT%
echo Set Shortcut = WshShell.CreateShortcut("%USERPROFILE%\Desktop\ChatORAI.lnk") >> %SCRIPT%
echo Shortcut.TargetPath = "%INSTALL_DIR%\chatorai.exe" >> %SCRIPT%
echo Shortcut.WorkingDirectory = "%INSTALL_DIR%" >> %SCRIPT%
echo Shortcut.Save >> %SCRIPT%
cscript //nologo %SCRIPT%
del %SCRIPT%
echo Desktop shortcut created.

:: Add to PATH
powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';%INSTALL_DIR%', 'Machine')"
echo Added to PATH. You may need to restart terminal.

echo.
echo ==============================
echo Installation complete!
echo.
echo You can now run ChatORAI from:
echo - Start Menu: Search for "ChatORAI"
echo - Command Line: chatorai
echo - Or from: "%INSTALL_DIR%\chatorai.exe"
echo.
echo To uninstall, run:
echo rmdir /s "%INSTALL_DIR%"
echo.
pause
