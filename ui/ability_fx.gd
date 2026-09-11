extends RefCounted
# Adapted choreography concepts from Showdown CC0 move animations. No web runtime.
var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ability_animations.json"))
var textures: Dictionary = {}
var triggered: Dictionary = {}

func _init():
 for row in JSON.parse_string(FileAccess.get_file_as_string("res://assets/showdown/manifest.json")):
  var image = Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/showdown/"+row.name+".png")) == OK:
   textures[row.name] = ImageTexture.create_from_image(image)

func recipe(event: Dictionary) -> Dictionary:
 return recipes.get(str(int(event.species)),{})

func stamp(ui, asset: String, point: Vector2, extent: float, color: Color):
 # Quantized positions and nearest sampling retain the low-resolution sprite aesthetic.
 var p = (point/2).round()*2
 if textures.has(asset):
  var texture = textures[asset]
  var dimensions = texture.get_size()
  var size = (dimensions*(extent/maxf(dimensions.x,dimensions.y))).round()
  ui.draw_texture_rect(texture,Rect2(p-size/2,size),false,color)
 else:
  ui.draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),color)

func draw(ui,e: Dictionary,t: float):
 var event = e.event
 var r = recipe(event)
 if r.is_empty(): return
 var key = str(int(event.species))+":"+event.spell
 triggered[key] = int(triggered.get(key,0))+1
 var color = Color(r.color,clampf((1-t)*2,0,1))
 var white = Color(1,1,1,color.a)
 var a: Vector2 = e.a
 var b: Vector2 = e.b
 var star = int(event.get("source_star",1))
 var scale = 1.0+0.12*(star-1)
 var n = int(r.count)+star-1
 var pattern = r.pattern
 var charge = e.kind == "cast"
 var center = a if charge else b
 var phase = t*TAU
 # Every recipe has a deliberate silhouette, path and asset pairing.
 if charge:
  ui._ring(a,10+int(t*9),color)
  var destinations = event.get("targets",[{"x":event.tx,"y":event.ty}])
  for target in destinations:
   var destination = ui._sprite_area(ui.world_rect(Vector2(target.x,target.y))).get_center()
   var bolt = a.lerp(destination,t)
   if pattern in ["seed","volley","meteor","throw","pollen"]: bolt.y -= sin(t*PI)*22
   elif pattern in ["vine","web","chain","magnet"]:
    ui.draw_line(a,bolt,color,2,false)
   elif pattern in ["jump","hunt","dive","ram"]:
    stamp(ui,r.accent,a.lerp(destination,t*0.7),18*scale,Color(1,1,1,white.a*0.4))
   stamp(ui,r.asset,bolt,14*scale,white)
 else:
  match pattern:
   "seed","vine","garden","pollen":
    for i in range(n):
     var angle = i*TAU/n+phase*0.2
     var p = center+Vector2(cos(angle)*(8+16*t),sin(angle)*9-12*t)
     ui.draw_line(center+Vector2(0,9),p,color,2,false)
     stamp(ui,r.asset,p,14*scale,white)
   "embers","lava","volcano","phoenix","hellbite":
    for i in range(n):
     var p = center+Vector2((i-(n-1)/2.0)*5,-t*(12+i%3*6))
     if pattern == "phoenix": p.x = sin(i*TAU/n)*t*24
     if pattern == "lava": p = center+Vector2(cos(i*TAU/n+phase)*18,sin(i*TAU/n+phase)*7)
     stamp(ui,r.asset,p,(16+(i%2)*6)*scale,white)
   "wave","rings","voice","aurora","surf","lantern":
    for i in range(n):
     var radius = 5+int(fmod(t*22+i*6,26))
     var origin = center+Vector2((i%2*2-1)*4,0) if pattern == "lantern" else center
     ui.draw_ellipse_shadow(origin,Vector2(radius,radius*(0.35 if pattern in ["wave","surf"] else 0.65)),Color(color,color.a*0.22))
     stamp(ui,r.asset,origin+Vector2(cos(i+phase)*radius,sin(i+phase)*radius*0.4),11*scale,white)
   "pulse","vortex","eclipse","nightmare","fog","curse","mist","luster":
    for i in range(n):
     var angle = i*TAU/n+phase*(1 if pattern in ["vortex","curse"] else -0.4)
     var radius = 6+18*(1-t if pattern in ["eclipse","nightmare"] else t)
     stamp(ui,r.asset,center+Vector2(cos(angle)*radius,sin(angle)*radius*0.55),16*scale,white)
    if pattern in ["pulse","luster"]: ui._cross(center,8+int(t*13),color)
   "rampart","mirror","shell","family","gem","magnet","iron":
    var radius = 12+int(t*10)
    if pattern == "mirror": ui.draw_rect(Rect2(center-Vector2(15,18),Vector2(30,36)),color,false,3)
    elif pattern == "gem": ui.draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]),color,3,false)
    else: ui._ring(center,radius,color)
    for i in range(n): stamp(ui,r.asset,center+Vector2(cos(i*TAU/n)*radius,sin(i*TAU/n)*radius*0.65),13*scale,white)
   "bite","jaw":
    var gap = 4+absf(cos(t*PI))*14
    stamp(ui,r.asset,center-Vector2(0,gap),30*scale,white)
    stamp(ui,r.accent,center+Vector2(0,gap),30*scale,white)
    if pattern == "jaw": ui._ring(center,8+int(t*12),color)
   "kick","chop","punch","ram","zen","horn","tumble","tail","throw":
    for i in range(n):
     var step = clampf(t*n-i,0,1)
     if step <= 0: continue
     var offset = Vector2((i%2*2-1)*sin(step*PI)*14,-sin(step*PI)*8)
     if pattern == "throw": offset = Vector2(cos(phase),sin(phase))*14*(1-t)
     if pattern == "tail": offset = Vector2(sin(phase)*22,cos(phase)*4)
     stamp(ui,r.asset,center+offset,(24 if pattern != "horn" else 34)*scale,white)
   "cross","claw","crescent","wings","phantom","dive":
    for i in range(n):
     var p = center+Vector2((i-(n-1)/2.0)*8,0)
     if pattern == "wings": p = center+Vector2((i%2*2-1)*(8+t*18),-6)
     if pattern == "dive": p.y -= (1-t)*22
     stamp(ui,r.asset if i%2==0 else r.accent,p,30*scale,white)
    if pattern == "cross": ui.draw_line(center+Vector2(-18,-12),center+Vector2(18,12),color,3,false)
   "chain","storm","jump","hunt":
    var points = PackedVector2Array()
    for i in range(7): points.append(center+Vector2((-1 if i%2 else 1)*(4+i%3*3),-25+i*7))
    ui.draw_polyline(points,Color("484850",color.a),6,false)
    ui.draw_polyline(points,color,3,false)
    if pattern == "storm": stamp(ui,r.accent,center+Vector2(0,-17),25*scale,white)
    else: stamp(ui,r.asset,center,17*scale,white)
   "rain","snow","blizzard","sand","frost":
    for i in range(n):
     var p = center+Vector2((i-(n-1)/2.0)*6,fmod(t*28+i*9,32)-22)
     if pattern in ["blizzard","sand"]: p.x += sin(phase+i)*8
     stamp(ui,r.asset,p,(9 if pattern == "rain" else 13)*scale,white)
   "moon","star","sleep","song","sky":
    for i in range(n):
     var p = center+Vector2(sin(i*TAU/n+phase)*18,-t*18+cos(i*TAU/n)*7)
     if pattern == "sleep": ui._label("z",Rect2(p,Vector2(12,15)),12,color)
     elif pattern == "star": ui._pixel_star(p,color)
     else: stamp(ui,r.asset,p,14*scale,white)
   "quake","spikes","rift":
    for i in range(n):
     var p = center+Vector2((i-(n-1)/2.0)*7,12-sin(t*PI)*14)
     stamp(ui,r.asset,p,15*scale,white)
     if pattern == "rift": ui.draw_line(p,p+Vector2(3,-12*t),color,3,false)
   "wheel","web","volley","beam","meteor","zenith":
    for i in range(n):
     var p = center+Vector2(cos(i*TAU/n+phase)*18,sin(i*TAU/n+phase)*13)
     if pattern == "meteor": p = center+Vector2((i-(n-1)/2.0)*7,-(1-t)*25)
     elif pattern in ["beam","volley"]: p = center+Vector2((1-t)*(-20+i*5),sin(i)*6)
     elif pattern == "web": ui.draw_line(center,p,color,2,false)
     stamp(ui,r.asset,p,16*scale,white)
    if pattern == "zenith": ui._ring(center,8+int(t*18),color)
  # The secondary component communicates the *actual* resolved effect, not just type.
  var effect = event.get("effect","")
  if effect in ["heal","cleanse"]: ui._cross(center+Vector2(0,-12*t),7,Color("88e8a0",color.a))
  elif effect == "shield": ui._ring(center,14+int(t*5),Color("a8d8ff",color.a))
  elif effect in ["stun","slow","freeze"]: stamp(ui,r.accent,center+Vector2(0,-16),16,white)
  else: stamp(ui,r.accent,center,10*scale,Color(1,1,1,white.a*0.8))
 if star == 3:
  ui._ring(center,22,Color("e8c868",color.a*0.75))
  ui._pixel_star(center+Vector2(0,-23),Color("e8c868",color.a))
 if event.get("overloaded",false):
  ui._ring(center,14+int(t*12),Color("e8a8ff",color.a))
  ui._ring(center,18+int(t*12),Color("e8a8ff",color.a*0.6))
