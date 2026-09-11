extends CanvasLayer
# Menus own input; only preferences persist. Lobby state always belongs to the server.
const VERSION = "9.0.0"
var game_ui
var root: Control
var body: VBoxContainer
var screen = "main"
var settings = ConfigFile.new()
var player_name = "Trainer"
var service = ""
var version = VERSION
var token = ""
var room: Dictionary = {}
var http: HTTPRequest
var pending = ""
var poll_time = 0.0
var last_success = 0.0
var status: Label
var name_input: LineEdit
var code_input: LineEdit
var notice = ""
var leave_target = "main"
var was_paused = false

func _ready():
 game_ui = get_parent()
 layer = 20
 settings.load("user://settings.cfg")
 player_name = str(settings.get_value("player","name","Trainer"))
 AudioServer.set_bus_volume_db(0,linear_to_db(float(settings.get_value("audio","volume",0.8))))
 if not bool(settings.get_value("display","fullscreen",true)):
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
 service = OS.get_environment("POKE_SERVICE").trim_suffix("/")
 var config_path = OS.get_executable_path().get_base_dir().path_join("service.json")
 if FileAccess.file_exists(config_path):
  var config = JSON.parse_string(FileAccess.get_file_as_string(config_path))
  if config is Dictionary: service = str(config.get("endpoint",service)).trim_suffix("/")
 var build_path = OS.get_executable_path().get_base_dir().path_join("build.json")
 if FileAccess.file_exists(build_path):
  var build = JSON.parse_string(FileAccess.get_file_as_string(build_path))
  if build is Dictionary: version = str(build.get("version",VERSION))
 http = HTTPRequest.new()
 http.timeout = 5
 add_child(http)
 http.request_completed.connect(_response)
 get_tree().auto_accept_quit = false
 show_screen("main")

func _process(delta):
 if not token.is_empty():
  poll_time += delta
  if poll_time >= 1 and pending.is_empty():
   poll_time = 0
   request("poll")
  if status and is_instance_valid(status) and Time.get_ticks_msec()-last_success > 5000:
   status.text = "Verbindung unterbrochen – erneuter Versuch läuft (max. 30 Sekunden)."

func _notification(what):
 if what == NOTIFICATION_WM_CLOSE_REQUEST: leave_game(true)

func _input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_F11 and screen != "game":
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
  if event.keycode == KEY_ESCAPE:
   if screen == "game": leave_game(false)
   elif screen not in ["main","lobby","confirm"]: show_screen("main")
   get_viewport().set_input_as_handled()

func style(background: Color) -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = background
 s.border_color = Color("384848")
 s.set_border_width_all(3)
 s.set_content_margin_all(12)
 return s

