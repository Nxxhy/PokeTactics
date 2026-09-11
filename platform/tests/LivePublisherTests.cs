using System.Reflection;
class LivePublisherTests {
 [STAThread] static void Main(string[] args) {
  if(args.Length!=2 || args[0]!="--dispatch-real-release")throw new Exception("Explicit --dispatch-real-release x.y.z required; this starts an actual GitHub build.");
  StableVersion.Parse(args[1]);ApplicationConfiguration.Initialize();
  using var host=new Form {ShowInTaskbar=false,WindowState=FormWindowState.Minimized};
  host.Shown+=async(_,_)=>{
   try {
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
