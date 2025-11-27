@echo off
REM ============================================
REM MT5 Strategy Tester - Direct Launch
REM يفتح MT5 Strategy Tester مباشرة مع الإعدادات
REM ============================================

echo ========================================
echo AI Trading System - MT5 Tester
echo ========================================
echo.

REM المسارات
set "TERM=C:\Program Files\MetaTrader 5\terminal64.exe"
set "CFG=C:\AI-Trading-System\automation\tester.ini"
set "LOG=C:\AI-Trading-System\Logs\mt5_tester.log"

REM إذا MT5 مثبت في مكان مختلف، غير المسار هنا
if not exist "%TERM%" (
    echo WARNING: MT5 not found at default location
    echo Trying alternative path...
    set "TERM=C:\Program Files\MetaTrader 5 IC Markets Global\terminal64.exe"
)

if not exist "%TERM%" (
    echo ERROR: MT5 terminal64.exe not found!
    echo Please edit run_tester.bat and set correct path
    echo Current path: %TERM%
    pause
    exit /b 1
)

REM إغلاق MT5 إذا كان مفتوح
echo Closing existing MT5 instances...
taskkill /IM terminal64.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul

REM تشغيل MT5 مع Strategy Tester
echo.
echo Starting MT5 Strategy Tester...
echo Config: %CFG%
echo Log: %LOG%
echo.

"%TERM%" /skipupdate /config:"%CFG%" /log:"%LOG%"

if %errorlevel% neq 0 (
    echo ERROR: Failed to start MT5
    pause
    exit /b 1
)

echo.
echo ========================================
echo MT5 Strategy Tester launched
echo ========================================
echo.
echo Next steps:
echo 1. MT5 will open with Strategy Tester
echo 2. Check settings in tester.ini are loaded
echo 3. Press Start to run backtest
echo 4. Results will be in: results\backtest_report.html
echo ========================================

REM لا تغلق النافذة لترى أي أخطاء
