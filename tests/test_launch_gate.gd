extends SceneTree
const Gate = preload("res://ui/launch_gate.gd")
var failures = 0
func check(ok: bool, message: String):
 if not ok:
  failures += 1
  push_error(message)
 else: print("PASS "+message)
func _init():
 DirAccess.make_dir_recursive_absolute("res://platform/tests/.runtime")
 var path = "res://platform/tests/.runtime/launch-gate-test.json"
 check(not Gate.consume_ticket(path,"9.1.2",100),"Missing ticket rejected")
 for test in [
  [{"version":"9.1.2","expires":130},true,"Valid launcher handoff accepted"],
  [{"version":"9.1.1","expires":130},false,"Wrong game version rejected"],
  [{"version":"9.1.2","expires":99},false,"Expired ticket rejected"],
  [{"version":"9.1.2","expires":200},false,"Long-lived ticket rejected"],
  [null,false,"Malformed ticket rejected"]]:
  var file = FileAccess.open(path,FileAccess.WRITE)
  file.store_string(JSON.stringify(test[0]))
  file.close()
  check(Gate.consume_ticket(path,"9.1.2",100) == test[1],test[2])
  check(not Gate.consume_ticket(path,"9.1.2",100),"Ticket cannot be replayed")
 quit(1 if failures else 0)
