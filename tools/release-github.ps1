param([Parameter(Mandatory)][string]$Version,[string]$NotesFile,[string]$Commit=$env:GITHUB_SHA)
$ErrorActionPreference='Stop'
if($env:GITHUB_REPOSITORY -ne 'Nxxhy/PokeTactics') { throw 'Release publishing is restricted to Nxxhy/PokeTactics' }
$headers=@{Authorization="Bearer $env:GH_TOKEN";Accept='application/vnd.github+json';'X-GitHub-Api-Version'='2026-03-10';'User-Agent'='PokeTactics-Release'}
$api='https://api.github.com/repos/Nxxhy/PokeTactics'
$tag="v$Version"
$existing=$null
for($page=1;;$page++) {
 $rows=@(Invoke-RestMethod "$api/releases?per_page=100&page=$page" -Headers $headers)
 foreach($row in $rows) {
  if($row.tag_name -eq $tag) {$existing=$row}
  if($row.tag_name -match '^v(\d+)\.(\d+)\.(\d+)$' -and !$row.prerelease -and [version]$row.tag_name.Substring(1) -gt [version]$Version) {throw 'A higher stable version already exists'}
 }
 if($rows.Count -lt 100) {break}
}
$notes=if($NotesFile -and (Test-Path -LiteralPath $NotesFile)){Get-Content -LiteralPath $NotesFile -Raw}else{"Poké Tactics $tag"}
if(!$existing) {
 $existing=Invoke-RestMethod "$api/releases" -Method Post -Headers $headers -ContentType 'application/json' -Body (@{tag_name=$tag;target_commitish=$Commit;name=$tag;body=$notes;draft=$true;prerelease=$false} | ConvertTo-Json)
} elseif(!$existing.draft -and $existing.assets.Count -gt 0) { throw 'Published release already contains assets; never replace released binaries' }
$names=@("PokeTactics-$Version-win-x64.zip",'SHA256SUMS.txt','update-win-x64.sig','update-win-x64.json')
$setup="PokeTactics-Setup-$Version.exe"
$names=@($setup)+$names
Copy-Item -LiteralPath "dist/$setup" -Destination "dist/Release/$setup" -Force
# The signed JSON is the final readiness marker. A partially uploaded release is never installable.
foreach($name in $names) {
 if($existing.assets | Where-Object name -EQ $name) { throw "Asset already exists: $name. Remove an incomplete draft explicitly before retrying." }
 $url="https://uploads.github.com/repos/Nxxhy/PokeTactics/releases/$($existing.id)/assets?name=$([Uri]::EscapeDataString($name))"
 Invoke-RestMethod $url -Method Post -Headers $headers -ContentType 'application/octet-stream' -InFile "dist/Release/$name" | Out-Null
}
$verified=Invoke-RestMethod "$api/releases/$($existing.id)" -Headers $headers
foreach($name in $names) {
 $asset=@($verified.assets | Where-Object { $_.name -eq $name -and $_.state -eq 'uploaded' })
 if($asset.Count -ne 1 -or $asset[0].size -ne (Get-Item "dist/Release/$name").Length) { throw "Release incomplete: $name" }
}
"Release ready: $($verified.html_url) (draft=$($verified.draft))" | Tee-Object -FilePath $env:GITHUB_STEP_SUMMARY -Append
