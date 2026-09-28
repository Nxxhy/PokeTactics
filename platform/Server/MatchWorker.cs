using System.Diagnostics;
using System.Text.Json;

sealed class MatchWorker : IDisposable {
 readonly Process process;
 bool disposed;
 public MatchWorker(IEnumerable<Member> members) {
  var game=Environment.GetEnvironmentVariable("POKE_GAME_DIR")??Path.GetFullPath(Path.Combine(AppContext.BaseDirectory,".."));
  var executable=Path.Combine(game,"PokeTactics.exe");
  if(!File.Exists(executable)||!File.Exists(Path.Combine(game,"PokeTactics.pck")))throw new Exception("Die Multiplayer-Spielengine fehlt im Installationspaket.");
  var start=new ProcessStartInfo(executable){UseShellExecute=false,CreateNoWindow=true,WorkingDirectory=game,RedirectStandardInput=true,RedirectStandardOutput=true,RedirectStandardError=true};
  foreach(var arg in new[]{"--headless","--path",game,"--script","res://core/network_worker.gd"})start.ArgumentList.Add(arg);
  process=Process.Start(start)??throw new Exception("Spielengine konnte nicht gestartet werden.");
  process.ErrorDataReceived+=(_,_)=>{};process.BeginErrorReadLine();
  try{Call(new {op="init",members=members.Select(m=>new {id=m.Id,name=m.Name}),seed=Random.Shared.Next(1,100000000)});}catch{Dispose();throw;}
 }
 public JsonElement Call(object message) {
  using var timeout=new CancellationTokenSource(TimeSpan.FromSeconds(25));
  process.StandardInput.WriteLine(JsonSerializer.Serialize(message));process.StandardInput.Flush();
  while(true) {
   var line=process.StandardOutput.ReadLineAsync(timeout.Token).AsTask().GetAwaiter().GetResult();
   if(line==null)throw new Exception("Die Multiplayer-Spielengine wurde beendet.");
   if(line.StartsWith("NET:")){using var document=JsonDocument.Parse(line[4..]);return document.RootElement.Clone();}
  }
 }
 public object View(Member member,int seen) => Call(new {op="view",id=member.Id,seen}).GetProperty("match_state");
 public void Drop(Member member)=>Call(new {op="drop",id=member.Id});
 public void Dispose(){if(disposed)return;disposed=true;if(!process.HasExited)process.Kill(true);process.Dispose();}
}
