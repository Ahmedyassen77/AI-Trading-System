@echo off
REM ============================================
REM Complete Backtest Workflow
REM يعمل كل شيء من البداية للنهاية
REM ============================================

echo ========================================
echo AI Trading System - Complete Backtest
echo ========================================
echo.

REM الانتقال لمجلد المشروع
cd /d C:\AI-Trading-System

REM 1. سحب آخر تحديثات من GitHub
echo [1/6] Pulling latest updates from GitHub...
git pull origin main
if %errorlevel% neq 0 (
    echo WARNING: Failed to pull from GitHub
    echo Continuing with local files...
)
echo.

REM 2. توليد إشارات SMC مع الرسومات
echo [2/6] Generating SMC signals with drawings...
python bridge\generate_signals.py
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate signals
    pause
    exit /b 1
)
echo.

REM 3. نسخ bridge.txt إلى MT5 Common Files
echo [3/6] Copying bridge.txt to MT5...
set MT5_COMMON=%APPDATA%\MetaQuotes\Terminal\Common\Files
if not exist "%MT5_COMMON%" (
    echo ERROR: MT5 Common Files directory not found
    echo Path: %MT5_COMMON%
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
echo [4/6] Copying drawings.json to MT5...
copy /Y signals\drawings.json "%MT5_COMMON%\drawings.json"
if %errorlevel% neq 0 (
    echo ERROR: Failed to copy drawings.json
    pause
    exit /b 1
)
echo.

REM 5. نسخ التحليل للرجوع إليه
echo [5/6] Copying analysis file...
if not exist "results" mkdir results
copy /Y signals\smc_analysis.json results\latest_analysis.json
echo.

REM 6. تشغيل MT5 Strategy Tester
echo [6/6] Launching MT5 Strategy Tester...
echo.
call automation\run_tester.bat

echo.
echo ========================================
echo Complete! Check MT5 Strategy Tester
echo ========================================
echo.
echo Files prepared:
echo - bridge.txt (signals)
echo - drawings.json (visualization)
echo - latest_analysis.json (full analysis)
echo.
echo MT5 Strategy Tester should be open now
echo Press Start in Strategy Tester to run backtest
echo ========================================
