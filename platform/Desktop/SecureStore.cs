using System.Runtime.InteropServices;
using System.Text;
static class SecureStore {
 [StructLayout(LayoutKind.Sequential)] struct Blob { public int Size; public IntPtr Data; }
 [DllImport("crypt32.dll",SetLastError=true,CharSet=CharSet.Unicode)] static extern bool CryptProtectData(ref Blob input,string description,IntPtr entropy,IntPtr reserved,IntPtr prompt,int flags,out Blob output);
 [DllImport("crypt32.dll",SetLastError=true)] static extern bool CryptUnprotectData(ref Blob input,IntPtr description,IntPtr entropy,IntPtr reserved,IntPtr prompt,int flags,out Blob output);
 [DllImport("kernel32.dll")] static extern IntPtr LocalFree(IntPtr memory);
 static byte[] Convert(byte[] bytes,bool protect) {
  var input=new Blob { Size=bytes.Length,Data=Marshal.AllocHGlobal(bytes.Length) }; Marshal.Copy(bytes,0,input.Data,bytes.Length);
  Blob output=default;
  try { var ok=protect?CryptProtectData(ref input,"PokeTacticsPublisher",IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,1,out output):CryptUnprotectData(ref input,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,1,out output); if(!ok)throw new Exception("Windows konnte die Zugangsdaten nicht schützen/entschlüsseln."); var result=new byte[output.Size]; Marshal.Copy(output.Data,result,0,result.Length);return result; }
  finally { Marshal.FreeHGlobal(input.Data);if(output.Data!=IntPtr.Zero)LocalFree(output.Data); }
 }
 public static void Save(string path,string token)=>File.WriteAllBytes(path,Convert(Encoding.UTF8.GetBytes(token),true));
 public static string Load(string path)=>Encoding.UTF8.GetString(Convert(File.ReadAllBytes(path),false));
}
