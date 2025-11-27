@echo off
REM ============================================
REM System Checker - فحص النظام الكامل
REM ============================================

echo.
echo ========================================
echo   AI Trading System - System Check
echo ========================================
echo.

set "ERRORS=0"

REM 1. فحص Python
echo [1/7] Checking Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python installed
    python --version
) else (
    echo   [ERROR] Python NOT installed!
    echo   Download from: https://www.python.org/downloads/
    set /a ERRORS+=1
)
echo.

REM 2. فحص المكتبات
echo [2/7] Checking Python libraries...
python -c "import pandas, yaml, numpy" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python libraries installed
) else (
    echo   [ERROR] Libraries missing!
    echo   Run: pip install -r requirements.txt
    set /a ERRORS+=1
)
echo.

REM 3. فحص MT5
echo [3/7] Checking MetaTrader 5...
set "MT5_FOUND=0"
if exist "C:\Program Files\MetaTrader 5\terminal64.exe" (
    echo   [OK] MT5 found at: C:\Program Files\MetaTrader 5\
    set "MT5_FOUND=1"
) else if exist "C:\Program Files\MetaTrader 5 IC Markets Global\terminal64.exe" (
    echo   [OK] MT5 found at: C:\Program Files\MetaTrader 5 IC Markets Global\
    set "MT5_FOUND=1"
) else (
    echo   [ERROR] MT5 NOT found!
    echo   Install MT5 from your broker
    set /a ERRORS+=1
)
echo.

REM 4. فحص مجلد Common Files
echo [4/7] Checking MT5 Common Files...
set "MT5_COMMON=%APPDATA%\MetaQuotes\Terminal\Common\Files"
if exist "%MT5_COMMON%" (
    echo   [OK] Common Files folder exists
    echo   Path: %MT5_COMMON%
) else (
    echo   [WARNING] Common Files folder not found
    echo   MT5 needs to be opened at least once
)
echo.

REM 5. فحص EA
echo [5/7] Checking EA files...
set "EA_FOUND=0"
if exist "%APPDATA%\MetaQuotes\Terminal\*\MQL5\Experts\EA_SignalBridge.ex5" (
    echo   [OK] EA found
    set "EA_FOUND=1"
) else (
    echo   [ERROR] EA NOT found!
    echo.
    echo   ========================================
    echo   IMPORTANT: EA is MISSING!
    echo   ========================================
    echo   You need to place EA_SignalBridge.ex5 in:
    echo   %APPDATA%\MetaQuotes\Terminal\[TERMINAL_ID]\MQL5\Experts\
    echo.
    echo   Without EA, MT5 cannot read signals!
    echo   ========================================
    set /a ERRORS+=1
)
echo.

REM 6. فحص ملفات الإشارات
echo [6/7] Checking signal files...
if exist "signals\bridge.txt" (
    echo   [OK] bridge.txt exists
    for /f %%a in ('type "signals\bridge.txt" ^| find /c /v ""') do set lines=%%a
    echo   Lines: %lines%
) else (
    echo   [INFO] No signals generated yet
    echo   Run: python bridge\generate_signals.py
)
echo.

if exist "signals\drawings.json" (
    echo   [OK] drawings.json exists
) else (
    echo   [INFO] No drawings generated yet
)
echo.

REM 7. ملخص
echo [7/7] Summary...
echo.
echo ========================================
if %ERRORS% equ 0 (
    echo   STATUS: READY [GREEN]
    echo   System is configured correctly!
) else (
    echo   STATUS: NOT READY [RED]
    echo   Found %ERRORS% error(s) - see above
)
echo ========================================
echo.

REM تعليمات حسب الحالة
if %ERRORS% gtr 0 (
    echo NEXT STEPS:
    echo 1. Fix errors above
    if %EA_FOUND% equ 0 (
        echo 2. GET EA FILE from developer
        echo 3. Place EA in MT5 Experts folder
    )
    echo 4. Run this check again
    echo.
) else (
    if %EA_FOUND% equ 0 (
        echo.
        echo ========================================
        echo   WARNING: EA is still missing!
        echo ========================================
        echo   Even though system is configured,
        echo   you MUST have EA to execute trades!
        echo.
        echo   Contact developer to get:
        echo   - EA_SignalBridge.ex5
        echo   or
        echo   - EA_SignalBridge.mq5 (source)
        echo ========================================
        echo.
    ) else (
        echo READY TO USE:
        echo 1. Run: RUN_BACKTEST.bat
        echo 2. MT5 will open
        echo 3. Press Start in Strategy Tester
        echo.
    )
)

pause
