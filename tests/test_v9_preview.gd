extends SceneTree
func _init(): call_deferred("run")
func run():
 root.size=Vector2i(1280,720)
 var preview=load("res://ui/animation_preview.tscn").instantiate()
 root.add_child(preview)
 for i in range(4): await process_frame
 var checked=0
 for index in range(70):
  for star in [1,2,3]:
   preview.roster_index=index
   preview.preview_star=star
   preview.preview()
   assert(not preview.playback.is_empty(),"Preview must initialize battle")
   assert(preview.playback.frames[0].units[0].species==preview.catalog.roster[index].id)
   assert(preview.playback.frames[0].units[0].star==star)
   checked+=1
 await process_frame
 print("ANIMATION PREVIEW: %d variants initialized without errors" % checked)
 quit()
