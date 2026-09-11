using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Security.Cryptography;
using System.Text.RegularExpressions;

record UpdateConfig(string Repository = "", string PublicKey = "", bool PrivateRepository = false);
record UpdateManifest(string Repository, string Version, string Tag, string Platform, string Package, long Size, string Sha256);
record ReleaseAsset(long Id, string Name, long Size, string State);
record GitRelease(long Id, [property:JsonPropertyName("tag_name")] string Tag, bool Draft, bool Prerelease, string? Body, ReleaseAsset[] Assets);
record UpdateOffer(GitRelease Release, UpdateManifest Manifest, ReleaseAsset Package);
record CheckCache(string? Etag, string? Body, DateTimeOffset NextCheck, bool Backoff = false);

static class StableVersion {
 // Stable SemVer subset also representable in Windows version resources and safe directory names.
 public static Version Parse(string value) {
  if (!Regex.IsMatch(value, @"^(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})$") || !Version.TryParse(value,out var v) || v.Major>65535 || v.Minor>65535 || v.Build>65535)
   throw new Exception("Eine stabile Version muss x.y.z ohne führende Nullen sein (jeweils 0–65535).");
  return v;
 }
}

sealed class GitHubUpdates : IDisposable {
 public bool CurrentConfirmed { get; private set; }
 readonly UpdateConfig config;
 readonly HttpClient client;
 readonly string cachePath;
 readonly string? token;
 public GitHubUpdates(UpdateConfig config, string cachePath, string? token = null, HttpClient? transport = null) {
  ValidateRepository(config.Repository);
  this.config=config; this.cachePath=cachePath; this.token=token;
  client=transport ?? Files.Client();
 }
 public static void ValidateRepository(string repository) {
  if(!Regex.IsMatch(repository,@"^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$") || repository.Contains("..") || repository.Equals("smogon/pokemon-showdown-client",StringComparison.OrdinalIgnoreCase))
   throw new Exception("Das tatsächliche Spiel-Repository muss als Eigentümer/Repository konfiguriert sein.");
 }
 public static HttpRequestMessage Request(HttpMethod method, Uri uri, string? token=null) {
  var q=new HttpRequestMessage(method,uri);
  q.Headers.UserAgent.ParseAdd("PokeTactics-Updater/10.0");
  if(uri.Host=="api.github.com") {
   q.Headers.Add("X-GitHub-Api-Version","2026-03-10");
   q.Headers.Accept.ParseAdd("application/vnd.github+json");
   if(!string.IsNullOrWhiteSpace(token)) q.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);
  }
  return q;
 }
 public async Task<UpdateOffer?> Latest(string installed, bool force=false, bool requireOnline=false) {
  CurrentConfirmed=false;
  StableVersion.Parse(installed);
  CheckCache cache=new(null,null,DateTimeOffset.MinValue);
  try { if(File.Exists(cachePath)) cache=Files.Read<CheckCache>(cachePath); } catch { }
  if(DateTimeOffset.UtcNow<cache.NextCheck && (!requireOnline || cache.Backoff)) {
   if(!force && !requireOnline) return null;
   throw new Exception("GitHub-Abfragepause bis "+cache.NextCheck.ToLocalTime().ToString("HH:mm:ss")+". Danach erneut versuchen.");
  }
  // Persistent pacing applies across launcher restarts and even when requests fail.
  void Save(DateTimeOffset next,string? etag=null,string? body=null,bool backoff=true) {
   Directory.CreateDirectory(Path.GetDirectoryName(cachePath)!);
   cache=new CheckCache(etag ?? cache.Etag,body ?? cache.Body,next,backoff);
   Files.Atomic(cachePath,JsonSerializer.Serialize(cache,Files.Json));
  }
  Save(DateTimeOffset.UtcNow.AddMinutes(1));
  using var q=Request(HttpMethod.Get,new Uri($"https://api.github.com/repos/{config.Repository}/releases/latest"),token);
  if(cache.Etag!=null) q.Headers.TryAddWithoutValidation("If-None-Match",cache.Etag);
  using var cts=new CancellationTokenSource(TimeSpan.FromSeconds(30));
  using var response=await client.SendAsync(q,cts.Token);
  if(response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.TooManyRequests) {
   var retry=DateTimeOffset.UtcNow.AddMinutes(15);
   if(response.Headers.TryGetValues("X-RateLimit-Reset",out var reset) && long.TryParse(reset.First(),out var unix)) retry=DateTimeOffset.FromUnixTimeSeconds(unix);
   if(response.Headers.RetryAfter?.Delta is TimeSpan delta) retry=DateTimeOffset.UtcNow+delta;
   if(response.Headers.RetryAfter?.Date is DateTimeOffset date) retry=date;
   if(retry<DateTimeOffset.UtcNow.AddMinutes(1)) retry=DateTimeOffset.UtcNow.AddMinutes(1);
   Save(retry); throw new Exception("GitHub-Zugriff gesperrt oder Abfragelimit erreicht. Erneute Prüfung ab "+retry.ToLocalTime().ToString("HH:mm")+".");
  }
  if(response.StatusCode==HttpStatusCode.NotFound) { Save(DateTimeOffset.UtcNow.AddMinutes(15)); throw new Exception("Noch kein stabiles Release vorhanden oder Repository-Zugriff fehlt."); }
  string body;
  if(response.StatusCode==HttpStatusCode.NotModified) body=cache.Body ?? throw new Exception("GitHub-Cache fehlt.");
  else { response.EnsureSuccessStatusCode(); body=await response.Content.ReadAsStringAsync(cts.Token); }
  Save(DateTimeOffset.UtcNow.AddMinutes(1),response.Headers.ETag?.ToString(),body);
  var release=JsonSerializer.Deserialize<GitRelease>(body,Files.Json) ?? throw new Exception("Release-Metadaten fehlen.");
  if(release.Draft || release.Prerelease) {
   if(requireOnline) throw new Exception("Keine gültige stabile Veröffentlichung bestätigt.");
   return null;
  }
  if(!release.Tag.StartsWith('v')) throw new Exception("Release-Tag muss vX.Y.Z sein.");
  var version=release.Tag[1..];
  if(StableVersion.Parse(version)<=StableVersion.Parse(installed)) {
   if(requireOnline) {
    if(version!=installed) throw new Exception("Installierte Version entspricht nicht der aktuellen stabilen Veröffentlichung.");
    await Validate(release);
    CurrentConfirmed=true;
   }
   Save(DateTimeOffset.UtcNow.AddMinutes(15),backoff:false); return null;
  }
  var offer=await Validate(release);
  Save(DateTimeOffset.UtcNow.AddMinutes(1),backoff:false);
  // Failed installation can be retried after the one-minute minimum instead of waiting 15 minutes.
  return offer;
 }
 public async Task<UpdateOffer> Validate(GitRelease release) {
  var version=release.Tag.StartsWith('v')?release.Tag[1..]:""; StableVersion.Parse(version);
  if(release.Prerelease) throw new Exception("Vorabversion gehört nicht zum stabilen Kanal.");
  ReleaseAsset Asset(string name,long max) {
   var matches=release.Assets.Where(a=>a.Name==name && a.State=="uploaded").ToArray();
   if(matches.Length!=1 || matches[0].Size<=0 || matches[0].Size>max) throw new Exception("Release ist unvollständig: "+name+" fehlt oder ist ungültig.");
   return matches[0];
  }
  var metadata=Asset("update-win-x64.json",16384);
  var signature=Asset("update-win-x64.sig",2048);
  var sums=Asset("SHA256SUMS.txt",4096);
  var payload=await Bytes(metadata,16384);
  var sig=Convert.FromBase64String(System.Text.Encoding.UTF8.GetString(await Bytes(signature,2048)).Trim());
  using var rsa=RSA.Create(); rsa.ImportFromPem(config.PublicKey);
  if(rsa.KeySize<3072 || !rsa.VerifyData(payload,sig,HashAlgorithmName.SHA256,RSASignaturePadding.Pss)) throw new Exception("Update-Signatur ungültig.");
  var manifest=JsonSerializer.Deserialize<UpdateManifest>(payload,Files.Json) ?? throw new Exception("Update-Metadaten ungültig.");
  if(manifest.Repository!=config.Repository || manifest.Version!=version || manifest.Tag!=release.Tag || manifest.Platform!="win-x64" || manifest.Package!=$"PokeTactics-{version}-win-x64.zip" || !Regex.IsMatch(manifest.Sha256,@"^[a-fA-F0-9]{64}$")) throw new Exception("Signierte Metadaten passen nicht zu Repository, Tag oder Windows-Paket.");
  var package=Asset(manifest.Package,629145600);
  if(package.Size!=manifest.Size) throw new Exception("Paketgröße passt nicht zu signierten Metadaten.");
  var checksumText=System.Text.Encoding.UTF8.GetString(await Bytes(sums,4096));
  if(!checksumText.Split('\n').Any(l=>l.TrimEnd('\r').Equals(manifest.Sha256+"  "+manifest.Package,StringComparison.OrdinalIgnoreCase))) throw new Exception("Prüfsummen-Datei passt nicht zum signierten Paket.");
  return new(release,manifest,package);
 }
 async Task<byte[]> Bytes(ReleaseAsset asset,int max) {
  using var buffer=new MemoryStream(); await Transfer(asset,buffer,max,null); return buffer.ToArray();
 }
 public async Task Download(UpdateOffer offer,string path,Action<int>? progress) {
  await using(var file=File.Create(path)) await Transfer(offer.Package,file,offer.Manifest.Size,progress);
  if(!(await Task.Run(()=>Files.Hash(path))).Equals(offer.Manifest.Sha256,StringComparison.OrdinalIgnoreCase)) throw new Exception("Paket-Prüfsumme stimmt nicht überein.");
 }
 async Task Transfer(ReleaseAsset asset,Stream output,long max,Action<int>? progress) {
  var uri=new Uri($"https://api.github.com/repos/{config.Repository}/releases/assets/{asset.Id}");
  using var overall=new CancellationTokenSource(TimeSpan.FromMinutes(15));
  for(var hop=0;hop<5;hop++) {
   using var q=Request(HttpMethod.Get,uri,token); q.Headers.Accept.Clear(); q.Headers.Accept.ParseAdd("application/octet-stream");
   using var response=await client.SendAsync(q,HttpCompletionOption.ResponseHeadersRead,overall.Token);
   if((int)response.StatusCode is 301 or 302 or 303 or 307 or 308) {
    var next=new Uri(uri,response.Headers.Location ?? throw new Exception("Download-Weiterleitung fehlt."));
    if(next.Scheme!="https" || !(next.Host=="github.com" || next.Host=="release-assets.githubusercontent.com" || next.Host=="objects.githubusercontent.com")) throw new Exception("Nicht erlaubtes Download-Ziel.");
    uri=next; continue; // Authorization is only ever attached to api.github.com.
   }
   response.EnsureSuccessStatusCode();
   if(response.Content.Headers.ContentLength is long length && length!=asset.Size) throw new Exception("Download-Größe unerwartet.");
   await using var input=await response.Content.ReadAsStreamAsync(overall.Token);
   var bytes=new byte[131072]; long total=0;
   while(true) {
    using var idle=CancellationTokenSource.CreateLinkedTokenSource(overall.Token); idle.CancelAfter(TimeSpan.FromSeconds(30));
    int n=await input.ReadAsync(bytes,idle.Token); if(n==0) break;
    total+=n; if(total>max || total>asset.Size) throw new Exception("Download überschreitet signierte Größe.");
    await output.WriteAsync(bytes.AsMemory(0,n),overall.Token); progress?.Invoke((int)(100*total/asset.Size));
   }
   if(total!=asset.Size) throw new Exception("Download unterbrochen oder unvollständig. Bitte erneut versuchen.");
   return;
  }
  throw new Exception("Zu viele Download-Weiterleitungen.");
 }
 public void Dispose()=>client.Dispose();
}
