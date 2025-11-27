@echo off
REM ============================================
REM System Checker - GUARANTEED TO SHOW RESULTS
REM ============================================

set "LOGFILE=%~dp0system_check_result.txt"

REM Clear old log
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
echo Please wait... checking all components...
echo.

set "ERRORS=0"

REM 1. Check Python
echo [1/7] Checking Python...
echo [1/7] Checking Python... >> "%LOGFILE%"
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python installed >> "%LOGFILE%"
    for /f "tokens=*" %%a in ('python --version 2^>^&1') do (
        echo   %%a >> "%LOGFILE%"
    )
) else (
    echo   [ERROR] Python NOT installed! >> "%LOGFILE%"
    echo   Download from: https://www.python.org/downloads/ >> "%LOGFILE%"
    set /a ERRORS+=1
)
echo. >> "%LOGFILE%"

REM 2. Check Python libraries
echo [2/7] Checking Python libraries...
echo [2/7] Checking Python libraries... >> "%LOGFILE%"
python -c "import pandas, yaml, numpy" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python libraries installed >> "%LOGFILE%"
) else (
    echo   [ERROR] Libraries missing! >> "%LOGFILE%"
    echo   Run: pip install -r requirements.txt >> "%LOGFILE%"
    set /a ERRORS+=1
)
echo. >> "%LOGFILE%"

REM 3. Check MT5
echo [3/7] Checking MetaTrader 5...
echo [3/7] Checking MetaTrader 5... >> "%LOGFILE%"
set "MT5_FOUND=0"

if exist "C:\Program Files\MetaTrader 5\terminal64.exe" (
    echo   [OK] MT5 found >> "%LOGFILE%"
    echo   Path: C:\Program Files\MetaTrader 5\ >> "%LOGFILE%"
    set "MT5_FOUND=1"
) else if exist "C:\Program Files\MetaTrader 5 IC Markets Global\terminal64.exe" (
    echo   [OK] MT5 found >> "%LOGFILE%"
    echo   Path: C:\Program Files\MetaTrader 5 IC Markets Global\ >> "%LOGFILE%"
    set "MT5_FOUND=1"
) else (
    echo   [ERROR] MT5 NOT found! >> "%LOGFILE%"
    echo   Install MT5 from your broker >> "%LOGFILE%"
    set /a ERRORS+=1
)
echo. >> "%LOGFILE%"

REM 4. Check MT5 Common Files
echo [4/7] Checking MT5 Common Files...
echo [4/7] Checking MT5 Common Files... >> "%LOGFILE%"
set "MT5_COMMON=%APPDATA%\MetaQuotes\Terminal\Common\Files"
if exist "%MT5_COMMON%" (
    echo   [OK] Common Files folder exists >> "%LOGFILE%"
    echo   Path: %MT5_COMMON% >> "%LOGFILE%"
    
    if exist "%MT5_COMMON%\bridge.txt" (
        echo   [OK] bridge.txt found >> "%LOGFILE%"
    ) else (
        echo   [INFO] bridge.txt not found >> "%LOGFILE%"
        echo   Run RUN_BACKTEST.bat to generate it >> "%LOGFILE%"
    )
    
    if exist "%MT5_COMMON%\drawings.json" (
        echo   [OK] drawings.json found >> "%LOGFILE%"
    ) else (
        echo   [INFO] drawings.json not found >> "%LOGFILE%"
    )
) else (
    echo   [WARNING] Common Files folder not found >> "%LOGFILE%"
    echo   MT5 needs to be opened at least once >> "%LOGFILE%"
)
echo. >> "%LOGFILE%"

REM 5. Check EA
echo [5/7] Checking EA files...
echo [5/7] Checking EA files... >> "%LOGFILE%"
set "EA_FOUND=0"

for /d %%d in ("%APPDATA%\MetaQuotes\Terminal\*") do (
    if exist "%%d\MQL5\Experts\EA_SignalBridge.ex5" (
        echo   [OK] EA found! >> "%LOGFILE%"
        echo   Path: %%d\MQL5\Experts\EA_SignalBridge.ex5 >> "%LOGFILE%"
        set "EA_FOUND=1"
        goto :ea_found
    )
)

