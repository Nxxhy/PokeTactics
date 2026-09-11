extends RefCounted
# Original procedural pixel scenery, inspired by the supplied references.
static func draw_scene(c,r: Rect2,time: float):
 c.draw_rect(r,Color("6ac29e"))
 c.draw_rect(Rect2(r.position,Vector2(r.size.x,22)),Color("7bd5c2"))
 for i in range(5):
  var x = r.position.x+fposmod(i*r.size.x/5+time*1.4,r.size.x-50)
  c.draw_rect(Rect2(x,r.position.y+3+i%2*4,40,5),Color("c8eed4"))
 # Terraced rock wall: shadow, warm stone face, pale ledges, broken seams.
 for i in range(int(r.size.x/36)+1):
  var x = r.position.x+i*36
  var y = r.position.y+18+(i%3)*3
  var w = minf(36,r.end.x-x)
  c.draw_rect(Rect2(x,y,w,32),Color("715c59"))
  c.draw_rect(Rect2(x+2,y+2,maxf(1,w-3),8),Color("c4b392"))
  c.draw_rect(Rect2(x+4,y+12,maxf(1,w-7),15),Color("947a6d"))
  c.draw_line(Vector2(x+8,y+12),Vector2(x+4,y+26),Color("b09a81"),3)
  c.draw_rect(Rect2(x,y+30,w,4),Color("455d44"))
 for i in range(14):
  var x = r.position.x+22+i*(r.size.x-44)/13
  tree(c,Vector2(x,r.position.y+58),0.8 if i%2 else 1.0)
 # Scenery on the sloping margins, outside all tile polygons.
 for side in [0,1]:
  for i in range(4):
   var y = r.position.y+90+i*(r.size.y-140)/4
   var depth = (y-r.position.y-58)/(r.size.y-58)
   var margin = r.size.x*(0.12-0.11*depth)
   var x = r.position.x+margin*0.4 if side == 0 else r.end.x-margin*0.4
   if margin > 37: tree(c,Vector2(x,y),minf(1.1,margin/65))
   else:
    c.draw_rect(Rect2(x-5,y-8,10,8),Color("7b8370"))
    c.draw_rect(Rect2(x-4,y-9,7,3),Color("bdc2a0"))
 for i in range(65):
  var y = r.position.y+65+fposmod(i*41,r.size.y-70)
  var depth = (y-r.position.y-58)/(r.size.y-58)
  var margin = r.size.x*(0.12-0.11*depth)
  var x = r.position.x+3+fposmod(i*13,maxf(1,margin-9))
  if i%2: x = r.end.x-(x-r.position.x)
  var sway = roundf(sin(time*1.8+i))
  c.draw_line(Vector2(x,y),Vector2(x-2+sway,y-4),Color("308b61"),2)
  c.draw_line(Vector2(x+2,y),Vector2(x+3+sway,y-3),Color("a5d779"),2)

static func tree(c,foot: Vector2,scale_value: float):
 c.draw_ellipse_shadow(foot,Vector2(22,6)*scale_value,Color("267452"))
 c.draw_rect(Rect2(foot+Vector2(-4,-18)*scale_value,Vector2(8,18)*scale_value),Color("6b6346"))
 for layer in range(3):
  var y = -19-layer*10
  var half = 23-layer*5
  var shape = PackedVector2Array([Vector2(-half,y),Vector2(-half,y-9),Vector2(-half+7,y-9),Vector2(-half+7,y-17),Vector2(half-7,y-17),Vector2(half-7,y-9),Vector2(half,y-9),Vector2(half,y)])
  for j in range(shape.size()): shape[j]=(foot+shape[j]*scale_value).round()
  c.draw_colored_polygon(shape,Color("327b3e") if layer == 0 else Color("4b9e49"))
  for j in range(5):
   var at = foot+Vector2(-half+5+j*(half*2-10)/5,y-8-(j%2)*5)*scale_value
   c.draw_rect(Rect2(at.round(),Vector2(5,4)*scale_value),Color("8ccd62") if j%2 else Color("65b954"))
