using System.Text.Json;
using System.Drawing.Text;
using System.Runtime.InteropServices;
using System.Reflection;
using System.Net.Http;
using System.Security.Cryptography;
using System.IO.Compression;

static class Files {
 public static readonly JsonSerializerOptions Json = new() { PropertyNameCaseInsensitive = true, WriteIndented = true };
 public static T Read<T>(string path) => JsonSerializer.Deserialize<T>(File.ReadAllText(path), Json)!;
 public static void Atomic(string path, string text) { File.WriteAllText(path + ".tmp", text); File.Move(path + ".tmp", path, true); }
 public static string Hash(string path) { using var f = File.OpenRead(path); return Convert.ToHexString(SHA256.HashData(f)); }
 public static HttpClient Client() => new(new HttpClientHandler { AllowAutoRedirect = false }) { Timeout = TimeSpan.FromMinutes(15) };
 public static Uri Endpoint(string value) {
  if (!Uri.TryCreate(value.TrimEnd('/')+"/", UriKind.Absolute, out var uri) || (uri.Scheme != "https" && !(uri.Scheme == "http" && uri.Host == "127.0.0.1"))) throw new Exception("Ein HTTPS-Server muss einmalig eingerichtet werden. HTTP ist nur für Tests auf 127.0.0.1 erlaubt.");
  return uri;
 }
 public static void Extract(string zip, string target) {
  using var archive = ZipFile.OpenRead(zip);
  if (archive.Entries.Count > 10000 || archive.Entries.Sum(e => e.Length) > 2L*1024*1024*1024) throw new Exception("Paket überschreitet Größenlimit.");
  foreach (var e in archive.Entries) {
   var dest = Path.GetFullPath(Path.Combine(target, e.FullName));
   if (!dest.StartsWith(Path.GetFullPath(target)+Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) || e.FullName.Contains(':') || e.FullName.Contains('\\') || ((e.ExternalAttributes >> 16) & 0xF000) == 0xA000) throw new Exception("Unsicherer Paketpfad.");
  }
  archive.ExtractToDirectory(target);
 }
}
record Service(string Endpoint = "", string PublicKey = "");
record Build(string Version);
record Signed(string Payload, string Signature);
record Manifest(string Version, string Sha256, long Size, string Notes, string MinimumVersion, string Package, long Expires);
class PixelForm : Form {
 [DllImport("gdi32.dll")] static extern IntPtr AddFontMemResourceEx(IntPtr data,uint size,IntPtr reserved,ref uint count);
 [DllImport("gdi32.dll")] static extern bool RemoveFontMemResourceEx(IntPtr handle);
 readonly PrivateFontCollection fonts = new();
 protected readonly FlowLayoutPanel Body = new() { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true, Padding = new Padding(24) };
 public PixelForm(string title) {
  Text = title; MinimumSize = new Size(660,620); Size = new Size(800,800); StartPosition = FormStartPosition.CenterScreen; BackColor = ColorTranslator.FromHtml("#e8f0c8"); ForeColor = ColorTranslator.FromHtml("#384848");
  using var resource = Assembly.GetExecutingAssembly().GetManifestResourceStream("pixel.ttf")!;
  using var bytes = new MemoryStream(); resource.CopyTo(bytes); var data = bytes.ToArray(); var ptr = Marshal.AllocCoTaskMem(data.Length);
  Marshal.Copy(data,0,ptr,data.Length); fonts.AddMemoryFont(ptr,data.Length); uint fontCount=0; var fontHandle=AddFontMemResourceEx(ptr,(uint)data.Length,IntPtr.Zero,ref fontCount);
  Disposed+=(_,_)=>{fonts.Dispose();RemoveFontMemResourceEx(fontHandle);Marshal.FreeCoTaskMem(ptr);};
  Font = new Font(fonts.Families[0],18,FontStyle.Regular,GraphicsUnit.Pixel);
  Controls.Add(Body); Body.SizeChanged += (_,_) => { foreach(Control c in Body.Controls) c.Width = Math.Max(300,Body.ClientSize.Width-65); };
  Label(title,30); AutoScaleMode = AutoScaleMode.Dpi;
 }
 protected Label Label(string text, int size = 22) { var l = new Label { Text=text, AutoSize=false, Height=60, Width=700, Font=new Font(Font.FontFamily,size,GraphicsUnit.Pixel), Margin=new Padding(0,4,0,8), UseCompatibleTextRendering=true }; Body.Controls.Add(l); return l; }
 protected Button Button(string text, Action action) { var b = new Button { Text=text, Width=700, Height=48, FlatStyle=FlatStyle.Flat, BackColor=ColorTranslator.FromHtml("#f8f8e8"), Margin=new Padding(0,4,0,4), UseCompatibleTextRendering=true }; b.FlatAppearance.BorderSize=3; b.Click+=(_,_)=>action(); Body.Controls.Add(b); return b; }
 protected TextBox Input(string text="", bool multiline=false) { var t=new TextBox { Text=text,Width=700,Height=multiline?100:32,Multiline=multiline,BackColor=ColorTranslator.FromHtml("#f8f8e8"),ScrollBars=multiline?ScrollBars.Vertical:ScrollBars.None }; Body.Controls.Add(t); return t; }
 protected async Task Guard(Func<Task> action, Label status) { try { await action(); } catch(Exception e) { status.Text = e.Message; } }
}
