@echo off
setlocal
if exist "%LOCALAPPDATA%\Programs\PokeTactics\PokeTacticsStart.exe" (
  start "" "%LOCALAPPDATA%\Programs\PokeTactics\PokeTacticsStart.exe"
  exit /b 0
)
echo Bitte das aktuelle Setup installieren und ueber die Spiel-Verknuepfung starten.
start "" "https://github.com/Nxxhy/PokeTactics/releases/latest"
pause
