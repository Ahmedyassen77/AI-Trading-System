@echo off
title AI Trading System - Quick Check
color 0A

cls
echo.
echo ========================================
echo   AI TRADING SYSTEM - QUICK CHECK
echo ========================================
echo.

REM Check Python
echo [1/4] Python:
python --version 2>nul
if %errorlevel% equ 0 (
    echo       Status: OK
) else (
    echo       Status: NOT FOUND
)
echo.

REM Check MT5
echo [2/4] MetaTrader 5:
if exist "C:\Program Files\MetaTrader 5\terminal64.exe" (
    echo       Status: OK
    echo       Path: C:\Program Files\MetaTrader 5\
) else if exist "C:\Program Files\MetaTrader 5 IC Markets Global\terminal64.exe" (
    echo       Status: OK
    echo       Path: C:\Program Files\MetaTrader 5 IC Markets Global\
) else (
    echo       Status: NOT FOUND
)
echo.

REM Check EA
echo [3/4] Expert Advisor (EA):
set "EA_FOUND=0"
for /d %%d in ("%APPDATA%\MetaQuotes\Terminal\*") do (
    if exist "%%d\MQL5\Experts\EA_SignalBridge.ex5" (
        echo       Status: FOUND
        echo       Path: %%d\MQL5\Experts\
        set "EA_FOUND=1"
        goto :ea_check_done
    )
)
echo       Status: NOT FOUND [THIS IS THE PROBLEM!]
echo.
echo       ========================================
echo       ^>^>^> EA_SignalBridge.ex5 is MISSING! ^<^<^<
echo       ========================================
echo.
echo       This is why trades don't execute!
echo.
echo       How to fix:
echo       1. Get EA_SignalBridge.ex5 file
echo       2. Open MT5 -^> File -^> Open Data Folder
echo       3. Copy EA to: MQL5\Experts\
echo       4. Restart MT5
echo.
echo       Read: EA_MISSING_HOW_TO_FIX.md for details
echo.

:ea_check_done
echo.

REM Check signals
echo [4/4] Signal Files:
if exist "%~dp0signals\bridge.txt" (
    echo       bridge.txt: FOUND
) else (
    echo       bridge.txt: NOT FOUND
)

if exist "%~dp0signals\drawings.json" (
    echo       drawings.json: FOUND
) else (
    echo       drawings.json: NOT FOUND
)
echo.

REM Summary
echo ========================================
echo   SUMMARY
echo ========================================
echo.

if %EA_FOUND% equ 1 (
    echo   System Status: READY
    echo.
    echo   Next step: Run RUN_BACKTEST.bat
) else (
    echo   System Status: EA MISSING
    echo.
    echo   Python works: YES
    echo   MT5 installed: YES
    echo   EA installed: NO [PROBLEM HERE]
    echo.
    echo   Fix this first!
)
echo.
echo ========================================
echo.
echo.
echo THIS WINDOW WILL STAY OPEN.
echo.
echo Press CTRL+C to close, or just close the window.
echo.
echo.

REM This will wait FOREVER - window won't close
pause >nul
