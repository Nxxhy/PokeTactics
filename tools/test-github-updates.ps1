param([string]$Godot=(Join-Path $PSScriptRoot '..\..\Godot\Godot_v4.7.2-stable_win64_console.exe'))
$ErrorActionPreference='Stop'
& dotnet run --project platform/tests/GitHubUpdateTests.csproj -c Release -p:UseSharedCompilation=false -p:NuGetAudit=false
if($LASTEXITCODE -ne 0) {throw 'GitHub update integration tests failed'}
& $Godot --headless --path . --log-file (Join-Path (Get-Location) 'docs/github-core-test.log') --script res://tests/test_core.gd
if($LASTEXITCODE -ne 0) {throw 'Core regression tests failed'}
& $Godot --headless --path . --log-file (Join-Path (Get-Location) 'docs/launch-gate-tests.log') --script res://tests/test_launch_gate.gd
if($LASTEXITCODE -ne 0) {throw 'Launcher handoff tests failed'}
