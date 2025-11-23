@echo off
REM ============================================
REM SMC Strategy Backtest Runner
REM ============================================

echo ========================================
echo AI Trading System - SMC Backtest
echo ========================================
echo.

REM الانتقال لمجلد المشروع
cd /d C:\AI-Trading-System

REM 1. سحب آخر تحديثات من GitHub
echo [1/5] Pulling latest updates from GitHub...
git pull origin main
if %errorlevel% neq 0 (
    echo ERROR: Failed to pull from GitHub
    pause
    exit /b 1
)
echo.

REM 2. توليد إشارات SMC مع الرسومات
echo [2/5] Generating SMC signals with drawings...
python bridge\generate_smc_signals.py
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate SMC signals
    pause
    exit /b 1
)
echo.

REM 3. نسخ bridge.txt إلى MT5 Common Files
echo [3/5] Copying bridge.txt to MT5...
set MT5_COMMON=%APPDATA%\MetaQuotes\Terminal\Common\Files
if not exist "%MT5_COMMON%" (
    echo ERROR: MT5 Common Files directory not found
    pause
    exit /b 1
)

copy /Y signals\bridge.txt "%MT5_COMMON%\bridge.txt"
if %errorlevel% neq 0 (
    echo ERROR: Failed to copy bridge.txt
    pause
    exit /b 1
)
echo.

REM 4. نسخ drawings.json إلى MT5 Common Files
echo [4/5] Copying drawings.json to MT5...
copy /Y signals\drawings.json "%MT5_COMMON%\drawings.json"
if %errorlevel% neq 0 (
    echo ERROR: Failed to copy drawings.json
    pause
    exit /b 1
)
echo.

REM 5. نسخ smc_analysis.json للرجوع إليه
echo [5/5] Copying analysis file...
copy /Y signals\smc_analysis.json results\latest_smc_analysis.json
echo.

echo ========================================
echo Done! Files ready for MT5
echo ========================================
echo.
echo Files copied to MT5:
echo - bridge.txt (trading signals)
echo - drawings.json (SMC visualization)
echo.
echo Next steps:
echo 1. Open MT5
echo 2. Load EA_SignalBridge on chart
echo 3. EA will read both files and:
echo    - Draw all SMC concepts
echo    - Execute trades
echo.
echo Analysis saved to: results\latest_smc_analysis.json
echo ========================================

pause
