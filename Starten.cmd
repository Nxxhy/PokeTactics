@echo off
setlocal
if exist "%~dp0dist\PokeTactics\PokeTactics.exe" (
  start "" "%~dp0dist\PokeTactics\PokeTactics.exe"
  exit /b 0
)
if exist "%~dp0..\Godot\Godot_v4.7.2-stable_win64.exe" (
  start "" "%~dp0..\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
  exit /b 0
)
echo Bitte das vollstaendige Windows-Paket entpacken oder Godot 4 installieren.
pause
