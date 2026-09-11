param([string]$Version='9.1.0', [string]$Godot=(Join-Path $PSScriptRoot '..\..\Godot\Godot_v4.7.2-stable_win64_console.exe'), [string]$Inno=(Join-Path $PSScriptRoot '..\platform\inno\ISCC.exe'))
$ErrorActionPreference='Stop'
$projectPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location $projectPath
try {
    if ($Version -notmatch '^(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})$' -or ($Version.Split('.') | Where-Object { [int]$_ -gt 65535 })) { throw 'Invalid stable version' }
    & ./tools/build.ps1 -Godot $Godot
    if ($LASTEXITCODE -ne 0) { throw 'Game build failed' }
    foreach ($item in @(@('Desktop/Launcher','Launcher'),@('Desktop/Publisher','Developer'),@('Bootstrap/Bootstrap','Bootstrap'))) {
        & dotnet publish "platform/$($item[0]).csproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:NuGetAudit=false -p:UseSharedCompilation=false -p:Version=$Version -o "dist/$($item[1])" --nologo
        if ($LASTEXITCODE -ne 0) { throw "Publish failed: $($item[0])" }
    }
    New-Item -ItemType Directory -Force dist/PlayerBuild | Out-Null
    Copy-Item -Path dist/PokeTactics/* -Destination dist/PlayerBuild -Recurse -Force
    Copy-Item -LiteralPath dist/Launcher/PokeLauncher.exe -Destination dist/PlayerBuild/PokeLauncher.exe -Force
    Set-Content -LiteralPath dist/PlayerBuild/build.json -Value ('{"version":"'+$Version+'"}') -Encoding utf8
    Copy-Item -LiteralPath tools/Animationsvorschau.cmd -Destination dist/PlayerBuild -Force
    foreach ($doc in @('V9-ANLEITUNG.md','V9-ANIMATIONEN.md','ANIMATIONS-ZUORDNUNG.md','SHOWDOWN-NOTICES.txt')) {
        Copy-Item -LiteralPath "docs/$doc" -Destination dist/PlayerBuild/docs -Force
    }
    foreach ($license in @('LICENSE.txt','ThirdPartyNotices.txt')) {
        Copy-Item -LiteralPath (Join-Path $env:ProgramFiles ('dotnet\'+$license)) -Destination ('dist/PlayerBuild/DOTNET-'+$license) -Force
        Copy-Item -LiteralPath (Join-Path $env:ProgramFiles ('dotnet\'+$license)) -Destination ('dist/Developer/DOTNET-'+$license) -Force
    }
    Copy-Item -LiteralPath docs/V9-ANLEITUNG.md -Destination dist/Developer/LIES-MICH.md -Force
    Copy-Item -LiteralPath assets/fonts/POWER-GREEN-SOURCE.txt -Destination dist/Developer -Force
    Copy-Item -LiteralPath platform/updates.json -Destination dist/Developer -Force
    Copy-Item -LiteralPath docs/GITHUB-RELEASES.md -Destination dist/Developer/LIES-MICH.md -Force
    Copy-Item -LiteralPath docs/GITHUB-RELEASES.md -Destination dist/PlayerBuild/docs -Force
    Copy-Item -LiteralPath platform/hosting/Dockerfile -Destination dist/Developer/Dockerfile -Force
    Set-Content -LiteralPath platform/active.txt -Value $Version -NoNewline -Encoding ascii
    & $Inno "/DAppVersion=$Version" platform/setup.iss
    if ($LASTEXITCODE -ne 0) { throw 'Setup compilation failed' }
    Get-FileHash "dist/PokeTactics-Setup-$Version.exe" -Algorithm SHA256
} finally { Pop-Location }
