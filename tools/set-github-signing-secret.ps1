$ErrorActionPreference='Stop'
Set-Location ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
if(!(Get-Command gh -ErrorAction SilentlyContinue)) {throw 'GitHub CLI fehlt. Offizielles gh installieren und gh auth login ausführen.'}
& gh auth status
if($LASTEXITCODE -ne 0) {throw 'GitHub CLI nicht angemeldet'}
Add-Type -AssemblyName System.Security
$protected=[IO.File]::ReadAllBytes((Join-Path (Get-Location) '.release-secrets/signing-key.dpapi'))
$bytes=[Security.Cryptography.ProtectedData]::Unprotect($protected,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
try {
 # Pipe directly to gh; private key is never printed, put on command line or written as plaintext.
 [Text.Encoding]::UTF8.GetString($bytes) | & gh secret set UPDATE_SIGNING_PRIVATE_KEY --repo Nxxhy/PokeTactics --env release
 if($LASTEXITCODE -ne 0) {throw 'GitHub secret upload failed'}
} finally {[Array]::Clear($bytes,0,$bytes.Length)}
