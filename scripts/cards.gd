extends Node2D

var _selected = null
var _enabled = enable()

@onready var _camera = $Camera2D

func enable() -> bool:
	_enabled = true
	return true

func disable() -> bool:
	_enabled = false
	return false


func _input(event):
	if event.is_action_pressed("select") and is_instance_valid(_selected) and _selected is Card and _enabled:
		var scene = _selected.placement_scene.instantiate()
		
		disable()
		_selected.queue_free()
		
		get_tree().root.add_child(scene)
		
		if scene is Character:
			scene.position = position
			_camera.enabled = false
			scene.death_function = func():
				_camera.enabled = true
				enable()
				print("Dead")
				scene.death_function = Callable()


func _enabled_movement(delta):
	if not _enabled: return
	
	var nodes = %CardFrame.get_children()
	var length = nodes.size()
	
	var i = 0
	_selected = null
	
	for node in nodes:
		var new_pos = Vector2(
			i*32.0 - 16 * length,
			-104
		)
		
		var mouse_dist = (new_pos.x + 32 - get_local_mouse_position().x)
		new_pos.y += min(abs(mouse_dist) - 50, 48)
		new_pos.x += clamp(mouse_dist, -104, 104)
		
		if -16 < mouse_dist and mouse_dist <= 16 and _selected == null and new_pos.y - get_local_mouse_position().y < 48:
			node.scale = lerp(node.scale, Vector2.ONE*1.5, delta * 10)
			new_pos.x -= 16
			new_pos.y -= 64
			_selected = node
		else:
			node.scale = lerp(node.scale, Vector2.ONE, delta * 10)
		
		node.position = lerp(node.position, new_pos, delta*10)
		node.rotation = deg_to_rad(clamp(mouse_dist/10, -15, 15))
		
		i += 1

func _disabled_movement(delta):
	if _enabled: return
	
	var nodes = %CardFrame.get_children()
	_selected = null
	
	for node in nodes:
		node.position = lerp(node.position, Vector2.DOWN*10, delta*10)
		node.rotation = lerp(node.rotation, 0.0, delta*10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_enabled_movement(delta)
	_disabled_movement(delta)
