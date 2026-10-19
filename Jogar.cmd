@echo off
chcp 65001 >nul
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_game.ps1"
if errorlevel 1 (
  echo.
  pause
  exit /b 1
)