func show_screen(which: String):
 screen = which
 game_ui.set_process_input(which == "game")
 if is_instance_valid(root):
  remove_child(root)
  root.queue_free()
  root = null
 if which == "game": return
 game_ui._cancel_drag()
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_STOP
 root.theme = game_ui.theme.duplicate()
 root.theme.default_font_size = 24
 for kind in ["Button","LineEdit","OptionButton"]:
  root.theme.set_stylebox("normal",kind,style(Color("f8f8e8")))
  root.theme.set_stylebox("hover",kind,style(Color("c8e8a0")))
  root.theme.set_stylebox("pressed",kind,style(Color("88c898")))
  root.theme.set_stylebox("focus",kind,style(Color("d8e8b0")))
  root.theme.set_color("font_color",kind,Color("384848"))
  root.theme.set_color("font_hover_color",kind,Color("203830"))
  root.theme.set_color("font_pressed_color",kind,Color("203830"))
 root.theme.set_color("font_color","Label",Color("384848"))
 add_child(root)
 var shade = ColorRect.new()
 shade.color = Color(0.08,0.20,0.16,0.94 if which != "result" else 0.8)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(shade)
 var margin = MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge, maxi(24,int(game_ui.size.x*0.18)))
 for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,maxi(24,int((game_ui.size.y-620)/2)) if which in ["main","difficulty","result","confirm"] else 24)
 root.add_child(margin)
 var panel = PanelContainer.new()
 panel.add_theme_stylebox_override("panel",style(Color("e8f0c8")))
 margin.add_child(panel)
 var scroll = ScrollContainer.new()
 panel.add_child(scroll)
 body = VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",10)
 scroll.add_child(body)
 label("POKÉ TACTICS",36)
 match which:
  "main":
   leave_target = "main"
   label("EXPEDITIONEN & TRAINER-LOBBYS · "+version)
   if not notice.is_empty(): label(notice)
   button("Expedition starten",func(): show_screen("difficulty"))
   button("Lobby erstellen",func(): show_screen("create"))
   button("Lobby beitreten",func(): show_screen("join"))
   button("Einstellungen",func(): show_screen("settings"))
   button("Spiel beenden",func(): get_tree().quit())
   label("Expeditionen werden nicht gespeichert. F11: Vollbild",20)
  "difficulty":
   label("Wähle deine Herausforderung")
   for difficulty in ["Leicht","Normal","Schwer"]:
    button(difficulty,func(): game_ui.chosen_difficulty = difficulty; game_ui._new_game(); show_screen("game"))
   button("Zurück",func(): show_screen("main"))
  "create", "join":
   label("Anzeigename (max. 20 Zeichen)")
   name_input = LineEdit.new()
   name_input.max_length = 20
   name_input.text = player_name
   body.add_child(name_input)
   if which == "join":
    label("Lobby-Code")
    code_input = LineEdit.new()
    code_input.max_length = 6
    code_input.placeholder_text = "ABC123"
    body.add_child(code_input)
   status = label("Noch kein öffentlicher Server eingerichtet." if service.is_empty() else "Bereit zur Verbindung.")
   button("Erstellen" if which == "create" else "Beitreten",func():
    player_name = name_input.text.strip_edges()
    save_settings()
    request("create" if screen == "create" else "join"))
   button("Zurück",func(): http.cancel_request(); pending = ""; show_screen("main"))
  "lobby":
   label("LOBBY "+str(room.get("code","")),30)
   button("Code kopieren",func(): DisplayServer.clipboard_set(str(room.code)))
   var members = room.get("members",[])
   for i in range(8):
    var row = HBoxContainer.new()
    body.add_child(row)
    var item = Label.new()
    item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    row.add_child(item)
    if i < members.size():
     var m = members[i]
     item.text = "%d. %s%s · %s · %s" % [i+1,m.name," [HOST]" if m.id == room.host else "","Verbunden" if m.connected else "Verbindung verloren","BEREIT" if m.ready else "Nicht bereit"]
     if m.ready: item.add_theme_color_override("font_color",Color("286038"))
     if room.me == room.host and m.id != room.me:
      var kick = Button.new()
      kick.text = "Entfernen"
      kick.pressed.connect(func(): request("kick",{"target":m.id}))
      row.add_child(kick)
    else: item.text = "%d. Freier Platz" % (i+1)
   var me_ready = false
   for m in members:
    if m.id == room.me: me_ready = m.ready
   button("Nicht bereit" if me_ready else "Bereit",func(): request("ready",{"ready":not me_ready}))
   var start = button("Multiplayer starten",func(): pass)
   start.disabled = true
   label("Multiplayer-Partien folgen in einem späteren Update",20)
   status = label("Verbunden · Wiederverbindungsfrist: 30 Sekunden",20)
   button("Lobby schließen" if room.me == room.host else "Lobby verlassen",func(): request("leave"))
  "settings":
   label("Spielername")
   name_input = LineEdit.new()
   name_input.text = player_name
   name_input.max_length = 20
   body.add_child(name_input)
   var full = CheckButton.new()
   full.text = "Vollbild"
   full.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
   body.add_child(full)
   full.toggled.connect(func(value): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED); settings.set_value("display","fullscreen",value))
   label("Gesamtlautstärke")
   var volume = HSlider.new()
   volume.max_value = 1.0
   volume.step = 0.05
   volume.value = float(settings.get_value("audio","volume",0.8))
   body.add_child(volume)
   volume.value_changed.connect(func(value): AudioServer.set_bus_volume_db(0,linear_to_db(value)); settings.set_value("audio","volume",value))
   button("Speichern und zurück",func(): player_name = name_input.text.strip_edges(); save_settings(); show_screen("main"))
  "confirm":
   label("Expedition verlassen?",30)
   label("Der gesamte Fortschritt dieser Expedition geht verloren.")
   button("Expedition fortsetzen",func(): game_ui.paused = was_paused; show_screen("game"))
   button("Verlassen",func(): game_ui.playback = {}; game_ui.effects.clear(); game_ui.paused = false; get_tree().quit() if leave_target == "quit" else show_screen("main"))
  "result":
   label("Expedition gewonnen" if int(game_ui.game.state.lives) > 0 else "Expedition gescheitert",36)
   label("Erreichte Runde: %d / 30 · Siege: %d" % [mini(30,int(game_ui.game.state.round)),int(game_ui.game.state.wins)])
   var team: Array[String] = []
   for u in game_ui.game.state.units:
    team.append(game_ui.catalog.display_name(u)+" · "+str(u.star)+" Sterne")
   label("Dein Team: "+", ".join(team))
   button("Neue Expedition",func(): show_screen("difficulty"))
   button("Zurück zum Hauptmenü",func(): show_screen("main"))
 root.modulate.a = 0.0
 create_tween().tween_property(root,"modulate:a",1.0,0.16)

