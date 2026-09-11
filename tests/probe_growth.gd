extends SceneTree
func _init():
 var c=preload("res://core/catalog.gd").new()
 var team=[]
 for m in c.roster:
  if "Pflanze" in c.combat_types({"species":m.id,"star":3}):team.append({"uid":team.size()+1,"species":m.id,"star":3,"slot":team.size(),"zone":"board"})
 var aug=preload("res://core/augments.gd").new().all.filter(func(a):return a.get("emblem","")=="Pflanze")[0].id
 var result=preload("res://core/battle.gd").new().run(team,team,100,[aug])
 var growth=0
 for frame in result.frames:
  for u in frame.units:growth=maxi(growth,u.growth)
 print("Growth live battle: ",result.ticks," ticks; stacks ",growth," units ",team.size())
 quit()
