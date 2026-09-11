using System.Diagnostics;
using System.Reflection;
using System.Text.Json;

class LiveStrictUpdateTests {
 [STAThread] static void Main(string[] args) {
  if(args.Length!=1) throw new Exception("Pass the current public version x.y.z. Downloads and runs the signed game in an isolated test directory.");
  var version=args[0];StableVersion.Parse(version);ApplicationConfiguration.Initialize();
  using var host=new Form {ShowInTaskbar=false,WindowState=FormWindowState.Minimized};
  host.Shown+=async(_,_)=>{
   var report=new List<string>();
   void Pass(bool ok,string text) {if(!ok)throw new Exception(text);report.Add("PASS "+text);Console.WriteLine(report[^1]);}
   try {
    var home=Path.GetFullPath(Path.Combine("dist","StrictLive-"+version+"-"+Guid.NewGuid()));Directory.CreateDirectory(home);
    var config=Files.Read<UpdateConfig>("platform/updates.json");
    using var updates=new GitHubUpdates(config,Path.Combine(home,"download-cache.json"));
    var offer=await updates.Latest("0.0.0");
    Pass(offer?.Manifest.Version==version,"Actual current signed public release is "+version);
    var zip=Path.Combine(home,"package.zip");await updates.Download(offer!,zip,null);
    var directory=Path.Combine(home,"versions",version);Files.Extract(zip,directory);
    Pass(true,"Public Windows package downloaded and SHA-256 verified");
    Files.Atomic(Path.Combine(home,"active.txt"),version);
    Files.Atomic(Path.Combine(home,"updates.json"),JsonSerializer.Serialize(config,Files.Json));
    Files.Atomic(Path.Combine(AppContext.BaseDirectory,"build.json"),JsonSerializer.Serialize(new {version}));
    using(var launcher=new Launcher(new[]{"--home",home},true)) {
     await (Task)typeof(Launcher).GetMethod("Check",BindingFlags.NonPublic|BindingFlags.Instance)!.Invoke(launcher,new object[]{true})!;
     var play=(Button)typeof(Launcher).GetField("play",BindingFlags.NonPublic|BindingFlags.Instance)!.GetValue(launcher)!;
     Pass(play.Enabled,"Actual launcher confirms current public version online and enables play");
    }
    var ticket=Path.Combine(home,"launch.json");
    Files.Atomic(ticket,JsonSerializer.Serialize(new {version,expires=DateTimeOffset.UtcNow.ToUnixTimeSeconds()+30}));
    var log=Path.Combine(home,"game.log");
    var start=new ProcessStartInfo(Path.Combine(directory,"PokeTactics.exe")) {UseShellExecute=false,CreateNoWindow=true,WorkingDirectory=directory,ArgumentList={"--headless","--quit-after","5","--log-file",log}};
    start.Environment["POKE_LAUNCH_TICKET"]=ticket;
    using var game=Process.Start(start)!;
    using var timeout=new CancellationTokenSource(TimeSpan.FromSeconds(45));
    try {await game.WaitForExitAsync(timeout.Token);}finally{if(!game.HasExited)game.Kill();}
    Pass(game.ExitCode==0&&!File.Exists(ticket)&&!File.ReadAllText(log).Contains("SCRIPT ERROR"),"GitHub-built game consumes the one-use version handoff and starts successfully");
    var existing=Process.GetProcessesByName("PokeLauncher");
    var canTestRelay=existing.Length==0;foreach(var p in existing)p.Dispose();
    if(canTestRelay) {
     start.Environment.Remove("POKE_LAUNCH_TICKET");
     using var direct=Process.Start(start)!;
     using var relayTimeout=new CancellationTokenSource(TimeSpan.FromSeconds(30));
     try {
      await direct.WaitForExitAsync(relayTimeout.Token);
      Process? relay=null;
      for(var i=0;i<100&&relay==null;i++) {
       foreach(var p in Process.GetProcessesByName("PokeLauncher")) {
        if(p.MainModule?.FileName==Path.Combine(directory,"PokeLauncher.exe"))relay=p;else p.Dispose();
       }
       if(relay==null)await Task.Delay(100);
      }
      using(relay) {Pass(direct.ExitCode==0&&relay!=null,"Direct game EXE without admission exits and starts its installed launcher");}
     } finally {
      if(!direct.HasExited)direct.Kill();
      foreach(var p in Process.GetProcessesByName("PokeLauncher"))using(p) {
       if(p.MainModule?.FileName==Path.Combine(directory,"PokeLauncher.exe")) {p.Kill();await p.WaitForExitAsync();}
      }
     }
    } else report.Add("SKIP Direct launch relay: an existing user launcher was preserved.");
    report.Add("Test files retained at "+home);
   } catch(Exception e){report.Add("FAIL "+e);Console.Error.WriteLine(e.Message);Environment.ExitCode=1;}
   finally{File.WriteAllLines("docs/github-strict-live-tests.txt",report);host.Close();}
  };
  Application.Run(host);
 }
}