func label(text: String, font_size: int = 24) -> Label:
 var item = Label.new()
 item.text = text
 item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 item.add_theme_font_size_override("font_size",font_size)
 body.add_child(item)
 return item

func button(text: String, action: Callable) -> Button:
 var item = Button.new()
 item.text = text
 item.custom_minimum_size.y = 46
 item.pressed.connect(action)
 body.add_child(item)
 return item

func save_settings():
 settings.set_value("player","name",player_name)
 settings.save("user://settings.cfg")

func leave_game(quit_app: bool):
 leave_target = "quit" if quit_app else "main"
 if screen == "game" and game_ui.game.state.phase != "finished":
  was_paused = game_ui.paused
  game_ui.paused = true
  show_screen("confirm")
 elif not token.is_empty():
  request("leave")
 elif quit_app: get_tree().quit()
 elif screen == "game":
  game_ui.playback = {}
  game_ui.effects.clear()
  show_screen("main")

func request(action: String, extra: Dictionary = {}):
 if not pending.is_empty(): return
 if service.is_empty():
  status.text = "Noch kein Hosting eingerichtet. Einzelspieler ist vollständig verfügbar."
  return
 if not service.begins_with("https://") and not service.begins_with("http://127.0.0.1:"):
  status.text = "Der Lobby-Dienst benötigt HTTPS."
  return
 var path = "/lobby"
 var headers = PackedStringArray(["Content-Type: application/json"])
 var payload = {"version":version,"name":player_name,"code":""}
 if action == "join": payload.code = code_input.text.strip_edges().to_upper()
 if action not in ["create","join"]:
  path += "/"+str(room.code)+"/session"
  headers.append("Authorization: Bearer "+token)
  payload = {"version":version,"action":action}
  payload.merge(extra)
 pending = action
 if http.request(service+path,headers,HTTPClient.METHOD_POST,JSON.stringify(payload)) != OK:
  pending = ""
  status.text = "Verbindung fehlgeschlagen. Bitte erneut versuchen."

func _response(result, response_code, _headers, bytes):
 var action = pending
 pending = ""
 var data = JSON.parse_string(bytes.get_string_from_utf8())
 if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400 or not data is Dictionary:
  var error = str(data.get("message","Verbindung fehlgeschlagen. Bitte erneut versuchen.")) if data is Dictionary else "Verbindung fehlgeschlagen. Bitte erneut versuchen."
  if is_instance_valid(status): status.text = error
  if action == "leave" or response_code in [403,410,426] or (not token.is_empty() and Time.get_ticks_msec()-last_success > 30000):
   token = ""
   room = {}
   notice = error
   if action == "leave" and leave_target == "quit": get_tree().quit()
   else: show_screen("main")
  return
 last_success = Time.get_ticks_msec()
 if action == "leave":
  token = ""
  room = {}
  if leave_target == "quit": get_tree().quit()
  else: show_screen("main")
  return
 if action in ["create","join"]:
  token = data.token
  room = data.lobby
  show_screen("lobby")
 elif room != data:
  room = data
  show_screen("lobby")
 elif is_instance_valid(status): status.text = "Verbunden · Wiederverbindungsfrist: 30 Sekunden"
