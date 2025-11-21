@echo off
REM ============================================
REM سكربت تشغيل الباكتيست الكامل
REM ============================================

echo ========================================
echo AI Trading System - Backtest Runner
echo ========================================
echo.

REM الانتقال لمجلد المشروع
cd /d C:\AI-Trading-System

REM 1. سحب آخر تحديثات من GitHub
echo [1/4] Pulling latest updates from GitHub...
git pull origin main
if %errorlevel% neq 0 (
    echo ERROR: Failed to pull from GitHub
    pause
    exit /b 1
)
echo.

REM 2. توليد الإشارات بواسطة Python
echo [2/4] Generating signals from strategy...
python bridge\generate_signals.py
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate signals
    pause
    exit /b 1
)
echo.

REM 3. نسخ bridge.txt إلى مجلد MT5 Common Files
echo [3/4] Copying bridge.txt to MT5 Common Files...
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

REM 4. تشغيل MT5 Strategy Tester
echo [4/4] Launching MT5 Strategy Tester...
REM ملاحظة: يجب تعديل المسار حسب مكان تثبيت MT5
set MT5_PATH=C:\Program Files\MetaTrader 5\terminal64.exe
if not exist "%MT5_PATH%" (
    echo WARNING: MT5 not found at default path
    echo Please run MT5 Strategy Tester manually
) else (
    start "" "%MT5_PATH%" /config:automation\tester.ini
)

echo.
echo ========================================
echo Done! Check MT5 Strategy Tester
echo Results will be saved in: results\
echo ========================================
pause
