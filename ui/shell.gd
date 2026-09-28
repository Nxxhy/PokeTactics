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
var network_match = false
var match_state: Dictionary = {}
var seen_battle = 0
var command_seq = 0
var network_action: Dictionary = {}
var network_before: Array = []
var ack_pending = false

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
 if service.is_empty() and FileAccess.file_exists(config_path):
  var config = JSON.parse_string(FileAccess.get_file_as_string(config_path))
  if config is Dictionary: service = str(config.get("endpoint",service)).trim_suffix("/")
 var build_path = OS.get_executable_path().get_base_dir().path_join("build.json")
 if FileAccess.file_exists(build_path):
  var build = JSON.parse_string(FileAccess.get_file_as_string(build_path))
  if build is Dictionary: version = str(build.get("version",VERSION))
 http = HTTPRequest.new()
 http.timeout = 30
 add_child(http)
 http.request_completed.connect(_response)
 get_tree().auto_accept_quit = false
 show_screen("main")

func _process(delta):
 if not token.is_empty():
  poll_time += delta
  if poll_time >= 1 and pending.is_empty():
   poll_time = 0
   request("battle_ack" if ack_pending else "poll")
  if status and is_instance_valid(status) and Time.get_ticks_msec()-last_success > 5000:
   status.text = "Verbindung unterbrochen – erneuter Versuch läuft (max. 30 Sekunden)."
  if network_match and Time.get_ticks_msec()-last_success > 5000:
   game_ui.message = "Verbindung zum Host unterbrochen. Befehle sind bis zur Wiederverbindung gesperrt."

func _notification(what):
 if what == NOTIFICATION_WM_CLOSE_REQUEST: leave_game(true)

func _input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_F11 and screen != "game":
   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
  if event.keycode == KEY_ESCAPE:
   if network_match:
    if screen == "game": leave_game(false)
    elif screen == "multiplayer_leave": leave_target = "main"; show_screen("standings")
    elif match_state.get("phase","") == "finished": show_screen("multiplayer_result")
    else: show_screen("game")
    get_viewport().set_input_as_handled()
    return
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
   status = label("Bitte im Launcher einen lokalen Host oder Lobby-Dienst wählen." if service.is_empty() else "Lobby-Dienst: "+service)
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
   var start = button("Multiplayer starten",func(): request("start"))
   start.disabled = room.me != room.host or members.size() < 2 or not members.all(func(m): return m.ready and m.connected)
   label("2–8 Trainer · 3 Leben · alle bereit → Host startet",20)
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
  "standings", "multiplayer_result":
   label("PARTIE BEENDET" if which == "multiplayer_result" else "TRAINER-STAND · KAMPF %d" % int(match_state.get("stage",1)),30)
   if which == "multiplayer_result":
    var winner_name = "Unentschieden"
    for entry in match_state.get("scores",[]):
     if entry.id == match_state.get("champion",""): winner_name = entry.name+" gewinnt!"
    label(winner_name,28)
   for entry in match_state.get("scores",[]):
    label("%s · %d Leben · %d Siege%s" % [entry.name,int(entry.lives),int(entry.wins)," · ausgeschieden" if entry.lives <= 0 else (" · bereit" if entry.ready else "")])
   if which != "multiplayer_result": button("Zurück zum Spielfeld",func(): show_screen("game"))
   button("Partie verlassen" if room.me != room.host else "Partie für alle schließen",func(): show_screen("multiplayer_leave"))
   status = label("Ausgeschiedene Trainer können den Stand bis zum Ende verfolgen.",18)
  "multiplayer_leave":
   label("Multiplayer-Partie verlassen?",30)
   label("Als Host beendest du die Partie für alle Trainer." if room.me == room.host else "Dein Team scheidet aus. Ein erneuter Beitritt ist während der Partie nicht möglich.")
   button("Zurück",func(): leave_target = "main"; show_screen("standings"))
   button("Verlassen",func(): request("leave"))
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
 if network_match:
  show_screen("multiplayer_leave" if quit_app else ("multiplayer_result" if match_state.get("phase","") == "finished" else "standings"))
  return
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
  status.text = "Bitte im Launcher unter LAN-LOBBY einen Server starten oder die Host-Adresse wählen. Danach das Spiel neu starten."
  return
 if not preload("res://core/lobby_endpoint.gd").allowed(service):
  status.text = "HTTP ist nur für private IPv4-Adressen im Heimnetz erlaubt. Online-Dienste benötigen HTTPS."
  return
 var path = "/lobby"
 var headers = PackedStringArray(["Content-Type: application/json"])
 var payload = {"version":version,"name":player_name,"code":""}
 if action == "join": payload.code = code_input.text.strip_edges().to_upper()
 if action not in ["create","join"]:
  path += "/"+str(room.code)+"/session"
  headers.append("Authorization: Bearer "+token)
  payload = {"version":version,"action":action,"seen":seen_battle,"stage":int(match_state.get("stage",0))}
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
   network_match = false
   match_state = {}
   game_ui.playback = {}
   game_ui.effects.clear()
   notice = error
   if action == "leave" and leave_target == "quit": get_tree().quit()
   else: show_screen("main")
  return
 last_success = Time.get_ticks_msec()
 if action == "leave":
  token = ""
  room = {}
  network_match = false
  match_state = {}
  game_ui.playback = {}
  game_ui.effects.clear()
  if leave_target == "quit": get_tree().quit()
  else: show_screen("main")
  return
 if action in ["create","join"]:
  seen_battle = 0
  command_seq = 0
  ack_pending = false
  token = data.token
  room = data.lobby
  show_screen("lobby")
 elif data.get("match_state") is Dictionary:
  room = data
  apply_network(data.match_state,data.get("result"),action)
 elif room != data:
  room = data
  show_screen("lobby")
 elif is_instance_valid(status): status.text = "Verbunden · Wiederverbindungsfrist: 30 Sekunden"

