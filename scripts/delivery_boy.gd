extends Character

var box = preload("res://scenes/box.tscn")

@onready var space_check: RayCast2D = $SpaceCheck

func _init():
	strength = 5000

func activate():
	if is_on_floor() and not space_check.is_colliding():
		var box_instance = box.instantiate()
		box_instance.position = position
		get_tree().root.add_child(box_instance)
