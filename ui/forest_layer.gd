extends Control
func _draw():
 preload("res://ui/forest.gd").draw_scene(self,Rect2(Vector2.ZERO,size),0)
func draw_ellipse_shadow(at: Vector2,radius: Vector2,color: Color):
 var points = PackedVector2Array()
 for i in range(12): points.append((at+Vector2(cos(i*TAU/12)*radius.x,sin(i*TAU/12)*radius.y)).round())
 draw_colored_polygon(points,color)
