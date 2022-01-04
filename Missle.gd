extends Spatial

# See
# https://kidscancode.org/godot_recipes/ai/homing_missile/

var MISSLE_SPEED = 70
var MISSLE_DAMAGE = 15
var TARGET = null

const KILL_TIMER = 4
var timer = 0

var hit_something = false

# FIXME: This should be on the NPC itself.
var HIT_RADIUS = 1

func _ready():
	# Should collide when enters the collision radius.
	# $Area.connect("body_entered", self, "collided")
	pass

func _physics_process(delta):
	# Godot uses -z for "forward"
	# https://godotengine.org/qa/23054/look_at-looks-exactly-at-the-opposite-direction
	var target_location = TARGET.global_transform.origin
	look_at(target_location, Vector3.UP)
	var forward_dir = -global_transform.basis.z.normalized()
	global_translate(forward_dir * MISSLE_SPEED * delta)

	var distance_to_target = target_location - global_transform.origin
	if distance_to_target.length() < HIT_RADIUS:
		collided(TARGET)

	timer += delta
	if timer >= KILL_TIMER:
		queue_free()

func collided(body):
	if hit_something == false:
		if body.has_method("missle_hit"):
			body.missle_hit(MISSLE_DAMAGE)

	hit_something = true
	queue_free()
