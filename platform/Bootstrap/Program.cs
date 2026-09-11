using System.Diagnostics;
using System.Runtime.InteropServices;
class Program {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int MessageBox(IntPtr h,string text,string caption,uint type);
 static void Main() {
  var home=AppContext.BaseDirectory;
  try {
   var active=File.ReadAllText(Path.Combine(home,"active.txt")).Trim();
   if(!Valid(active)) throw new Exception("Ungültige aktive Version.");
   var exe=Path.Combine(home,"versions",active,"PokeLauncher.exe");
   if (!File.Exists(exe) && File.Exists(Path.Combine(home,"previous.txt"))) {
    var previous=File.ReadAllText(Path.Combine(home,"previous.txt")).Trim();
    if(!Valid(previous)) throw new Exception("Ungültige Rückfallversion.");
    exe=Path.Combine(home,"versions",previous,"PokeLauncher.exe");
    File.WriteAllText(Path.Combine(home,"active.txt.tmp"),previous); File.Move(Path.Combine(home,"active.txt.tmp"),Path.Combine(home,"active.txt"),true);
   }
   try { Process.Start(new ProcessStartInfo(exe) { UseShellExecute=false,ArgumentList={"--home",home} }); }
   catch when (File.Exists(Path.Combine(home,"previous.txt"))) {
    var previous=File.ReadAllText(Path.Combine(home,"previous.txt")).Trim();
    if(!Valid(previous)) throw;
    var fallback=Path.Combine(home,"versions",previous,"PokeLauncher.exe");
    Process.Start(new ProcessStartInfo(fallback) { UseShellExecute=false,ArgumentList={"--home",home} });
    File.WriteAllText(Path.Combine(home,"active.txt.tmp"),previous);File.Move(Path.Combine(home,"active.txt.tmp"),Path.Combine(home,"active.txt"),true);
   }
  } catch(Exception e) { MessageBox(IntPtr.Zero,"Start fehlgeschlagen: "+e.Message+" Bitte Setup erneut ausführen.","Poké Tactics",0x10); }
 }
 static bool Valid(string version) => System.Text.RegularExpressions.Regex.IsMatch(version,@"^(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})$") && Version.TryParse(version,out var v) && v.Major<=65535 && v.Minor<=65535 && v.Build<=65535;
}
