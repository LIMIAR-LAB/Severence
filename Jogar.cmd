@echo off
chcp 65001 >nul
setlocal
set "GODOT_EXE=C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot nao encontrado. Abra project.godot no Godot 4.7.2 e pressione F6 ou F5.
  pause
  exit /b 1
)
set "GODOT_CONSOLE=C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
rem Importa arte nova (ex.: refugio) antes de abrir o jogo; rapido quando nada mudou.
if exist "%GODOT_CONSOLE%" "%GODOT_CONSOLE%" --headless --path "%~dp0." --import --quit >nul 2>&1
start "Severence — Ecos do Tempo" "%GODOT_EXE%" --path "%~dp0."
