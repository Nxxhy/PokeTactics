extends RefCounted
# One-use handoff prevents accidental direct launches. This is not DRM against modified clients.
static func consume_ticket(path: String, version: String, now: float) -> bool:
 if path.is_empty() or not FileAccess.file_exists(path): return false
 var ticket = JSON.parse_string(FileAccess.get_file_as_string(path))
 DirAccess.remove_absolute(path)
 if not ticket is Dictionary: return false
 var expires = float(ticket.get("expires",0))
 return str(ticket.get("version","")) == version and expires >= now and expires <= now + 35

static func admit() -> bool:
 var executable = OS.get_executable_path()
 # Source development and standalone test scripts do not use the installed game executable.
 if executable.get_file().to_lower() != "poketactics.exe": return true
 var directory = executable.get_base_dir()
 var build = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("build.json"))) if FileAccess.file_exists(directory.path_join("build.json")) else null
 if build is Dictionary and consume_ticket(OS.get_environment("POKE_LAUNCH_TICKET"),str(build.get("version","")),Time.get_unix_time_from_system()):
  OS.set_environment("POKE_LAUNCH_TICKET","")
  return true
 var launcher = directory.path_join("PokeLauncher.exe")
 if FileAccess.file_exists(launcher):
  var home = directory.get_base_dir().get_base_dir() if directory.get_base_dir().get_file() == "versions" else directory
  OS.create_process(launcher,["--home",home])
 else:
  OS.alert("Bitte das aktuelle Setup installieren und das Spiel über den Launcher starten. Eine Online-Versionsprüfung ist erforderlich.","Poké Tactics · Launcher erforderlich")
 return false
