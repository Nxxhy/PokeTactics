extends SceneTree
var ui
var shell
var passed=0
var failed=0
func _init(): call_deferred("run")
func check(ok,label):
 if ok: passed+=1
 else: failed+=1;printerr("FAIL MENU: "+label)
func run():
 root.size=Vector2i(1280,720)
 ui=load("res://ui/main.tscn").instantiate()
 ui.save_path="res://tests/v9-never-save.json"
 root.add_child(ui)
 await process_frame
 shell=load("res://ui/shell.gd").new()
 ui.shell=shell
 ui.add_child(shell)
 await process_frame
 check(shell.screen=="main" and not ui.is_processing_input(),"Main menu captures input on startup")
 check(not ui.has_method("_save") and not ui.game.has_method("restore"),"No save/restore functionality")
 for dims in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=dims
  for screen in ["main","difficulty","create","join","settings","result","confirm"]:
   shell.show_screen(screen)
   await process_frame;await process_frame
   for child in shell.body.get_children():
    check(child.size.x<=shell.body.size.x+1,"Control width fits "+screen+str(dims))
    if child is Label: check(child.get_minimum_size().y<=child.size.y+1,"Wrapped label height "+screen)
  shell.room={"code":"ABC123","me":"1","host":"1","members":[]}
  for i in range(8):shell.room.members.append({"id":str(i+1),"name":"GlurakTrainer12345678","ready":i%2==0,"connected":i!=7})
  shell.show_screen("lobby")
  await process_frame;await process_frame
  check(shell.body.get_child_count()>=15,"Eight lobby slots plus controls")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v9-lobby-%d.png"%dims.x)
 shell.room={};shell.token=""
 shell.show_screen("game")
 ui._new_game()
 var round_before=ui.game.state.round
 ui.game._settle(1)
 check(ui.game.state.round==round_before and ui.game.state.lives==2,"Round defeat costs one life and repeats round")
 ui._finish_playback()
 check(shell.screen=="game","Round loss is not final defeat")
 shell.leave_game(false)
 check(shell.screen=="confirm","Leaving expedition requires progress warning")
 shell.show_screen("game")
 ui.game.state.lives=1
 ui.game._settle(1)
 ui._finish_playback()
 check(shell.screen=="result" and ui.game.state.phase=="finished","Final defeat opens central result screen")
 var before=ui.game.snapshot()
 check(not ui.game.command({"type":"battle"}).ok,"Further battles rejected")
 ui.game._settle(0)
 check(before==ui.game.snapshot(),"No duplicated payout after final result")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/v9-result.png")
 ui._new_game();ui.game.state.round=30;ui.game._settle(0);ui._finish_playback()
 check(shell.screen=="result" and ui.game.state.lives==3,"Final victory opens central result screen")
 shell.show_screen("main")
 root.mode=Window.MODE_FULLSCREEN
 await process_frame;await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/v9-main-menu.png")
 check(shell.root.size==ui.size,"Menu fills fullscreen viewport")
 print("V9 MENUS: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
