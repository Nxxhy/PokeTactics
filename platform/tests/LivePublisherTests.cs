using System.Reflection;
class LivePublisherTests {
 [STAThread] static void Main(string[] args) {
  if(args.Length!=2 || (args[0]!="--dispatch-real-release" && args[0]!="--verify-real-release"))throw new Exception("Use --dispatch-real-release x.y.z to start a GitHub build, or --verify-real-release x.y.z for read-only verification.");
  StableVersion.Parse(args[1]);ApplicationConfiguration.Initialize();
  using var host=new Form {ShowInTaskbar=false,WindowState=FormWindowState.Minimized};
  host.Shown+=async(_,_)=>{
   try {
    if(args[0]=="--verify-real-release") {
     using var updates=new GitHubUpdates(Files.Read<UpdateConfig>("platform/updates.json"),Path.Combine(Path.GetTempPath(),"poke-verify-"+Guid.NewGuid()+".json"));
     var offer=await updates.Latest("0.0.0");
     if(offer?.Manifest.Version!=args[1])throw new Exception("Expected complete signed GitHub release "+args[1]);
     Console.WriteLine("PASS Actual GitHub stable release "+args[1]+": complete metadata, signature, pinned public key, checksum file and package size verified.");return;
    }
    using var publisher=new Publisher();
    T Field<T>(string name)=>(T)typeof(Publisher).GetField(name,BindingFlags.Instance|BindingFlags.NonPublic)!.GetValue(publisher)!;
    Task Call(string name)=>(Task)typeof(Publisher).GetMethod(name,BindingFlags.Instance|BindingFlags.NonPublic)!.Invoke(publisher,null)!;
    await Call("UseGitLogin");
    Field<TextBox>("version").Text=args[1];
    Field<TextBox>("notes").Text="GitHub-Updates sind eingerichtet. Diese Version prüft den vollständigen Update-Weg von 9.1.0 auf "+args[1]+" und ergänzt die Anmeldung der Entwickler-App über Git.";
    await Call("Dispatch");
    Console.WriteLine("PASS Actual publisher authenticated through Git, loaded release/build status and dispatched v"+args[1]);
   } catch(Exception e){Console.Error.WriteLine(e.Message);Environment.ExitCode=1;}finally{host.Close();}
  };
  Application.Run(host);
 }
}
