@echo off
REM ============================================
REM Auto-Pull من GitHub
REM يستخدم مع Task Scheduler لسحب التحديثات دورياً
REM ============================================

cd /d C:\AI-Trading-System

echo [%date% %time%] Checking for updates...

REM Fetch latest
git fetch origin main

REM Check if there are changes
git diff --quiet HEAD origin/main
if %errorlevel% equ 0 (
    echo [%date% %time%] Already up to date
) else (
    echo [%date% %time%] Updates found, pulling...
    git reset --hard origin/main
    echo [%date% %time%] Pull completed
)

REM Log to file
echo [%date% %time%] Auto-pull executed >> Logs\pull.log
