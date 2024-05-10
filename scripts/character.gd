class_name Character
extends CharacterBody2D

enum DamageCause {
	DEFAULT, IMPALEMENT, ABILITY
}

const AIR_FRICTION = 3
const DEAD_FRICTION = 1

var friction = 15

var strength = 3000
var jump_power = 300
var gravity = 980
var speed = 200

var force_field = 0
var health = 3

var dead = false
var finally_dead = false
var dead_grounded_time = 0

var death_function: Callable

@onready var interaction_area = $InteractionArea
@onready var hurt_detection_area = $HurtDetectionArea
@onready var spike_detection_area = $SpikeDetectionArea
@onready var death_timer = $DeathTimer
@onready var camera = $Camera2D

func _on_death_timer_timeout():
	get_tree().reload_current_scene()

func _ready():
	camera.enabled = true

func dead_move(delta): 
	velocity.x = lerpf(velocity.x, 0, delta * DEAD_FRICTION)


func dead_gravity(delta):
	velocity.y += gravity * delta

func dead_spike(delta):
	if spike_detection_area.has_overlapping_areas():
		var new_velocity = Vector2.UP.rotated(spike_detection_area.get_overlapping_areas()[0].rotation) * gravity / 100
		if new_velocity.y < 0:
			new_velocity *= -1
		new_velocity.x = clamp(new_velocity.x, -new_velocity.y, new_velocity.y)
		velocity = lerp(velocity, new_velocity, 20*delta)
		return true
	return false

func dead_final():
	finally_dead = true
	camera.enabled = false
	death_function.call()
	print("call death func")


func dead_check(delta):
	dead_grounded_time += delta
	if velocity.length_squared() > 1000:
		dead_grounded_time = 0
	
	print(velocity.length_squared(), "  ", dead_grounded_time)
	if dead_grounded_time > 2 and not finally_dead:
		dead_final()


func move(delta):
	var movement = Input.get_axis("left", "right") * speed
	velocity.x = lerpf(velocity.x, movement, delta * (friction if is_on_floor() else AIR_FRICTION))


func apply_gravity(delta):
	if is_on_floor():
		velocity.y = min(0, velocity.y)
	else:
		velocity.y += gravity * delta


func jump():
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = -jump_power


func kill(cause: DamageCause):
	health = 0
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(12, 14)
	set_collision_mask_value(2, false)
	$Collision.shape = rectangle
	$Collision.one_way_collision = true
	$SpikeDetectionArea/Collision.shape = rectangle
	
	dead = true


func damage(amount: int, cause: DamageCause, force_field_time: float = 3) -> bool:
	if force_field > 0:
		return false
	
	health -= amount
	force_field = force_field_time
	if health == 0:
		kill(cause)
	elif health < 0:
		health = 0
		return false
	return true
	


func _hurt_detect():
	var areas = hurt_detection_area.get_overlapping_areas()
	if not areas.is_empty():
		var area = areas[0]
		if area is Spike: # implement later
			damage(3, DamageCause.IMPALEMENT)
		else:
			damage(1, DamageCause.DEFAULT)


func death_bounce(collision):
	if collision == null: return
	
	if velocity.y < 160:
		velocity.y = 0
	
	velocity = velocity.bounce(collision.get_normal())
	velocity *= 0.5


func _push_object(delta):
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if abs(c.get_angle()) < PI/3 or abs(c.get_angle()) > PI*2/3:
			continue
		if collider is RigidBody2D:
			collider.apply_central_impulse(-c.get_normal() * delta * strength)


func activate(): pass


func _interact(interaction_node):
	if not is_instance_valid(interaction_node): return
	if interaction_node is HealthCrystal:
		interaction_node.queue_free()
		health += 1


func _input(event):
	if event.is_action_pressed("activate"):
		if not interaction_area.has_overlapping_areas():
			activate()
			return
		
		var areas: Array[Area2D] = interaction_area.get_overlapping_areas()
		
		areas.sort_custom(func(a, b) -> bool:
			return interaction_area.position.distance_to_squared(a.position) > interaction_area.position.distance_to_squared(b.position)
		)
		
		_interact(areas[0])


func _physics_process(delta):
	if dead:
		var in_spike = dead_spike(delta)
		
		if not in_spike:
			dead_move(delta)
			dead_gravity(delta)
		
		dead_check(delta)
		
		var collision = move_and_collide(velocity * delta)
		death_bounce(collision)
	else:
		move(delta)
		apply_gravity(delta)
		jump()
		move_and_slide()
		
		_hurt_detect()
		
		_push_object(delta)
	
	force_field -= delta



