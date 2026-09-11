extends SceneTree

func _init():
 var packer = PCKPacker.new()
 DirAccess.make_dir_recursive_absolute("res://dist/PokeTactics")
 var error = packer.pck_start("res://dist/PokeTactics/PokeTactics.pck")
 if error != OK:
  push_error("Cannot create pack: %d" % error)
  quit(1)
  return
 var files = ["project.godot","ui/main.tscn","ui/main.gd","ui/shell.gd","ui/ability_fx.gd","ui/animation_preview.gd","ui/animation_preview.tscn","data/ability_animations.json","assets/showdown/manifest.json","core/catalog.gd","core/match.gd","core/battle.gd","core/augments.gd","data/roster.json","data/augments.json","data/form_names.json","data/species_gen1_3.json","data/type_chart.json","assets/fonts/VT323-Regular.ttf"]
 for filename in DirAccess.get_files_at("res://assets/showdown"):
  if filename.ends_with(".png"): files.append("assets/showdown/"+filename)
 for filename in DirAccess.get_files_at("res://assets/pokemon"):
  if filename.ends_with(".png"):
   files.append("assets/pokemon/"+filename)
 files.append_array(["core/difficulty.gd","assets/fonts/AtkinsonHyperlegible-Regular.ttf","assets/fonts/PixelifySans.ttf"])
 files.append_array(["core/traits.gd","data/traits.json","data/roster-v7-backup.json"])
 files.append("assets/fonts/pkmnem.ttf")
 files.append("ui/launch_gate.gd")
 files.append("assets/fonts/pkmnemn.ttf")
 files.append_array(["ui/forest.gd","ui/forest_layer.gd","assets/animated/manifest.json"])
 for filename in DirAccess.get_files_at("res://assets/animated"):
  if filename.ends_with(".png"): files.append("assets/animated/"+filename)
 for path in files:
  error = packer.add_file("res://"+path,"res://"+path)
  if error != OK:
   push_error("Cannot pack " + path)
   quit(1)
   return
 error = packer.flush()
 print("Packed %d files; result %d" % [files.size(),error])
 quit(0 if error == OK else 1)