func send_command(action: Dictionary, revision: int) -> Dictionary:
 if not pending.is_empty() or Time.get_ticks_msec()-last_success > 5000:
  return {"ok":false,"message":"Warte auf die Bestätigung des Hosts."}
 if match_state.get("phase","") != "planning" or match_state.get("ready",false) or game_ui.game.state.lives <= 0:
  return {"ok":false,"message":"Die Aufstellung ist bis zur nächsten Planung gesperrt."}
 if action.type == "battle":
  request("round_ready")
 else:
  command_seq += 1
  network_action = action.duplicate(true)
  network_before = game_ui.game.state.units.duplicate(true)
  request("command",{"command":action,"revision":revision,"seq":command_seq})
 return {"ok":true,"message":"Anfrage an den Host gesendet …"}

func apply_network(data: Dictionary, result, action: String):
 var first = not network_match
 var scores_changed = match_state.get("scores",[]) != data.scores or match_state.get("stage",0) != data.stage
 network_match = true
 match_state = data
 game_ui.game.state = data.state
 game_ui.game.rng.state = int(data.state.get("rng_state","0"))
 if action == "battle_ack": ack_pending = false
 if first:
  game_ui.playback = {}
  game_ui.effects.clear()
  game_ui.game.last_battle = {}
  game_ui.start_open = false
  game_ui.reset_open = false
  game_ui.help_open = false
  show_screen("game")
 if action == "command" and result is Dictionary:
  if result.get("ok",false): game_ui._action_effects(network_action,network_before)
  game_ui.message = result.get("message","")
  game_ui.message_error = not result.get("ok",false)
  network_action = {}
 else:
  var ready_count = data.scores.filter(func(s): return s.lives > 0 and s.ready).size()
  game_ui.message = "Multiplayer · Kampf %d · %s · %d bereit · %ds" % [int(data.stage),"Kampf läuft" if data.phase == "battle" else "Aufstellen und bereit melden",ready_count,maxi(0,int(data.deadline-Time.get_unix_time_from_system()))]
  game_ui.message_error = false
  if result is Dictionary and not result.get("ok",true):
   game_ui.message = result.get("message","")
   game_ui.message_error = true
 if data.has("recipe") and int(data.recipe.serial) > seen_battle:
  seen_battle = int(data.recipe.serial)
  game_ui.game.last_battle = preload("res://core/league.gd").replay(data.recipe)
  game_ui._replay()
  if screen != "multiplayer_leave": show_screen("game")
 elif game_ui.playback.is_empty():
  if screen != "multiplayer_leave":
   if data.phase == "finished" and (screen != "multiplayer_result" or scores_changed): show_screen("multiplayer_result")
   elif data.phase != "finished" and game_ui.game.state.lives <= 0 and (screen != "standings" or scores_changed): show_screen("standings")
   elif screen == "standings" and scores_changed: show_screen("standings")
 game_ui.queue_redraw()

func battle_finished():
 ack_pending = true
 if pending.is_empty(): request("battle_ack")
 if screen == "multiplayer_leave": return
 if match_state.get("phase","") == "finished": show_screen("multiplayer_result")
 elif game_ui.game.state.lives <= 0: show_screen("standings")
