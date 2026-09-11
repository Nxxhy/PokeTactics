param([string]$Godot = (Join-Path $PSScriptRoot '..\..\Godot\Godot_v4.7.2-stable_win64_console.exe'))
$ErrorActionPreference = 'Stop'
$project = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$binary = $Godot -replace '_console\.exe$', '.exe'
$release = Join-Path $project 'dist\PokeTactics'
New-Item -ItemType Directory -Force -Path $release | Out-Null
& $Godot --headless --log-file (Join-Path $project 'docs\build.log') --path $project --script res://tools/pack.gd
if ($LASTEXITCODE -ne 0) { throw 'PCK build failed' }
Copy-Item -LiteralPath $binary -Destination (Join-Path $release 'PokeTactics.exe') -Force
Copy-Item -LiteralPath (Join-Path $project 'README.md') -Destination (Join-Path $release 'LIES-MICH.md') -Force
Copy-Item -LiteralPath (Join-Path $project 'docs\GODOT-LICENSE.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'docs\GODOT-THIRD-PARTY.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\POKEAPI-LICENCE.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'docs\MEDIEN.md') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\manifest.json') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\manifest-v3.json') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\animated\manifest.json') -Destination (Join-Path $release 'ANIMATION-MANIFEST.json') -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\fonts\OFL.txt') -Destination (Join-Path $release 'PIXELIFY-OFL.txt') -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\fonts\VT323-OFL.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\fonts\ATKINSON-OFL.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\fonts\POWER-GREEN-SOURCE.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'assets\manifest-v8.json') -Destination $release -Force
$releaseDocs = Join-Path $release 'docs'
New-Item -ItemType Directory -Force -Path $releaseDocs | Out-Null
foreach ($name in @('BALANCING.md','TESTBERICHT.md','ARCHITEKTUR.md','MEDIEN.md','V3-UEBERSICHT.md','V4-DARSTELLUNG.md','V5-DESIGN.md','V6-UI.md','V7-UI.md','V8-SYSTEME.md','AUGMENTS.md','ROSTER.md')) {
    Copy-Item -LiteralPath (Join-Path $project ('docs\' + $name)) -Destination $releaseDocs -Force
}
Compress-Archive -LiteralPath $release -DestinationPath (Join-Path $project 'dist\PokeTactics-Windows.zip') -Force
Get-FileHash -LiteralPath (Join-Path $project 'dist\PokeTactics-Windows.zip') -Algorithm SHA256 | Format-List
