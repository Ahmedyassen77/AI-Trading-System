@echo off
title Compile EA - Quick Guide
color 0B

cls
echo.
echo ========================================
echo   EA COMPILATION - QUICK GUIDE
echo ========================================
echo.
echo You now have the full EA source code:
echo   MQL5\EA_SignalBridge.mq5
echo.
echo ========================================
echo   HOW TO COMPILE (3 STEPS)
echo ========================================
echo.
echo 1. Open MetaEditor
echo    - From MT5: Tools -^> MetaQuotes Language Editor
echo    - Or search: MetaEditor in Start Menu
echo.
echo 2. Open file:
echo    File -^> Open -^> C:\AI-Trading-System\MQL5\EA_SignalBridge.mq5
echo.
echo 3. Compile:
echo    Press F7
echo    (or click Compile button)
echo.
echo ========================================
echo   RESULT
echo ========================================
echo.
echo You should see:
echo   [OK] 0 error(s), 0 warning(s)
echo   [OK] EA_SignalBridge.ex5 compiled successfully
echo.
echo The .ex5 file will be in:
echo   MT5 Data Folder\MQL5\Experts\EA_SignalBridge.ex5
echo.
echo To find it:
echo   MT5 -^> File -^> Open Data Folder -^> MQL5\Experts\
echo.
echo ========================================
echo   AFTER COMPILATION
echo ========================================
echo.
echo 1. Restart MT5
echo 2. Run: SIMPLE_CHECK.bat (to verify EA is found)
echo 3. Run: RUN_BACKTEST.bat (to test)
echo.
echo ========================================
echo   NEED HELP?
echo ========================================
echo.
echo Read: HOW_TO_COMPILE_EA.md (full guide)
echo.
echo ========================================
echo.
echo Press any key to open HOW_TO_COMPILE_EA.md...
pause >nul

start notepad "%~dp0HOW_TO_COMPILE_EA.md"
