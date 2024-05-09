class_name Character
extends CharacterBody2D

enum DamageCause {
	DEFAULT, IMPALEMENT
}

const SPEED = 200
const FRICTION = 15
const AIR_FRICTION = 3
const DEAD_FRICTION = 1
const GRAVITY = 980
const JUMP_POWER = 300

var force_field = 0
var health = 3

var dead = false
var dead_grounded_time = 0

@onready var interaction_area = $InteractionArea
@onready var hurt_detection_area = $HurtDetectionArea
@onready var spike_detection_area = $SpikeDetectionArea
@onready var death_timer = $DeathTimer


func _on_death_timer_timeout():
	get_tree().reload_current_scene()


func dead_move(delta): 
	velocity.x = lerpf(velocity.x, 0, delta * DEAD_FRICTION)


func dead_gravity(delta):
	velocity.y += GRAVITY * delta

func dead_spike(delta):
	if spike_detection_area.has_overlapping_areas():
		var new_velocity = Vector2.UP.rotated(spike_detection_area.get_overlapping_areas()[0].rotation) * GRAVITY / 100
		if new_velocity.y < 0:
			new_velocity *= -1
		new_velocity.x = clamp(new_velocity.x, -new_velocity.y, new_velocity.y)
		velocity = lerp(velocity, new_velocity, 20*delta)
		return true
	return false


func dead_check(delta):
	dead_grounded_time += delta
	if velocity.length_squared() > 100:
		dead_grounded_time = 0
	
	if dead_grounded_time > 2:
		death_complete()


func death_complete():
	$Collision.shape.size.y = 14
	$SpikeDetectionArea/Collision.shape.size.y = 14


func move(delta):
	var movement = Input.get_axis("left", "right") * SPEED
	velocity.x = lerpf(velocity.x, movement, delta * (FRICTION if is_on_floor() else AIR_FRICTION))


func apply_gravity(delta):
	if is_on_floor():
		velocity.y = min(0, velocity.y)
	else:
		velocity.y += GRAVITY * delta


func jump():
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = -JUMP_POWER


func death(cause: DamageCause):
	dead = true
	


func damage(amount: int, cause: DamageCause, force_field_time: float = 3):
	if force_field > 0:
		return
	
	health -= amount
	force_field = force_field_time
	if health == 0:
		death(cause)


func hurt_detect():
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
	velocity *= 0.8


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
		hurt_detect()
		move_and_slide()
	
	force_field -= delta



