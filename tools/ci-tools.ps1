$ErrorActionPreference='Stop'
$taskTools=Join-Path $env:RUNNER_TEMP 'poketactics-tools'
New-Item -ItemType Directory -Force $taskTools | Out-Null
function Download-Verified($Url,$Path,$Hash) {
 Invoke-WebRequest -Uri $Url -OutFile $Path
 if((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Hash) {throw 'Build tool checksum mismatch'}
}
Download-Verified 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip' "$taskTools/godot.zip" '731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953'
Expand-Archive -LiteralPath "$taskTools/godot.zip" -DestinationPath "$taskTools/godot" -Force
Download-Verified 'https://github.com/jrsoftware/issrc/releases/download/is-7_1_0/innosetup-7.1.0-x64.exe' "$taskTools/inno.exe" '0362A383ED217D4C4239B5933866DD96D3EB2102737DA92F80F6057A4B40DF2F'
$setup=Start-Process -FilePath "$taskTools/inno.exe" -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/CURRENTUSER',('/DIR="'+$taskTools+'\inno"')) -WindowStyle Hidden -Wait -PassThru
if($setup.ExitCode -ne 0) {throw 'Inno Setup installation failed'}
"GODOT_EXE=$taskTools\godot\Godot_v4.7.2-stable_win64_console.exe" >> $env:GITHUB_ENV
"INNO_EXE=$taskTools\inno\ISCC.exe" >> $env:GITHUB_ENV
