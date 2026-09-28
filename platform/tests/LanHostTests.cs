using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Net.Sockets;
using System.Diagnostics;
using System.Text.Json;

var passed=0;
void Check(bool ok,string message){if(!ok)throw new Exception(message);Console.WriteLine("PASS "+message);passed++;}
int FreePort(){var listener=new TcpListener(IPAddress.Loopback,0);listener.Start();var port=((IPEndPoint)listener.LocalEndpoint).Port;listener.Stop();return port;}
foreach(var address in new[]{"192.168.1.3:18790","10.0.0.2:18790","172.16.0.2:18790","127.0.0.1:18790"})Check(LanHost.Endpoint(address).Scheme=="http","Accept private LAN endpoint "+address);
foreach(var address in new[]{"8.8.8.8:18790","172.32.0.1:18790","192.168.1.3.evil.test:18790","user@192.168.1.1:18790","192.168.1.1:18790/path","192.168.1.1:99999","file:///test","192.168.1.1","192.168.1.1:80"}) {
 bool rejected=false;try{LanHost.Endpoint(address);}catch{rejected=true;}Check(rejected,"Reject non-LAN or malformed endpoint "+address);
}
using var host=new LanHost();var port=FreePort();var root=Path.GetFullPath("dist/PlayerBuild");
await host.Start(root,port,"9.2.0");Check(host.Running,"Bundled self-contained server starts from launcher controller");
using var client=new HttpClient {BaseAddress=new Uri($"http://127.0.0.1:{port}"),Timeout=TimeSpan.FromSeconds(5)};
async Task<JsonElement> Join(string name,string code="") {using var r=await client.PostAsJsonAsync("/lobby",new {name,code,version="9.2.0"});r.EnsureSuccessStatusCode();return JsonDocument.Parse(await r.Content.ReadAsStringAsync()).RootElement.Clone();}
var trainer=await Join("Host");var code=trainer.GetProperty("lobby").GetProperty("code").GetString()!;var guest=await Join("Gast",code);
Check(guest.GetProperty("lobby").GetProperty("members").GetArrayLength()==2,"Two independent sessions join the locally hosted lobby");
using(var old=await client.PostAsJsonAsync("/lobby",new {name="Alt",code,version="9.1.2"}))Check((int)old.StatusCode==426,"Host rejects mismatched game version");
using(var q=new HttpRequestMessage(HttpMethod.Post,$"/lobby/{code}/session")){
 q.Headers.Authorization=new("Bearer",guest.GetProperty("token").GetString());q.Content=JsonContent.Create(new {action="ready",version="9.2.0",ready=true});
 using var r=await client.SendAsync(q);var body=JsonDocument.Parse(await r.Content.ReadAsStringAsync());Check(r.IsSuccessStatusCode&&body.RootElement.GetProperty("members")[1].GetProperty("ready").GetBoolean(),"Guest ready state synchronized");
}
var conflict=false;using(var other=new LanHost()){try{await other.Start(root,port,"9.2.0");}catch{conflict=true;}}
Check(conflict&&host.Running,"Port conflict reported without killing original server");
host.Stop();Check(!host.Running,"Stopping host terminates owned server");
await host.Start(root,port,"9.2.0");Check(host.Running,"Server restarts on same port");host.Stop();
var parentPort=FreePort();var start=new ProcessStartInfo(Path.Combine(root,"Lobby/PokeLobby.exe")){UseShellExecute=false,CreateNoWindow=true,RedirectStandardInput=true,RedirectStandardOutput=true,RedirectStandardError=true,ArgumentList={"--urls",$"http://127.0.0.1:{parentPort}"}};
start.Environment["POKE_PARENT_INPUT"]="1";
using(var orphan=Process.Start(start)!) {orphan.BeginOutputReadLine();orphan.BeginErrorReadLine();try{await Task.Delay(1000);orphan.StandardInput.Close();using var timeout=new CancellationTokenSource(TimeSpan.FromSeconds(10));await orphan.WaitForExitAsync(timeout.Token);Check(orphan.HasExited,"Lost launcher input shuts server down without orphan process");}finally{if(!orphan.HasExited)orphan.Kill(true);}}
File.WriteAllText("docs/lan-host-tests.txt",$"{passed} passed, 0 failed. Actual packaged server, two HTTP sessions on one computer. Physical second device and firewall traversal not tested.");
Console.WriteLine($"LAN HOST: {passed} passed, 0 failed");
