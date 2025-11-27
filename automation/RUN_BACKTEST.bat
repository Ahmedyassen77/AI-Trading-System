@echo off
REM ============================================
REM SIMPLE RUNNER - الأسرع والأبسط
REM ============================================
REM هذا الملف يعمل كل شيء تلقائياً:
REM 1. يولد الإشارات
REM 2. ينسخها لـ MT5
REM 3. يفتح MT5 Strategy Tester
REM ============================================

cd /d C:\AI-Trading-System

echo ========================================
echo Starting Backtest...
echo ========================================
echo.

REM توليد الإشارات
echo Generating signals...
python bridge\generate_signals.py
if %errorlevel% neq 0 (
    echo ERROR: Signal generation failed!
    pause
    exit /b 1
)

REM نسخ للـ MT5
echo.
echo Copying to MT5...
copy /Y signals\bridge.txt "%APPDATA%\MetaQuotes\Terminal\Common\Files\bridge.txt"
copy /Y signals\drawings.json "%APPDATA%\MetaQuotes\Terminal\Common\Files\drawings.json"

REM تشغيل MT5
echo.
echo Opening MT5 Strategy Tester...
echo.
call automation\run_tester.bat

echo.
echo ========================================
echo Done! MT5 is ready - Press Start
echo ========================================
