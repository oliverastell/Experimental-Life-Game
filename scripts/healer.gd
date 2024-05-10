extends Character

var health_crystal = preload("res://scenes/health_crystal.tscn")

func activate():
	if not is_on_floor():
		return
	
	if not damage(1, DamageCause.ABILITY): return
	print(health)
	
	var health_instance = health_crystal.instantiate()
	health_instance.position = position
	get_tree().root.add_child(health_instance)
