using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

if(args.Length<1) throw new ArgumentException("Usage: ReleaseTools x.y.z [build-directory] [output-directory]");
var version=args[0];var source=Path.GetFullPath(args.Length>1?args[1]:"dist/PlayerBuild");var output=Path.GetFullPath(args.Length>2?args[2]:"dist/Release");
if(!Regex.IsMatch(version,@"^(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})$") || version.Split('.').Any(p=>int.Parse(p)>65535)) throw new Exception("Invalid stable version");
var options=new JsonSerializerOptions {PropertyNameCaseInsensitive=true,WriteIndented=true};
var config=JsonSerializer.Deserialize<Config>(File.ReadAllText("platform/updates.json"),options)!;
if(config.Repository!="Nxxhy/PokeTactics") throw new Exception("Wrong game repository");
using var build=JsonDocument.Parse(File.ReadAllText(Path.Combine(source,"build.json")));
if(build.RootElement.GetProperty("version").GetString()!=version)throw new Exception("Build version mismatch");
foreach(var name in new[]{"PokeTactics.exe","PokeTactics.pck","PokeLauncher.exe"}) if(!File.Exists(Path.Combine(source,name)))throw new Exception("Missing "+name);
foreach(var entry in Directory.EnumerateFileSystemEntries(source,"*",SearchOption.AllDirectories)) {
 if((File.GetAttributes(entry)&FileAttributes.ReparsePoint)!=0 || Regex.IsMatch(Path.GetFileName(entry),@"(?i)token|private|Publisher|\.pem$|^updates.json$|^service.json$"))throw new Exception("Untrusted build content: "+Path.GetFileName(entry));
}
using var signer=RSA.Create();using var verifier=RSA.Create();
var secret=Environment.GetEnvironmentVariable("UPDATE_SIGNING_PRIVATE_KEY") ?? throw new Exception("UPDATE_SIGNING_PRIVATE_KEY secret missing");
signer.ImportFromPem(secret);Environment.SetEnvironmentVariable("UPDATE_SIGNING_PRIVATE_KEY",null);
verifier.ImportFromPem(config.PublicKey);
if(signer.KeySize<3072 || !signer.ExportSubjectPublicKeyInfo().SequenceEqual(verifier.ExportSubjectPublicKeyInfo()))throw new Exception("Signing key does not match pinned public key");
Directory.CreateDirectory(output);
var package=$"PokeTactics-{version}-win-x64.zip";var path=Path.Combine(output,package);
if(File.Exists(path))File.Delete(path);
ZipFile.CreateFromDirectory(source,path,CompressionLevel.Optimal,false);
string hash;using(var file=File.OpenRead(path))hash=Convert.ToHexString(SHA256.HashData(file)).ToLowerInvariant();
var payload=JsonSerializer.SerializeToUtf8Bytes(new{repository=config.Repository,version,tag="v"+version,platform="win-x64",package,size=new FileInfo(path).Length,sha256=hash},options);
var signature=signer.SignData(payload,HashAlgorithmName.SHA256,RSASignaturePadding.Pss);
if(!verifier.VerifyData(payload,signature,HashAlgorithmName.SHA256,RSASignaturePadding.Pss))throw new Exception("Signature self-check failed");
File.WriteAllBytes(Path.Combine(output,"update-win-x64.json"),payload);
File.WriteAllText(Path.Combine(output,"update-win-x64.sig"),Convert.ToBase64String(signature),new UTF8Encoding(false));
File.WriteAllText(Path.Combine(output,"SHA256SUMS.txt"),hash+"  "+package+"\n",new UTF8Encoding(false));
Console.WriteLine($"Signed v{version} for {config.Repository}");
record Config(string Repository,string PublicKey);
