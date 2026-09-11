using System.Diagnostics;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text.Json;

static class LauncherProgram {
 [STAThread] static void Main(string[] args) {
  if(args.Length>=4 && args[2]=="--wait-parent" && int.TryParse(args[3],out var parent)) { try { Process.GetProcessById(parent).WaitForExit(15000); } catch(ArgumentException) {} }
  ApplicationConfiguration.Initialize();
  using var mutex = new Mutex(true,"Local\\PokeTactics-Launcher",out var acquired);
  if (!acquired) { MessageBox.Show("Der Launcher ist bereits geöffnet."); return; }
  try { Application.Run(new Launcher(args)); } finally { mutex.ReleaseMutex(); }
 }
}
class Launcher : PixelForm {
 readonly string home;
 readonly Service service;
 readonly UpdateConfig updateConfig;
 readonly System.Windows.Forms.Timer polling = new() { Interval = 900000 };
 readonly string credentials;
 readonly Func<GitHubUpdates>? updateFactory;
 string version;
 readonly Label status, versions;
 readonly TextBox notes;
 readonly Button play;
 readonly ProgressBar progress;
 Process? game;
 bool busy;
 bool currentConfirmed;
 readonly bool integration;
 public Launcher(string[] args, bool integrationTest = false, Func<GitHubUpdates>? updateFactory = null) : base("POKÉ TACTICS · LAUNCHER") {
  integration = integrationTest; this.updateFactory=updateFactory;
  home = args.Length >= 2 && args[0] == "--home" ? Path.GetFullPath(args[1]) : AppContext.BaseDirectory;
  version = Files.Read<Build>(Path.Combine(AppContext.BaseDirectory,"build.json")).Version;
  service = File.Exists(Path.Combine(home,"service.json")) ? Files.Read<Service>(Path.Combine(home,"service.json")) : new();
  var configPath=Path.Combine(home,"updates.json");
  updateConfig=File.Exists(configPath)?Files.Read<UpdateConfig>(configPath):new();
  credentials=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"PokeTactics", "github-reader.bin");
  versions = Label("Installiert: "+version+" · Neueste Version: wird geprüft");
  status = Label("Update-Prüfung wird vorbereitet."); status.Height=90;
  progress = new ProgressBar { Width=700, Height=22 }; Body.Controls.Add(progress);
  Label("Versionshinweise"); notes = Input("",true); notes.ReadOnly=true; notes.Height=180;
  play = Button("Spielen",StartGame);
  play.Enabled=false;
  Button("Erneut prüfen / Aktualisieren",()=>_ = Check(true));
  if(updateConfig.PrivateRepository) {
   Label("Privates Repository: persönlicher GitHub-Token mit Contents: Read (nur auf diesem PC)").Height=80;
   var access=Input(); access.UseSystemPasswordChar=true;
   Button("Eigenen Zugriff Windows-geschützt speichern",()=>{
    Directory.CreateDirectory(Path.GetDirectoryName(credentials)!); SecureStore.Save(credentials,access.Text); access.Clear();
    status.Text="Persönlicher Zugriff gespeichert. Erneut prüfen.";
   });
   Button("Gespeicherten GitHub-Zugriff entfernen",()=>{if(File.Exists(credentials)) File.Delete(credentials); currentConfirmed=false; play.Enabled=false; status.Text="Zugriff entfernt. Spielstart erfordert eine erfolgreiche Online-Prüfung.";});
  }
  Button("Beenden",Close);
  Shown += async (_,_) => { await Check(true); if(!IsDisposed) polling.Start(); };
  polling.Tick += async (_,_) => await Check();
  Disposed += (_,_) => polling.Dispose();
  FormClosing += (_,e) => { if (busy) { e.Cancel=true; status.Text="Bitte warte, bis die laufende Aktualisierung abgeschlossen ist."; } };
 }
 string ActiveDirectory => Path.Combine(home,"versions",File.ReadAllText(Path.Combine(home,"active.txt")).Trim());
 async void StartGame() {
  if (busy || game is { HasExited:false }) return;
  await Check(true);
  if(IsDisposed || !currentConfirmed || busy) return;
  try {
   var path = Directory.Exists(Path.Combine(home,"versions")) ? ActiveDirectory : AppContext.BaseDirectory;
   var start = new ProcessStartInfo(Path.Combine(path,"PokeTactics.exe")) { WorkingDirectory=path,UseShellExecute=false };
   start.Environment["POKE_SERVICE"] = service.Endpoint;
   var ticket=Path.Combine(Path.GetTempPath(),"poketactics-launch-"+Guid.NewGuid()+".json");
   Files.Atomic(ticket,JsonSerializer.Serialize(new { version, expires=DateTimeOffset.UtcNow.ToUnixTimeSeconds()+30 },Files.Json));
   start.Environment["POKE_LAUNCH_TICKET"] = ticket;
   game = Process.Start(start); status.Text="Spiel läuft. Neue Updates werden erst nach dem Beenden aktiviert.";
   _ = RemoveTicket(ticket);
  } catch(Exception e) { status.Text="Spielstart fehlgeschlagen: "+e.Message; }
 }
 static async Task RemoveTicket(string path) { await Task.Delay(35000); try { File.Delete(path); } catch(IOException) { } }
 async Task Check(bool force=false) {
  if (busy) return;
  busy=true; play.Enabled=false;
  string? staging=null;
  try {
   if (updateConfig.Repository.Length==0 || updateConfig.PublicKey.Length==0) {
    versions.Text="Installiert: "+version+" · GitHub-Updates noch nicht eingerichtet";
    throw new Exception("Spiel-Repository oder öffentlicher Signierschlüssel fehlt.");
   }
   var personalToken=updateConfig.PrivateRepository && File.Exists(credentials)?SecureStore.Load(credentials):null;
   if(updateConfig.PrivateRepository && string.IsNullOrEmpty(personalToken)) throw new Exception("Persönlicher GitHub-Zugriff für das private Repository fehlt.");
   using var updates=updateFactory?.Invoke() ?? new GitHubUpdates(updateConfig,Path.Combine(home,"github-update-cache.json"),personalToken);
   var offer=await updates.Latest(version,force,requireOnline:true);
   if(offer==null) {
    currentConfirmed=updates.CurrentConfirmed;
    versions.Text="Installiert: "+version;
    status.Text=currentConfirmed ? "Aktuelle Version bestätigt. Vor dem Spielstart wird erneut online geprüft." : "Spielstart gesperrt. Bitte die aktuelle Version online prüfen.";
    return;
   }
   currentConfirmed=false;
   var manifest=offer.Manifest;
   versions.Text="Installiert: "+version+" · Neue Version: "+manifest.Version;
   notes.Text=offer.Release.Body ?? "Keine Versionshinweise vorhanden.";
   var work=Path.Combine(home,"staging"); Directory.CreateDirectory(work);
   staging=Path.Combine(work,Guid.NewGuid().ToString("N")); Directory.CreateDirectory(staging);
   var zip=Path.Combine(staging,"package.zip");
   status.Text="Download läuft …";
   await updates.Download(offer,zip,p=>progress.Value=p);
   var extracted=Path.Combine(staging,"build"); Directory.CreateDirectory(extracted);
   status.Text="Paket wird geprüft und vorbereitet …";
   progress.Style=ProgressBarStyle.Marquee;
   await Task.Run(()=>Files.Extract(zip,extracted));
   progress.Style=ProgressBarStyle.Continuous; progress.Value=100;
   if (Files.Read<Build>(Path.Combine(extracted,"build.json")).Version!=manifest.Version || !File.Exists(Path.Combine(extracted,"PokeTactics.exe")) || !File.Exists(Path.Combine(extracted,"PokeTactics.pck")) || !File.Exists(Path.Combine(extracted,"PokeLauncher.exe"))) throw new Exception("Update enthält keinen vollständigen Build.");
   // Never touch running game or launcher binaries. A new directory becomes active atomically.
   status.Text="Update vorbereitet. Warte auf das Ende eines laufenden Spiels …";
   while (GameRunning()) await Task.Delay(1000);
   var target=Path.Combine(home,"versions",manifest.Version);
   Directory.CreateDirectory(Path.GetDirectoryName(target)!);
   if (Directory.Exists(target)) {
    if (File.ReadAllText(Path.Combine(home,"active.txt")).Trim()==manifest.Version) throw new Exception("Version ist bereits aktiv.");
    Directory.Move(target,Path.Combine(staging,"interrupted-build"));
   }
   Directory.Move(extracted,target);
   var active=Path.Combine(home,"active.txt");
   if (File.Exists(active)) Files.Atomic(Path.Combine(home,"previous.txt"),File.ReadAllText(active));
   var previousVersion=File.ReadAllText(active).Trim();
   Files.Atomic(active,manifest.Version);
   version=manifest.Version;
   status.Text="Update installiert. Der Launcher startet neu …";
   if (integration) return;
   try { Process.Start(new ProcessStartInfo(Path.Combine(target,"PokeLauncher.exe")) { UseShellExecute=false, ArgumentList={"--home",home,"--wait-parent",Environment.ProcessId.ToString()} }); }
   catch { Files.Atomic(active,previousVersion); version=previousVersion; throw; }
   // New process waits for this process to release the update lock.
   busy=false; Close();
  } catch(Exception e) { currentConfirmed=false; status.Text="Spielstart gesperrt: "+e.Message+" Bitte erneut prüfen. Eine laufende Partie wird nicht unterbrochen."; }
  finally { progress.Style=ProgressBarStyle.Continuous; if(staging!=null) { try { Directory.Delete(staging,true); } catch(IOException) { } } busy=false; play.Enabled=currentConfirmed; }
 }
 bool GameRunning() {
  if(game is { HasExited:false }) return true;
  foreach(var p in Process.GetProcessesByName("PokeTactics")) { using(p) { try { if(p.MainModule?.FileName?.StartsWith(home,StringComparison.OrdinalIgnoreCase)==true) return true; } catch { return true; } } }
  return false;
 }
}
