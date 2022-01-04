extends Spatial

enum Team {BLUE, RED, NEUTRAL}
export(Team) var TEAM setget set_team

# Should inherit from MOB
# Should have multiple areas
# https://proworthy.gg/blog/minion-ai-documentaiton/
# https://kidscancode.org/godot_recipes/ai/homing_missile/


enum State {
	Attacking,
	Marching,
}

export var DETECT_RADIUS = 10
var DEBUG_HALF_THICKNESS = 0.1

# One per second?
var ATTACK_DELAY = 1
var MOVE_SPEED = 5
var TARGET = null
var DAMAGE = 30

var HEALTH = 100

# If attacking
# Windup
# Fire
# Wind-down

var missle_scene = preload("Missle.tscn")
var since_last_attack = INF

enum Mode {
	walking,
	fighting,
}

var mode = Mode.walking

func _team_material():
	match TEAM:
		Team.BLUE:
			return preload("res://Blue.tres")
		Team.RED:
			return preload("res://Red.tres")
		Team.NEUTRAL:
			return preload("res://Red.tres")

func set_team(new_team):
	TEAM = new_team
	$MeshInstance.set_surface_material(0, _team_material())

func _ready():
	set_team(TEAM)
	$DetectRadius/Shape.shape.radius = DETECT_RADIUS
	$DetectRadius/Debug.inner_radius = DETECT_RADIUS - DEBUG_HALF_THICKNESS
	$DetectRadius/Debug.outer_radius = DETECT_RADIUS + DEBUG_HALF_THICKNESS

func fire_at(target):
	var clone = missle_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)

	clone.global_transform = self.global_transform
	# clone.scale = Vector3(4, 4, 4)
	clone.MISSLE_DAMAGE = DAMAGE
	clone.TARGET = target


func walk(delta):
	# Godot uses -z for "forward"
	# https://godotengine.org/qa/23054/look_at-looks-exactly-at-the-opposite-direction
	var forward_dir = -global_transform.basis.z.normalized()
	global_translate(forward_dir * MOVE_SPEED * delta)

func attack_if_ready(delta):
	since_last_attack += delta
	if since_last_attack > ATTACK_DELAY:
		since_last_attack = 0
		look_at(TARGET.global_transform.origin, Vector3(0, 1, 0))
		fire_at(TARGET)

func compute_mode():
	if TARGET != null:
		return Mode.fighting
	else:
		return Mode.walking

func _process(delta):
	match compute_mode():
		Mode.walking:
			walk(delta)
		Mode.fighting:
			attack_if_ready(delta)

func missle_hit(damage):
	HEALTH -= damage
	print(HEALTH)

func _on_DetectRadius_area_entered(area):
	var mob = area.get_parent()
	if mob.TEAM != TEAM:
		TARGET = mob
		print(TARGET)

