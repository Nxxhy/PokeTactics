using System.Security.Cryptography;
using System.Text.Json;
using System.IO.Compression;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(o => o.Limits.MaxRequestBodySize = 600L * 1024 * 1024);
builder.Services.AddRateLimiter(o => { o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(c => RateLimitPartition.GetFixedWindowLimiter(c.Connection.RemoteIpAddress?.ToString() ?? "unknown", _ => new FixedWindowRateLimiterOptions { PermitLimit = 1200, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 })); o.RejectionStatusCode = 429; });
var app = builder.Build();
app.UseRateLimiter();
var gate = new object();
var rooms = new Dictionary<string, Room>();
string Minimum() => Environment.GetEnvironmentVariable("POKE_MINIMUM_VERSION") ?? "9.0.0";
bool Compatible(string version) => Version.TryParse(version, out var v) && v >= Version.Parse(Minimum());
void Sweep() {
    var now = DateTimeOffset.UtcNow;
    foreach (var room in rooms.Values.ToArray()) {
        if (now - room.Members[0].Seen > TimeSpan.FromSeconds(30)) { rooms.Remove(room.Code); continue; }
        room.Members.RemoveAll(m => now - m.Seen > TimeSpan.FromSeconds(30));
    }
}
object View(Room r, Member m) => new { code = r.Code, me = m.Id, host = r.Members[0].Id, members = r.Members.Select(p => new { id = p.Id, name = p.Name, ready = p.Ready, connected = DateTimeOffset.UtcNow - p.Seen < TimeSpan.FromSeconds(5) }), reconnectSeconds = 30 };
IResult Error(string message, int code = 400) => Results.Json(new { message }, statusCode: code);
app.MapGet("/health", () => Results.Ok(new { status = "ok", version = "9.0.0", minimumVersion = Minimum() }));
app.MapPost("/lobby", (LobbyRequest q) => {
    lock (gate) {
        Sweep();
        if (!Compatible(q.Version)) return Error("Bitte aktualisiere das Spiel. Diese Version kann keine Lobby betreten.", 426);
        if ((q.Name ?? "").Trim().Length is < 1 or > 20 || (q.Name ?? "").Any(char.IsControl)) return Error("Der Name muss 1 bis 20 sichtbare Zeichen enthalten.");
        if (rooms.Count >= 1000) return Error("Der Lobby-Dienst ist ausgelastet. Bitte später erneut versuchen.", 503);
        Room room;
        if (string.IsNullOrEmpty(q.Code)) {
            string code; do { code = Convert.ToHexString(RandomNumberGenerator.GetBytes(3)); } while (rooms.ContainsKey(code));
            room = new Room(code); rooms.Add(code, room);
        } else if (!rooms.TryGetValue(q.Code.Trim().ToUpperInvariant(), out room!)) return Error("Lobby nicht gefunden oder bereits geschlossen.", 404);
        if (room.Members.Count >= 8) return Error("Diese Lobby ist voll (8/8).", 409);
        var member = new Member(q.Name!.Trim()); room.Members.Add(member);
        return Results.Json(new { token = member.Token, lobby = View(room, member) });
    }
});
app.MapPost("/lobby/{code}/session", (string code, SessionRequest q, HttpContext c) => {
    lock (gate) {
        Sweep();
        if (!Compatible(q.Version)) return Error("Update erforderlich, um die Lobby weiter zu verwenden.", 426);
        if (!rooms.TryGetValue(code, out var room)) return Error("Die Lobby wurde geschlossen oder die Wiederverbindungsfrist ist abgelaufen.", 410);
        var token = c.Request.Headers.Authorization.ToString().Replace("Bearer ", "");
        var member = room.Members.Find(m => m.Token == token);
        if (member == null) return Error("Du bist nicht mehr Mitglied dieser Lobby.", 403);
        member.Seen = DateTimeOffset.UtcNow;
        switch (q.Action) {
            case "poll": break;
            case "ready": member.Ready = q.Ready; break;
            case "leave":
                if (room.Members[0] == member) rooms.Remove(code); else room.Members.Remove(member);
                return Results.Json(new { left = true });
            case "kick":
                if (room.Members[0] != member) return Error("Nur der Host darf Spieler entfernen.", 403);
                if (q.Target == member.Id) return Error("Verwende Lobby schließen.");
                room.Members.RemoveAll(m => m.Id == q.Target); break;
            default: return Error("Unbekannte Lobby-Aktion.");
        }
        return Results.Json(View(room, member));
    }
});
// Game updates and publishing are exclusively handled by Nxxhy/PokeTactics GitHub Releases.
app.Run();
record LobbyRequest(string Name, string Code, string Version);
record SessionRequest(string Action, string Version, bool Ready = false, string Target = "");
class Room(string code) { public string Code = code; public List<Member> Members = new(); }
class Member(string name) { public string Id = Guid.NewGuid().ToString("N"); public string Token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32)); public string Name = name; public bool Ready; public DateTimeOffset Seen = DateTimeOffset.UtcNow; }