echo   [ERROR] EA NOT FOUND! >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   ======================================== >> "%LOGFILE%"
echo   CRITICAL: EA_SignalBridge.ex5 is MISSING! >> "%LOGFILE%"
echo   ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   Without EA, trades will NOT execute! >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   How to fix: >> "%LOGFILE%"
echo   1. Open MT5 >> "%LOGFILE%"
echo   2. File -^> Open Data Folder >> "%LOGFILE%"
echo   3. Go to: MQL5\Experts\ >> "%LOGFILE%"
echo   4. Copy EA_SignalBridge.ex5 there >> "%LOGFILE%"
echo   5. Restart MT5 >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo   Read file: EA_MISSING_HOW_TO_FIX.md >> "%LOGFILE%"
echo   ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"
set /a ERRORS+=1
goto :ea_check_done

:ea_found
echo. >> "%LOGFILE%"

:ea_check_done

REM 6. Check local signal files
echo [6/7] Checking local signal files...
echo [6/7] Checking local signal files... >> "%LOGFILE%"
if exist "%~dp0signals\bridge.txt" (
    echo   [OK] signals\bridge.txt exists >> "%LOGFILE%"
    for /f %%a in ('type "%~dp0signals\bridge.txt" ^| find /c /v ""') do (
        echo   Lines: %%a >> "%LOGFILE%"
    )
) else (
    echo   [INFO] No signals generated yet >> "%LOGFILE%"
    echo   Run: python bridge\generate_signals.py >> "%LOGFILE%"
)

if exist "%~dp0signals\drawings.json" (
    echo   [OK] signals\drawings.json exists >> "%LOGFILE%"
) else (
    echo   [INFO] No drawings generated yet >> "%LOGFILE%"
)
echo. >> "%LOGFILE%"

REM 7. Summary
echo [7/7] Summary...
echo [7/7] Summary... >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"

if %ERRORS% equ 0 (
    if %EA_FOUND% equ 1 (
        echo   STATUS: READY [GREEN] >> "%LOGFILE%"
        echo   System is fully configured! >> "%LOGFILE%"
    ) else (
        echo   STATUS: INCOMPLETE [YELLOW] >> "%LOGFILE%"
        echo   System works but EA is missing >> "%LOGFILE%"
        echo   Signals generated but NOT executed >> "%LOGFILE%"
    )
) else (
    echo   STATUS: NOT READY [RED] >> "%LOGFILE%"
    echo   Found %ERRORS% error(s) >> "%LOGFILE%"
)
echo ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

REM Next steps
echo. >> "%LOGFILE%"
echo NEXT STEPS: >> "%LOGFILE%"
echo =========== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

if %EA_FOUND% equ 0 (
    echo [CRITICAL] EA IS MISSING! >> "%LOGFILE%"
    echo. >> "%LOGFILE%"
    echo Read these files for help: >> "%LOGFILE%"
    echo - EA_MISSING_HOW_TO_FIX.md >> "%LOGFILE%"
    echo - WHAT_YOU_SEE_NOW.md >> "%LOGFILE%"
    echo. >> "%LOGFILE%"
) else (
    echo [OK] Run: RUN_BACKTEST.bat >> "%LOGFILE%"
    echo. >> "%LOGFILE%"
)

REM Done - now OPEN the log file automatically
echo.
echo [7/7] Done!
echo.
echo Opening results in Notepad...

REM Open in notepad - will stay open even if CMD closes
start notepad "%LOGFILE%"

REM Also show summary in CMD
echo.
echo ========================================
echo   CHECK COMPLETE
echo ========================================
echo.
echo Results saved to: %LOGFILE%
echo.
echo The results are now open in Notepad.
echo You can read them there.
echo.
echo ========================================
echo.
echo This window will close in 10 seconds...
echo (or press any key to close now)
timeout /t 10
