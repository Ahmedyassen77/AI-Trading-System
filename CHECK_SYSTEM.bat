@echo off
REM ============================================
REM System Checker - فحص النظام الكامل
REM ============================================

REM كتابة النتيجة في ملف
set "LOGFILE=system_check_result.txt"
echo. > "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"
echo   AI Trading System - System Check >> "%LOGFILE%"
echo   Date: %date% %time% >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

cls
echo.
echo ========================================
echo   AI Trading System - System Check
echo ========================================
echo.
echo Writing results to: %LOGFILE%
echo.

set "ERRORS=0"

REM 1. فحص Python
echo [1/7] Checking Python...
echo [1/7] Checking Python... >> "%LOGFILE%"
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python installed
    echo   [OK] Python installed >> "%LOGFILE%"
    for /f "tokens=*" %%a in ('python --version 2^>^&1') do (
        echo   %%a
        echo   %%a >> "%LOGFILE%"
    )
) else (
    echo   [ERROR] Python NOT installed!
    echo   [ERROR] Python NOT installed! >> "%LOGFILE%"
    echo   Download from: https://www.python.org/downloads/
    echo   Download from: https://www.python.org/downloads/ >> "%LOGFILE%"
    set /a ERRORS+=1
)
echo. >> "%LOGFILE%"

REM 2. فحص المكتبات
echo.
echo [2/7] Checking Python libraries...
echo [2/7] Checking Python libraries... >> "%LOGFILE%"
python -c "import pandas, yaml, numpy" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python libraries installed
    echo   [OK] Python libraries installed >> "%LOGFILE%"
) else (
    echo   [ERROR] Libraries missing!
    echo   [ERROR] Libraries missing! >> "%LOGFILE%"
    echo   Run: pip install -r requirements.txt
    echo   Run: pip install -r requirements.txt >> "%LOGFILE%"
    set /a ERRORS+=1
)
echo. >> "%LOGFILE%"

REM 3. فحص MT5
echo.
echo [3/7] Checking MetaTrader 5...
echo [3/7] Checking MetaTrader 5... >> "%LOGFILE%"
set "MT5_FOUND=0"
set "MT5_PATH="

if exist "C:\Program Files\MetaTrader 5\terminal64.exe" (
    echo   [OK] MT5 found
    echo   [OK] MT5 found >> "%LOGFILE%"
    echo   Path: C:\Program Files\MetaTrader 5\
    echo   Path: C:\Program Files\MetaTrader 5\ >> "%LOGFILE%"
    set "MT5_FOUND=1"
    set "MT5_PATH=C:\Program Files\MetaTrader 5\"
) else if exist "C:\Program Files\MetaTrader 5 IC Markets Global\terminal64.exe" (
    echo   [OK] MT5 found
    echo   [OK] MT5 found >> "%LOGFILE%"
    echo   Path: C:\Program Files\MetaTrader 5 IC Markets Global\
    echo   Path: C:\Program Files\MetaTrader 5 IC Markets Global\ >> "%LOGFILE%"
    set "MT5_FOUND=1"
    set "MT5_PATH=C:\Program Files\MetaTrader 5 IC Markets Global\"
) else (
    echo   [ERROR] MT5 NOT found!
    echo   [ERROR] MT5 NOT found! >> "%LOGFILE%"
    echo   Install MT5 from your broker
    echo   Install MT5 from your broker >> "%LOGFILE%"
    set /a ERRORS+=1
)
echo. >> "%LOGFILE%"

REM 4. فحص مجلد Common Files
echo.
echo [4/7] Checking MT5 Common Files...
echo [4/7] Checking MT5 Common Files... >> "%LOGFILE%"
set "MT5_COMMON=%APPDATA%\MetaQuotes\Terminal\Common\Files"
if exist "%MT5_COMMON%" (
    echo   [OK] Common Files folder exists
    echo   [OK] Common Files folder exists >> "%LOGFILE%"
    echo   Path: %MT5_COMMON%
    echo   Path: %MT5_COMMON% >> "%LOGFILE%"
    
    REM فحص الملفات الموجودة
    if exist "%MT5_COMMON%\bridge.txt" (
        echo   [OK] bridge.txt found in Common Files
        echo   [OK] bridge.txt found in Common Files >> "%LOGFILE%"
    ) else (
        echo   [INFO] bridge.txt not found in Common Files
        echo   [INFO] bridge.txt not found in Common Files >> "%LOGFILE%"
        echo   Run RUN_BACKTEST.bat to generate it
        echo   Run RUN_BACKTEST.bat to generate it >> "%LOGFILE%"
    )
    
    if exist "%MT5_COMMON%\drawings.json" (
        echo   [OK] drawings.json found in Common Files
        echo   [OK] drawings.json found in Common Files >> "%LOGFILE%"
    ) else (
        echo   [INFO] drawings.json not found in Common Files
        echo   [INFO] drawings.json not found in Common Files >> "%LOGFILE%"
    )
) else (
    echo   [WARNING] Common Files folder not found
    echo   [WARNING] Common Files folder not found >> "%LOGFILE%"
    echo   MT5 needs to be opened at least once
    echo   MT5 needs to be opened at least once >> "%LOGFILE%"
)
echo. >> "%LOGFILE%"

REM 5. فحص EA
echo.
echo [5/7] Checking EA files...
echo [5/7] Checking EA files... >> "%LOGFILE%"
set "EA_FOUND=0"
set "EA_PATH="

