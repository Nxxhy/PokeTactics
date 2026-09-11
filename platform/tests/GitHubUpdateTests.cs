using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Security.Cryptography;
using System.IO.Compression;
using System.Reflection;
using System.Diagnostics;

class GitHubUpdateTests {
 static int count;
 static readonly string Root=Path.GetFullPath(Path.Combine(AppContext.BaseDirectory,"../../../../.."));
 static readonly string Work=Path.Combine(Root,"platform/tests/.runtime/github-"+Guid.NewGuid());
 static readonly List<string> Results=new();
 static void Check(bool ok,string name) { if(!ok) throw new Exception("FAIL "+name);count++; Results.Add("PASS "+name);Console.WriteLine(Results[^1]); }
 static async Task Reject(Func<Task> action,string name) { try {await action();}catch {Check(true,name);return;}Check(false,name); }
 static T Field<T>(object o,string name)=>(T)o.GetType().GetField(name,BindingFlags.NonPublic|BindingFlags.Instance)!.GetValue(o)!;
 static Task Update(Launcher l)=>(Task)typeof(Launcher).GetMethod("Check",BindingFlags.NonPublic|BindingFlags.Instance)!.Invoke(l,new object[]{true})!;
 [STAThread] static void Main() {
  Directory.CreateDirectory(Work); ApplicationConfiguration.Initialize();
  using var form=new Form {ShowInTaskbar=false,WindowState=FormWindowState.Minimized};
  form.Shown+=async(_,_)=>{try {await Run();Results.Add($"{count} passed, 0 failed. Local simulated GitHub API; actual launcher installation and game process. Public GitHub release test is separate.");}catch(Exception e){Results.Add(e.ToString());Environment.ExitCode=1;}finally{File.WriteAllLines(Path.Combine(Root,"docs/github-update-tests.txt"),Results);form.Close();}};
  Application.Run(form);
 }
 static async Task Run() {
  using var rsa=RSA.Create(3072);
  var cfg=new UpdateConfig("Nxxhy/PokeTactics",rsa.ExportSubjectPublicKeyInfoPem());
  string Cache()=>Path.Combine(Work,Guid.NewGuid()+".json");
  Check(StableVersion.Parse("9.10.0")>StableVersion.Parse("9.9.9"),"Numeric semantic version ordering");
  foreach(var v in new[]{"09.1.0","9.1","9.1.0-beta","9.1.0+meta","../9.1.0","65536.1.0"}) await Reject(()=>{StableVersion.Parse(v);return Task.CompletedTask;},"Reject invalid stable Windows version "+v);
  await Reject(()=>{GitHubUpdates.ValidateRepository("smogon/pokemon-showdown-client");return Task.CompletedTask;},"Animation repository cannot become game update source");
  var fx=new Fixture(rsa,"9.1.0");
  GitHubUpdates Client(Fixture f,string? cache=null,string? token=null)=>new(cfg,cache ?? Cache(),token,new HttpClient(f){Timeout=TimeSpan.FromMinutes(2)});
  using(var c=Client(fx)) {var offer=await c.Latest("9.0.0");Check(offer?.Manifest.Version=="9.1.0","Complete stable release selected and signature verified");var zip=Path.Combine(Work,"verified.zip");await c.Download(offer!,zip,null);Check(Files.Hash(zip)==fx.Hash,"Signed package downloaded and hash checked");}
  Check(fx.NoLeakedAuth,"CDN redirects carry no GitHub credentials");
  var strictCache=Cache();var strict=new Fixture(rsa,"9.1.0");
  using(var c=Client(strict,strictCache)) {
   await c.Latest("9.1.0",requireOnline:true);Check(c.CurrentConfirmed,"Equal signed online version authorizes start");
   await c.Latest("9.1.0",requireOnline:true);Check(c.CurrentConfirmed&&strict.ApiCalls==2,"Every start revalidates online despite normal polling cache");
   strict.Mode="304";
   await c.Latest("9.1.0",requireOnline:true);Check(c.CurrentConfirmed&&strict.SawEtag,"Online 304 plus signed cached release authorizes current version");
   strict.Mode="offline";
   await Reject(async()=>{await c.Latest("9.1.0",requireOnline:true);},"Cached successful check cannot authorize offline start");
   Check(!c.CurrentConfirmed,"Failed online check revokes authorization");
  }
  foreach(var mode in new[]{"missing","signature","draft","prerelease"}) {
   using var c=Client(new Fixture(rsa,"9.1.0",mode));
   await Reject(async()=>{await c.Latest("9.1.0",requireOnline:true);},"Current version still requires valid stable metadata: "+mode);
   Check(!c.CurrentConfirmed,"Invalid metadata never authorizes: "+mode);
  }
  using(var c=Client(new Fixture(rsa,"9.0.0"))) await Reject(async()=>{await c.Latest("9.1.0",requireOnline:true);},"Unpublished newer installed version cannot start");
  foreach(var mode in new[]{"missing","uploading","signature","checksum","repo","version","platform","size"}) {
   var f=new Fixture(rsa,"9.1.0",mode);using var c=Client(f);await Reject(async()=>{await c.Latest("9.0.0");},"Reject release: "+mode);
  }
  foreach(var mode in new[]{"draft","prerelease"}) {var f=new Fixture(rsa,"9.1.0",mode);using var c=Client(f);Check(await c.Latest("9.0.0")==null,"Ignore "+mode);Check(f.AssetCalls==0,"No downloads for "+mode);}
  using(var c=Client(new Fixture(rsa,"9.0.0"))) Check(await c.Latest("9.1.0")==null,"Never downgrade");
  foreach(var mode in new[]{"truncated","corrupt","evilredirect"}) {var f=new Fixture(rsa,"9.1.0",mode);using var c=Client(f);var o=await c.Latest("9.0.0");await Reject(()=>c.Download(o!,Path.Combine(Work,mode+".zip"),null),"Reject package: "+mode);}
  var auth=new Fixture(rsa,"9.1.0"); using(var c=Client(auth,token:"individual-reader")) {var o=await c.Latest("9.0.0");await c.Download(o!,Path.Combine(Work,"private.zip"),null);} Check(auth.SawAuth&&auth.NoLeakedAuth,"Individual private reader token restricted to GitHub API");
  var cache=Cache();var cached=new Fixture(rsa,"9.0.0");
  using(var c=Client(cached,cache)) {await c.Latest("9.0.0");await c.Latest("9.0.0");Check(cached.ApiCalls==1,"Persistent 15-minute polling limit");}
  var saved=Files.Read<CheckCache>(cache);Files.Atomic(cache,JsonSerializer.Serialize(saved with{NextCheck=DateTimeOffset.MinValue}));cached.Mode="304";
  using(var c=Client(cached,cache)) Check(await c.Latest("9.0.0")==null&&cached.SawEtag,"Conditional ETag / 304 response");
  var rate=new Fixture(rsa,"9.1.0","rate");cache=Cache();using(var c=Client(rate,cache)) await Reject(async()=>{await c.Latest("9.0.0");},"GitHub rate limit handled");
  using(var c=Client(rate,cache)) {await c.Latest("9.0.0");Check(rate.ApiCalls==1,"Rate-limit backoff survives new client");}
  using(var c=Client(rate,cache)) {await Reject(async()=>{await c.Latest("9.0.0",requireOnline:true);},"Strict online start respects rate-limit backoff");Check(rate.ApiCalls==1,"Strict start does not bypass GitHub rate limit");}
  var credential=Path.Combine(Work,"reader.dpapi");SecureStore.Save(credential,"individual-test-token");Check(SecureStore.Load(credential)=="individual-test-token"&&!Encoding.UTF8.GetString(File.ReadAllBytes(credential)).Contains("individual-test-token"),"Windows DPAPI credential storage");
  File.WriteAllText(Path.Combine(AppContext.BaseDirectory,"build.json"),"{\"version\":\"9.0.0\"}");
  string Home(string name) {
   var home=Path.Combine(Work,name);Directory.CreateDirectory(Path.Combine(home,"versions/9.0.0"));
   File.WriteAllText(Path.Combine(home,"active.txt"),"9.0.0");File.WriteAllText(Path.Combine(home,"updates.json"),JsonSerializer.Serialize(cfg));
   File.WriteAllText(Path.Combine(home,"settings-sentinel.cfg"),"Trainer=Preserved");
   foreach(var file in new[]{"PokeTactics.exe","PokeTactics.pck","PokeLauncher.exe"}) File.Copy(Path.Combine(Root,"dist/PlayerBuild",file),Path.Combine(home,"versions/9.0.0",file));
   return home;
  }
  var installed=Home("installed");
  var currentFixture=new Fixture(rsa,"9.0.0");
  using(var launcher=new Launcher(new[]{"--home",Home("strict-start")},true,()=>Client(currentFixture))) {
   await Update(launcher);Check(Field<Button>(launcher,"play").Enabled,"Valid online current release enables play button");
   currentFixture.Mode="offline";
   typeof(Launcher).GetMethod("StartGame",BindingFlags.NonPublic|BindingFlags.Instance)!.Invoke(launcher,null);
   for(var i=0;i<100&&Field<bool>(launcher,"busy");i++) await Task.Delay(10);
   Check(!Field<Button>(launcher,"play").Enabled&&!Field<bool>(launcher,"currentConfirmed")&&Field<Process?>(launcher,"game")==null,"Play click rechecks connection and never launches after going offline");
   currentFixture.Mode="";
   await Update(launcher);Check(Field<Button>(launcher,"play").Enabled,"Successful retry unlocks current version again");
  }
  using(var launcher=new Launcher(new[]{"--home",installed},true,()=>Client(new Fixture(rsa,"9.1.0",real:true)))) {
   await Update(launcher);Check(File.ReadAllText(Path.Combine(installed,"active.txt"))=="9.1.0","Actual launcher activates 9.0.0 -> 9.1.0");
   Check(File.Exists(Path.Combine(installed,"versions/9.0.0/PokeTactics.exe")),"Previous game preserved");
   Check(File.ReadAllText(Path.Combine(installed,"settings-sentinel.cfg"))=="Trainer=Preserved","Settings outside version directories preserved");
   var psi=new ProcessStartInfo(Path.Combine(installed,"versions/9.1.0/PokeTactics.exe")){UseShellExecute=false,CreateNoWindow=true,WorkingDirectory=Path.Combine(installed,"versions/9.1.0"),ArgumentList={"--headless","--path",Path.Combine(installed,"versions/9.1.0"),"--quit-after","5","--log-file",Path.Combine(Work,"game.log")}};
   Ticket(psi,"9.1.0");
   using var game=Process.Start(psi)!;await game.WaitForExitAsync();Check(game.ExitCode==0&&!File.ReadAllText(Path.Combine(Work,"game.log")).Contains("SCRIPT ERROR"),"Updated actual game starts successfully");
  }
  File.WriteAllText(Path.Combine(AppContext.BaseDirectory,"build.json"),"{\"version\":\"9.1.0\"}");
  using(var launcher=new Launcher(new[]{"--home",installed},true,()=>Client(new Fixture(rsa,"9.1.1",real:true)))) {await Update(launcher);Check(File.ReadAllText(Path.Combine(installed,"active.txt"))=="9.1.1","Second consecutive launcher update 9.1.0 -> 9.1.1");}
  File.WriteAllText(Path.Combine(AppContext.BaseDirectory,"build.json"),"{\"version\":\"9.0.0\"}");
  foreach(var mode in new[]{"offline","missing","truncated","corrupt","zipslip"}) {
   var home=Home(mode);using var launcher=new Launcher(new[]{"--home",home},true,()=>Client(new Fixture(rsa,"9.1.0",mode)));
   Check(!Field<Button>(launcher,"play").Enabled,"Start is locked before first check: "+mode);
   await Update(launcher);Check(File.ReadAllText(Path.Combine(home,"active.txt"))=="9.0.0"&&!Field<Button>(launcher,"play").Enabled&&!Field<bool>(launcher,"currentConfirmed"),"Old files preserved but start locked after "+mode);
  }
  var locked=Home("locked");
  using(var launcher=new Launcher(new[]{"--home",locked},true,()=>Client(new Fixture(rsa,"9.1.0",real:true)))) {
   using(var handle=new FileStream(Path.Combine(locked,"active.txt"),FileMode.Open,FileAccess.Read,FileShare.Read)) await Update(launcher);
   Check(File.ReadAllText(Path.Combine(locked,"active.txt"))=="9.0.0","Activation failure preserves old pointer");
   await Update(launcher);Check(File.ReadAllText(Path.Combine(locked,"active.txt"))=="9.1.0","Retry recovers an interrupted installation");
  }
  var running=Home("running");
  var start=new ProcessStartInfo(Path.Combine(running,"versions/9.0.0/PokeTactics.exe")){UseShellExecute=false,CreateNoWindow=true,WorkingDirectory=Path.Combine(running,"versions/9.0.0"),ArgumentList={"--headless","--path",Path.Combine(running,"versions/9.0.0"),"--log-file",Path.Combine(Work,"running-game.log")}};
  File.WriteAllText(Path.Combine(running,"versions/9.0.0/build.json"),"{\"version\":\"9.0.0\"}");
  Ticket(start,"9.0.0");
  using(var game=Process.Start(start)!) {
   try {using var launcher=new Launcher(new[]{"--home",running},true,()=>Client(new Fixture(rsa,"9.1.0",real:true)));
    typeof(Launcher).GetField("game",BindingFlags.NonPublic|BindingFlags.Instance)!.SetValue(launcher,game);
    var update=Update(launcher);
    for(var i=0;i<200 && !Field<Label>(launcher,"status").Text.StartsWith("Update vorbereitet");i++) await Task.Delay(100);
    Check(!game.HasExited&&!update.IsCompleted&&File.ReadAllText(Path.Combine(running,"active.txt"))=="9.0.0","Running actual game is not interrupted; update staged");
    game.Kill();await game.WaitForExitAsync();await update;
    Check(File.ReadAllText(Path.Combine(running,"active.txt"))=="9.1.0","Staged update activates only after game exits");
   }finally{if(!game.HasExited)game.Kill();}
  }
 }
 static void Ticket(ProcessStartInfo start,string version) {
  var path=Path.Combine(Work,Guid.NewGuid()+".json");
  File.WriteAllText(path,JsonSerializer.Serialize(new {version,expires=DateTimeOffset.UtcNow.ToUnixTimeSeconds()+30}));
  start.Environment["POKE_LAUNCH_TICKET"]=path;
 }
 sealed class Fixture : HttpMessageHandler {
  public string Mode;public int ApiCalls,AssetCalls; public bool NoLeakedAuth=true,SawAuth,SawEtag;
  public string Hash;
  readonly Dictionary<long,byte[]> data=new();readonly GitRelease release;
  public Fixture(RSA rsa,string version,string mode="",bool real=false) {
   Mode=mode;using var mem=new MemoryStream();
   using(var zip=new ZipArchive(mem,ZipArchiveMode.Create,true)) {
    foreach(var name in new[]{"PokeTactics.exe","PokeTactics.pck","PokeLauncher.exe"}) {
     if(real) zip.CreateEntryFromFile(Path.Combine(Root,"dist/PlayerBuild",name),name,CompressionLevel.Fastest);
     else {using var s=zip.CreateEntry(name).Open();s.Write(new byte[]{1,2,3});}
    }
    using(var s=new StreamWriter(zip.CreateEntry("build.json").Open()))s.Write(JsonSerializer.Serialize(new{version}));
    if(mode=="zipslip") {using var s=new StreamWriter(zip.CreateEntry("../escape.txt").Open());s.Write("escape");}
   }
   data[4]=mem.ToArray();Hash=Convert.ToHexString(SHA256.HashData(data[4]));
   var m=new UpdateManifest(mode=="repo"?"other/repo":"Nxxhy/PokeTactics",mode=="version"?"9.9.9":version,"v"+version,mode=="platform"?"linux":"win-x64",$"PokeTactics-{version}-win-x64.zip",data[4].Length+(mode=="size"?1:0),Hash);
   data[1]=JsonSerializer.SerializeToUtf8Bytes(m);var sig=rsa.SignData(data[1],HashAlgorithmName.SHA256,RSASignaturePadding.Pss);if(mode=="signature")sig[0]^=1;
   data[2]=Encoding.UTF8.GetBytes(Convert.ToBase64String(sig));data[3]=Encoding.UTF8.GetBytes((mode=="checksum"?new string('0',64):Hash)+"  "+m.Package+"\n");
   var names=new[]{"update-win-x64.json","update-win-x64.sig","SHA256SUMS.txt",m.Package};
   release=new(1,"v"+version,mode=="draft",mode=="prerelease","Test release notes",names.Select((n,i)=>new ReleaseAsset(i+1,n,data[i+1].Length,mode=="uploading"&&i==3?"new":"uploaded")).Where(a=>mode!="missing"||a.Id!=2).ToArray());
  }
  protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage q,CancellationToken ct) {
   if(Mode=="offline") throw new HttpRequestException("Offline fixture");
   var uri=q.RequestUri!;SawAuth|=q.Headers.Authorization!=null;
   if(uri.Host!="api.github.com"&&q.Headers.Authorization!=null)NoLeakedAuth=false;
   HttpResponseMessage Reply(byte[] bytes)=>new(HttpStatusCode.OK){Content=new ByteArrayContent(bytes)};
   if(uri.AbsolutePath.EndsWith("/latest")) {
    ApiCalls++;SawEtag|=q.Headers.IfNoneMatch.Any();
    if(Mode=="rate") {var r=new HttpResponseMessage(HttpStatusCode.TooManyRequests);r.Headers.RetryAfter=new(TimeSpan.FromMinutes(20));return Task.FromResult(r);}
    if(Mode=="304")return Task.FromResult(new HttpResponseMessage(HttpStatusCode.NotModified));
    var response=Reply(JsonSerializer.SerializeToUtf8Bytes(release));response.Headers.ETag=new("\"test-v1\"");return Task.FromResult(response);
   }
   var id=long.Parse(uri.Segments[^1]);
   if(uri.Host=="api.github.com") {AssetCalls++;var r=new HttpResponseMessage(HttpStatusCode.Found);r.Headers.Location=new Uri($"https://{(Mode=="evilredirect"&&id==4?"evil.example":"release-assets.githubusercontent.com")}/{id}");return Task.FromResult(r);}
   var bytes=data[id].ToArray();
   if(id==4&&Mode=="corrupt")bytes[0]^=1;
   if(id==4&&Mode=="truncated")bytes=bytes[..^1];
   var result=Reply(bytes);result.Content.Headers.ContentLength=data[id].Length;return Task.FromResult(result);
  }
  protected override void Dispose(bool disposing) { } // Reusable fixture across conditional requests; no real sockets.
 }
}
