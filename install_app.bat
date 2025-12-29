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

:: Check if flutter build exists
if not exist "build\windows\runner\Release\chatorai.exe" (
    echo.
    echo ERROR: Application not built. Please run first:
    echo flutter build windows --release
    echo.
    pause
    exit /b 1
)

:: Create installation directory
echo.
echo Creating installation directory...
set INSTALL_DIR=C:\Program Files\ChatORAI
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

:: Copy files
echo Copying application files...
xcopy /s /y "build\windows\runner\Release\*" "%INSTALL_DIR%\"

:: Create Start Menu shortcut
echo Creating Start Menu shortcut...
set SCRIPT="%TEMP%\CreateShortcut.vbs"
echo Set WshShell = CreateObject("WScript.Shell") > %SCRIPT%
echo Set Shortcut = WshShell.CreateShortcut("%APPDATA%\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk") >> %SCRIPT%
echo Shortcut.TargetPath = "%INSTALL_DIR%\chatorai.exe" >> %SCRIPT%
echo Shortcut.WorkingDirectory = "%INSTALL_DIR%" >> %SCRIPT%
echo Shortcut.Save >> %SCRIPT%
cscript //nologo %SCRIPT%
del %SCRIPT%

:: Create Desktop shortcut
echo.
echo Optional: Create Desktop shortcut?
choice /c YN /n /m "Press Y for Yes, N for No"
if %errorlevel% equ 1 (
    set SCRIPT="%TEMP%\CreateDesktopShortcut.vbs"
    echo Set WshShell = CreateObject("WScript.Shell") > %SCRIPT%
    echo Set Shortcut = WshShell.CreateShortcut("%USERPROFILE%\Desktop\ChatORAI.lnk") >> %SCRIPT%
    echo Shortcut.TargetPath = "%INSTALL_DIR%\chatorai.exe" >> %SCRIPT%
    echo Shortcut.WorkingDirectory = "%INSTALL_DIR%" >> %SCRIPT%
    echo Shortcut.Save >> %SCRIPT%
    cscript //nologo %SCRIPT%
    del %SCRIPT%
    echo Desktop shortcut created.
)

:: Add to PATH (optional)
echo.
echo Optional: Add ChatORAI to system PATH?
choice /c YN /n /m "Press Y for Yes, N for No"
if %errorlevel% equ 1 (
    powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';%INSTALL_DIR%', 'Machine')"
    echo Added to PATH. You may need to restart terminal.
)

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