REM البحث في كل مجلدات Terminal
for /d %%d in ("%APPDATA%\MetaQuotes\Terminal\*") do (
    if exist "%%d\MQL5\Experts\EA_SignalBridge.ex5" (
        echo   [OK] EA found!
        echo   [OK] EA found! >> "%LOGFILE%"
        echo   Path: %%d\MQL5\Experts\EA_SignalBridge.ex5
        echo   Path: %%d\MQL5\Experts\EA_SignalBridge.ex5 >> "%LOGFILE%"
        set "EA_FOUND=1"
        set "EA_PATH=%%d\MQL5\Experts\EA_SignalBridge.ex5"
        goto :ea_found
    )
)

:ea_not_found
echo   [ERROR] EA NOT FOUND!
echo   [ERROR] EA NOT FOUND! >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   ======================================== >> "%LOGFILE%"
echo   CRITICAL: EA_SignalBridge.ex5 is MISSING! >> "%LOGFILE%"
echo   ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   Without EA, the system CANNOT execute trades! >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   You need to place EA_SignalBridge.ex5 in: >> "%LOGFILE%"
echo   %APPDATA%\MetaQuotes\Terminal\[TERMINAL_ID]\MQL5\Experts\ >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   How to find the correct folder: >> "%LOGFILE%"
echo   1. Open MT5 >> "%LOGFILE%"
echo   2. File -^> Open Data Folder >> "%LOGFILE%"
echo   3. Go to: MQL5\Experts\ >> "%LOGFILE%"
echo   4. Copy EA_SignalBridge.ex5 there >> "%LOGFILE%"
echo   5. Restart MT5 >> "%LOGFILE%"
echo   ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"
set /a ERRORS+=1
goto :ea_check_done

:ea_found
echo. >> "%LOGFILE%"

:ea_check_done

REM 6. فحص ملفات الإشارات المحلية
echo.
echo [6/7] Checking local signal files...
echo [6/7] Checking local signal files... >> "%LOGFILE%"
if exist "signals\bridge.txt" (
    echo   [OK] signals\bridge.txt exists
    echo   [OK] signals\bridge.txt exists >> "%LOGFILE%"
    for /f %%a in ('type "signals\bridge.txt" ^| find /c /v ""') do (
        echo   Lines: %%a
        echo   Lines: %%a >> "%LOGFILE%"
    )
) else (
    echo   [INFO] No signals generated yet
    echo   [INFO] No signals generated yet >> "%LOGFILE%"
    echo   Run: python bridge\generate_signals.py
    echo   Run: python bridge\generate_signals.py >> "%LOGFILE%"
)

if exist "signals\drawings.json" (
    echo   [OK] signals\drawings.json exists
    echo   [OK] signals\drawings.json exists >> "%LOGFILE%"
) else (
    echo   [INFO] No drawings generated yet
    echo   [INFO] No drawings generated yet >> "%LOGFILE%"
)
echo. >> "%LOGFILE%"

echo.
echo [7/7] Summary...
echo [7/7] Summary... >> "%LOGFILE%"
echo.
echo ======================================== >> "%LOGFILE%"

if %ERRORS% equ 0 (
    if %EA_FOUND% equ 1 (
        echo   STATUS: READY [GREEN]
        echo   STATUS: READY [GREEN] >> "%LOGFILE%"
        echo   System is fully configured!
        echo   System is fully configured! >> "%LOGFILE%"
    ) else (
        echo   STATUS: INCOMPLETE [YELLOW]
        echo   STATUS: INCOMPLETE [YELLOW] >> "%LOGFILE%"
        echo   System works but EA is missing
        echo   System works but EA is missing >> "%LOGFILE%"
        echo   Signals will be generated but NOT executed
        echo   Signals will be generated but NOT executed >> "%LOGFILE%"
    )
) else (
    echo   STATUS: NOT READY [RED]
    echo   STATUS: NOT READY [RED] >> "%LOGFILE%"
    echo   Found %ERRORS% error(s) - see details above
    echo   Found %ERRORS% error(s) - see details above >> "%LOGFILE%"
)
echo ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

REM تعليمات
echo. >> "%LOGFILE%"
echo NEXT STEPS: >> "%LOGFILE%"
echo =========== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

if %ERRORS% gtr 0 (
    echo Fix the errors above first! >> "%LOGFILE%"
    echo. >> "%LOGFILE%"
)

if %EA_FOUND% equ 0 (
    echo [MOST IMPORTANT] GET EA FILE: >> "%LOGFILE%"
    echo - You need: EA_SignalBridge.ex5 >> "%LOGFILE%"
    echo - Place it in: MT5 Data Folder\MQL5\Experts\ >> "%LOGFILE%"
    echo - How: Open MT5 -^> File -^> Open Data Folder >> "%LOGFILE%"
    echo. >> "%LOGFILE%"
) else (
    echo [OK] You can now run: RUN_BACKTEST.bat >> "%LOGFILE%"
    echo. >> "%LOGFILE%"
)

REM عرض النتيجة
cls
echo.
echo ========================================
echo   CHECK COMPLETE
echo ========================================
echo.
type "%LOGFILE%"
echo.
echo ========================================
echo Results saved to: %LOGFILE%
echo ========================================
echo.
echo.
echo ========================================
echo IMPORTANT: Read the results above carefully!
echo ========================================
echo.
pause
