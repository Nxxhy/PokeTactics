$ErrorActionPreference='Stop'
Set-Location ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
Add-Type -AssemblyName System.Security
$keyFile=Join-Path (Get-Location) '.release-secrets/signing-key.dpapi'
$config=Get-Content platform/updates.json -Raw | ConvertFrom-Json
if(Test-Path -LiteralPath $keyFile) { throw 'Signing key already exists. Never rotate the pinned key accidentally.' }
if($config.publicKey) { throw 'Public key already pinned. Recover its corresponding private key instead.' }
New-Item -ItemType Directory -Force .release-secrets | Out-Null
$rsa=[Security.Cryptography.RSA]::Create(3072)
try {
 $bytes=[Text.Encoding]::UTF8.GetBytes($rsa.ExportPkcs8PrivateKeyPem())
 $protected=[Security.Cryptography.ProtectedData]::Protect($bytes,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
 [IO.File]::WriteAllBytes($keyFile,$protected)
 [Array]::Clear($bytes,0,$bytes.Length)
 $config.publicKey=$rsa.ExportSubjectPublicKeyInfoPem()
 [IO.File]::WriteAllText((Join-Path (Get-Location) 'platform/updates.json'),($config | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 'Signing key created locally (Windows DPAPI); only the public key is in updates.json.'
} finally {$rsa.Dispose()}
