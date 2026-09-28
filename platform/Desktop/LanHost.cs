using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text.Json;

sealed class LanHost : IDisposable {
 Process? process;
 string lastError="";
 public bool Running => process is {HasExited:false};
 public int Port {get;private set;}
 public static bool PrivateAddress(IPAddress address) {
  if(address.IsIPv4MappedToIPv6)address=address.MapToIPv4();
  if(address.AddressFamily!=AddressFamily.InterNetwork)return false;
  var b=address.GetAddressBytes();return b[0]==127||b[0]==10||(b[0]==172&&b[1]>=16&&b[1]<=31)||(b[0]==192&&b[1]==168);
 }
 public static Uri Endpoint(string text) {
  var value=text.Trim();if(!value.Contains("://"))value="http://"+value;
  if(!Uri.TryCreate(value,UriKind.Absolute,out var uri)||uri.Scheme!="http"||uri.Port<1024||uri.UserInfo!=""||uri.AbsolutePath!="/"||uri.Query!=""||uri.Fragment!=""||!IPAddress.TryParse(uri.Host,out var ip)||!PrivateAddress(ip))
   throw new Exception("Bitte eine lokale IPv4-Adresse mit Port eingeben, z. B. 192.168.178.20:18790.");
  return uri;
 }
 public static string[] Addresses(int port) => NetworkInterface.GetAllNetworkInterfaces()
  .Where(n=>n.OperationalStatus==OperationalStatus.Up&&n.NetworkInterfaceType!=NetworkInterfaceType.Loopback)
  .SelectMany(n=>n.GetIPProperties().UnicastAddresses).Select(a=>a.Address)
  .Where(a=>a.AddressFamily==AddressFamily.InterNetwork&&PrivateAddress(a)&&!IPAddress.IsLoopback(a))
  .Select(a=>$"{a}:{port}").Distinct().ToArray();
 public static async Task Probe(Uri uri,string? instance=null,string? version=null) {
  using var client=new HttpClient(new HttpClientHandler {AllowAutoRedirect=false,UseProxy=false}) {Timeout=TimeSpan.FromSeconds(2)};
  using var response=await client.GetAsync(new Uri(uri,"health"));response.EnsureSuccessStatusCode();
  using var data=JsonDocument.Parse(await response.Content.ReadAsStringAsync());
  var root=data.RootElement;
  if(!root.TryGetProperty("service",out var service)||service.GetString()!="PokeTacticsLobby"||
    (instance!=null&&root.GetProperty("instance").GetString()!=instance))throw new Exception("Unter dieser Adresse antwortet kein passender Poké-Tactics-Lobbyserver.");
  if(version!=null&&root.TryGetProperty("requiredVersion",out var required)&&required.GetString() is {Length:>0} v&&v!=version)
   throw new Exception("Host und Gast benötigen dieselbe Spielversion (Host: "+v+").");
 }
 public async Task Start(string directory,int port,string version) {
  if(Running)throw new Exception("Der lokale Server läuft bereits.");
  var executable=Path.Combine(directory,"Lobby","PokeLobby.exe");
  if(!File.Exists(executable))throw new Exception("Der lokale Lobbyserver fehlt. Bitte das aktuelle Setup installieren.");
  Port=port;var instance=Guid.NewGuid().ToString("N");
  var start=new ProcessStartInfo(executable) {UseShellExecute=false,CreateNoWindow=true,WorkingDirectory=Path.GetDirectoryName(executable)!,RedirectStandardInput=true,RedirectStandardOutput=true,RedirectStandardError=true};
  start.ArgumentList.Add("--urls");start.ArgumentList.Add($"http://0.0.0.0:{port}");
  start.Environment["POKE_LAN"]="1";start.Environment["POKE_REQUIRED_VERSION"]=version;
  start.Environment["POKE_PARENT_INPUT"]="1";start.Environment["POKE_INSTANCE"]=instance;
  lastError="";process=Process.Start(start)??throw new Exception("Lobbyserver konnte nicht gestartet werden.");
  process.OutputDataReceived+=(_,e)=>{if(e.Data!=null)lastError=e.Data;};process.ErrorDataReceived+=(_,e)=>{if(e.Data!=null)lastError=e.Data;};
  process.BeginOutputReadLine();process.BeginErrorReadLine();
  try {
   for(var attempt=0;attempt<30;attempt++) {
    if(!Running)throw new Exception("Lobbyserver beendet. Port möglicherweise belegt. "+lastError);
    try {await Probe(new Uri($"http://127.0.0.1:{port}"),instance,version);return;}catch(HttpRequestException){}catch(TaskCanceledException){}
    await Task.Delay(200);
   }
   throw new Exception("Lobbyserver antwortet nicht. Bitte Port prüfen und erneut versuchen.");
  }catch{Stop();throw;}
 }
 public void Stop() {if(process!=null){if(!process.HasExited)process.Kill(entireProcessTree:true);process.Dispose();process=null;}}
 public void Dispose()=>Stop();
}
