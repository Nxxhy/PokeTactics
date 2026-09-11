using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Diagnostics;

static class PublisherProgram {
 [STAThread] static void Main() { ApplicationConfiguration.Initialize(); Application.Run(new Publisher()); }
}
class Publisher : PixelForm {
 readonly TextBox repository,token,branch,version,notes;
 readonly Label status;
 readonly ListBox history;
 readonly Button publish;
 readonly System.Windows.Forms.Timer timer = new() { Interval=30000 };
 readonly string preferences=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"PokeTacticsPublisher");
 bool busy;
 public Publisher() : base("POKÉ TACTICS · GITHUB RELEASES") {
  Size=new Size(880,1000);
  Label("Spiel-Repository · Eigentümer/Repository"); repository=Input("Nxxhy/PokeTactics"); repository.ReadOnly=true;
  Label("Persönlicher GitHub-Token · Actions: Write und Contents: Write").Height=80;
  token=Input(); token.UseSystemPasswordChar=true;
  Button("Zugang Windows-geschützt speichern",()=>{
   Directory.CreateDirectory(preferences); SecureStore.Save(Path.Combine(preferences,"github-token.bin"),token.Text); status!.Text="Zugang nur für diesen Windows-Benutzer gespeichert.";
  });
  Label("Build-Branch oder Commit"); branch=Input("main");
  Label("Neue stabile Version (x.y.z)"); version=Input("9.1.0");
  Label("Versionshinweise"); notes=Input("",true); notes.Height=150;
  Button("Build starten · Release-Entwurf vorbereiten",()=>_ = Run(Dispatch));
  status=Label("GitHub Actions baut, testet und signiert. Veröffentlichung erfolgt separat."); status.Height=130;
  history=new ListBox { Width=700,Height=180,HorizontalScrollbar=true }; Body.Controls.Add(history);
  Button("Build-Status und Entwürfe aktualisieren",()=>_ = Run(RefreshStatus));
  Button("Ausgewählten Build / Release in GitHub öffnen",()=>{ if(history.SelectedItem is Row r) Process.Start(new ProcessStartInfo(r.Url){UseShellExecute=true}); });
  publish=Button("Ausgewählten fertigen Entwurf veröffentlichen",()=>_ = Run(Publish));
  Label("Auch direkt in GitHub veröffentlichte Releases verwenden dieselben signierten Dateien. Keine lokalen Paket-Uploads mehr.").Height=100;
  try { if(File.Exists(Path.Combine(preferences,"github-token.bin"))) token.Text=SecureStore.Load(Path.Combine(preferences,"github-token.bin")); } catch { status.Text="Gespeicherten GitHub-Zugang bitte erneuern."; }
  timer.Tick+=async(_,_)=>{ if(!string.IsNullOrWhiteSpace(token.Text)) await Run(RefreshStatus); };
  Shown+=(_,_)=>timer.Start(); Disposed+=(_,_)=>timer.Dispose();
  FormClosing+=(_,e)=>{if(busy){e.Cancel=true;status.Text="Bitte laufende GitHub-Anfrage abwarten.";}};
 }
 async Task Run(Func<Task> action) { if(busy)return; busy=true; publish.Enabled=false; try {await action();} catch(Exception e){status.Text=e.Message;} finally {busy=false;publish.Enabled=true;} }
 async Task<JsonElement> Api(HttpMethod method,string path,object? body=null) {
  GitHubUpdates.ValidateRepository(repository.Text);
  if(string.IsNullOrWhiteSpace(token.Text)) throw new Exception("GitHub-Zugang fehlt. Token nur hier in der Entwickler-App eingeben.");
  using var client=Files.Client();
  using var q=GitHubUpdates.Request(method,new Uri($"https://api.github.com/repos/{repository.Text}/{path}"),token.Text);
  if(body!=null) q.Content=new StringContent(JsonSerializer.Serialize(body),Encoding.UTF8,"application/json");
  using var timeout=new CancellationTokenSource(TimeSpan.FromSeconds(30));
  using var response=await client.SendAsync(q,timeout.Token);
  if(!response.IsSuccessStatusCode) throw new Exception($"GitHub {(int)response.StatusCode}: Repository, Token-Rechte, Workflow und Actions-Logs prüfen.");
  if(response.StatusCode==System.Net.HttpStatusCode.NoContent) return default;
  using var doc=JsonDocument.Parse(await response.Content.ReadAsStringAsync(timeout.Token)); return doc.RootElement.Clone();
 }
 async Task Dispatch() {
  StableVersion.Parse(version.Text);
  if(notes.Text.Length>12000 || string.IsNullOrWhiteSpace(branch.Text)) throw new Exception("Branch fehlt oder Versionshinweise sind zu lang.");
  await Api(HttpMethod.Post,"actions/workflows/release.yml/dispatches",new { @ref=branch.Text,inputs=new {version=version.Text,notes=notes.Text} });
  status.Text="Build angefordert für v"+version.Text+". Status wird alle 30 Sekunden geladen; Fehlerdetails stehen im ausgewählten GitHub-Build.";
  await RefreshStatus();
 }
 async Task RefreshStatus() {
  var runs=await Api(HttpMethod.Get,"actions/workflows/release.yml/runs?per_page=10");
  var releases=await Api(HttpMethod.Get,"releases?per_page=20");
  var selection=(history.SelectedItem as Row)?.Url;
  history.Items.Clear();
  foreach(var r in releases.EnumerateArray()) history.Items.Add(new Row(r.GetProperty("id").GetInt64(),r.GetProperty("tag_name").GetString()+ (r.GetProperty("draft").GetBoolean()?" · ENTWURF":" · veröffentlicht"),r.GetProperty("html_url").GetString()!,r.GetProperty("draft").GetBoolean()));
  foreach(var r in runs.GetProperty("workflow_runs").EnumerateArray()) history.Items.Add(new Row(0,$"Build {r.GetProperty("display_title").GetString()} · {r.GetProperty("status").GetString()} · {r.GetProperty("conclusion").ToString()}",r.GetProperty("html_url").GetString()!,false));
  foreach(Row r in history.Items) if(r.Url==selection) history.SelectedItem=r;
 }
 async Task Publish() {
  if(history.SelectedItem is not Row {Draft:true} row) throw new Exception("Bitte einen fertigen Release-Entwurf auswählen.");
  var raw=await Api(HttpMethod.Get,"releases/"+row.Id);
  var release=raw.Deserialize<GitRelease>(Files.Json)!;
  var configPath=Path.Combine(AppContext.BaseDirectory,"updates.json");
  if(!File.Exists(configPath)) throw new Exception("updates.json mit dem öffentlichen Signierschlüssel fehlt neben der Entwickler-App.");
  var config=Files.Read<UpdateConfig>(configPath);
  if(config.Repository!=repository.Text) throw new Exception("Signierkonfiguration gehört zu einem anderen Repository.");
  using var updates=new GitHubUpdates(config,Path.Combine(preferences,"unused-cache.json"),token.Text);
  var offer=await updates.Validate(release);
  if(!release.Draft) throw new Exception("Release ist bereits veröffentlicht.");
  if(MessageBox.Show($"{config.Repository}: {offer.Manifest.Version} mit geprüfter Signatur jetzt öffentlich veröffentlichen?","Release veröffentlichen",MessageBoxButtons.YesNo)!=DialogResult.Yes) return;
  await Api(HttpMethod.Patch,"releases/"+row.Id,new {draft=false,prerelease=false,make_latest="true"});
  status.Text="Release veröffentlicht. Launcher erkennen es bei der nächsten GitHub-Prüfung.";
  await RefreshStatus();
 }
 record Row(long Id,string Text,string Url,bool Draft) {public override string ToString()=>Text;}
}
