$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Set-Location $projectRoot
$registry='HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{F87E10C2-1963-4D85-80E1-96046DDA9293}_is1'
if(Test-Path -LiteralPath $registry) {throw 'Existing user installation detected; isolated migration test skipped to preserve its registration.'}
$target=Join-Path $projectRoot 'dist/GitHubInstallerTest'
if(Test-Path -LiteralPath $target) {throw 'Test installation already exists; inspect it before retrying.'}
function Install-TestVersion($Version) {
 $installer=Join-Path $projectRoot "dist/PokeTactics-Setup-$Version.exe"
 $args=@('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/DIR="'+$target+'"'),('/LOG="'+$projectRoot+'\docs\github-install-'+$Version+'.log"'))
 $process=Start-Process -FilePath $installer -ArgumentList $args -WindowStyle Hidden -Wait -PassThru
 if($process.ExitCode -ne 0) {throw "Setup $Version failed: $($process.ExitCode)"}
}
try {
 Install-TestVersion '9.0.0'
 if((Get-Content -LiteralPath "$target/active.txt" -Raw).Trim() -ne '9.0.0') {throw 'Old installer version invalid'}
 'Trainer=MigrationTest' | Set-Content -LiteralPath "$target/settings-sentinel.cfg"
 Install-TestVersion '9.1.0'
 if((Get-Content -LiteralPath "$target/active.txt" -Raw).Trim() -ne '9.1.0') {throw 'New launcher not activated'}
 if((Get-Content -LiteralPath "$target/previous.txt" -Raw).Trim() -ne '9.0.0') {throw 'Previous version pointer lost'}
 $updates=Get-Content -LiteralPath "$target/updates.json" -Raw | ConvertFrom-Json
 if($updates.repository -ne 'Nxxhy/PokeTactics' -or !$updates.publicKey) {throw 'Update source/key missing'}
 if((Get-Content -LiteralPath "$target/settings-sentinel.cfg").Trim() -ne 'Trainer=MigrationTest') {throw 'Settings changed'}
 $log=Join-Path $projectRoot 'docs/github-installed-game.log'
 $game=Start-Process -FilePath "$target/versions/9.1.0/PokeTactics.exe" -ArgumentList @('--headless','--quit-after','5','--log-file',('"'+$log+'"')) -WorkingDirectory "$target/versions/9.1.0" -WindowStyle Hidden -Wait -PassThru
 if($game.ExitCode -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR')) {throw 'Installed game failed'}
 'PASS Actual 9.0.0 setup -> 9.1.0 setup migration; new active launcher, pinned GitHub config, previous version, settings sentinel, game startup.' | Set-Content docs/github-installer-tests.txt
} finally {
 if(Test-Path -LiteralPath "$target/unins000.exe") {
  $uninstall=Start-Process -FilePath "$target/unins000.exe" -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART') -WindowStyle Hidden -Wait -PassThru
  if($uninstall.ExitCode -ne 0) {throw 'Test uninstaller failed'}
 }
}
