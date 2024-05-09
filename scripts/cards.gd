extends Control

var selected = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var nodes = get_children()
	var length = nodes.size()
	
	var i = 0
	selected = null
	
	for node in nodes:
		var new_pos = Vector2(
			i*32.0 - 16 * length,
			-104
		)
		
		var mouse_dist = (new_pos.x + 32 - get_local_mouse_position().x)
		new_pos.y += min(abs(mouse_dist) - 50, 48)
		new_pos.x += clamp(mouse_dist, -104, 104)
		
		if -16 < mouse_dist and mouse_dist <= 16 and selected == null:
			node.scale = lerp(node.scale, Vector2.ONE*1.5, delta * 10)
			new_pos.x -= 16
			new_pos.y -= 64
			selected = node
		else:
			node.scale = lerp(node.scale, Vector2.ONE, delta * 10)
		
		node.position = lerp(node.position, new_pos, delta*10)
		node.rotation = deg_to_rad(clamp(mouse_dist/10, -30, 30))
		
		i += 1
