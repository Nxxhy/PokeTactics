param([string]$Godot=(Join-Path $PSScriptRoot '..\..\Godot\Godot_v4.7.2-stable_win64_console.exe'),[string]$Python='python')
$ErrorActionPreference='Stop'
& $Godot --headless --path . --log-file docs/league-tests.log --script res://tests/test_league.gd
if($LASTEXITCODE -ne 0){throw 'Authoritative league tests failed'}
& dotnet build platform/Server/Server.csproj -c Release -p:UseSharedCompilation=false -p:NuGetAudit=false --nologo
if($LASTEXITCODE -ne 0){throw 'Server build failed'}
$env:POKE_GODOT_PATH=[IO.Path]::GetFullPath($Godot)
& $Python platform/tests/test_multiplayer.py
if($LASTEXITCODE -ne 0){throw 'Multiplayer HTTP integration failed'}
& $Python platform/tests/test_multiplayer_clients.py
if($LASTEXITCODE -ne 0){throw 'Separate Godot clients failed'}
