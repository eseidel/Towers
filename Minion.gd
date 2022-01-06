extends Spatial

# FIXME: Share code with Tower

enum Team {BLUE, RED}
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
var COLLISION_RADIUS = 2
var DEBUG_HALF_THICKNESS = 0.1

# One per second?
var ATTACK_DELAY = 1
var MOVE_SPEED = 5

var DAMAGE = 25
var HEALTH = 300

var since_last_target_update = INF
var TARGET_UPDATE_DELAY = .25
var TARGET_REF = null

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

var waypoints = []
var next_waypoint_offset = 0
var WAYPOINT_RADIUS = 2
var last_turn_direction = 1

func _team_material():
	match TEAM:
		Team.BLUE:
			return preload("res://Blue.tres")
		Team.RED:
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
	clone.TARGET_REF = weakref(target)

func next_waypoint():
	if next_waypoint_offset >= waypoints.size():
		return null
	match TEAM:
		Team.BLUE:
			return waypoints[next_waypoint_offset]
		Team.RED:
			return waypoints[waypoints.size() - 1 - next_waypoint_offset]

func reached_waypoint():
	next_waypoint_offset += 1

func closest_distance_to(location, areas):
	var distances = []
	for area in areas:
		var offset = location - area.global_transform.origin
		distances.push_back(offset.length())
	return distances.min()

func avoid_nearby_mobs(forward_offset):
	var nearby_npcs = $DetectRadius.get_overlapping_areas()
	if nearby_npcs.empty():
		return forward_offset
	var planned_location = global_transform.origin + forward_offset
	var new_distance = closest_distance_to(planned_location, nearby_npcs)
	if new_distance > COLLISION_RADIUS:
		return forward_offset

	# We would only ever be moving if not attacking, so we should only need to
	# check against same-team mob positions.
	var slice_count = 2
	var slice_angle = PI / slice_count
	# FIXME: This is too short-sighted.  We should instead plan a path around the other minions and
	# then pick a point along that path to move towards.
	for i in range(slice_count):
		var turned_left_offset = forward_offset.rotated(Vector3.UP, last_turn_direction * i * -slice_angle)
		var turned_left_location = global_transform.origin + turned_left_offset
		var turned_left_distance = closest_distance_to(turned_left_location, nearby_npcs)
		if turned_left_distance > COLLISION_RADIUS:
			last_turn_direction = 1
			return turned_left_offset
	
		var turned_right_offset = forward_offset.rotated(Vector3.UP, last_turn_direction * i * slice_angle)
		var turned_right_location = global_transform.origin + turned_right_offset
		var turned_right_distance = closest_distance_to(turned_right_location, nearby_npcs)
		if turned_right_distance > COLLISION_RADIUS:
			last_turn_direction = -1
			return turned_right_offset
	return null


func plan_movement_offset(delta):
	# Godot uses -z for "forward"
	# https://godotengine.org/qa/23054/look_at-looks-exactly-at-the-opposite-direction
	var forward_dir = -global_transform.basis.z.normalized()
	var planned_offset = forward_dir * MOVE_SPEED * delta
		# Adjust offset to avoid obstacles (including other minions)
	return avoid_nearby_mobs(planned_offset)

func walk(delta):
	var waypoint = next_waypoint()
	if waypoint:
		var target_location = waypoint.global_transform.origin
		look_at(target_location, Vector3.UP)
		var offset = plan_movement_offset(delta)
		if offset:
			global_translate(offset)

		var distance_to_target = target_location - global_transform.origin
		if distance_to_target.length() < WAYPOINT_RADIUS:
			reached_waypoint()
	# Do nothing if no waypoint.


func validate_target():
	if !TARGET_REF:
		return null
	var target = TARGET_REF.get_ref()
	if !target:
		TARGET_REF = null
		return null
	return target

func attack_if_ready(delta):
	var target = validate_target()
	if !target:
		return

	since_last_attack += delta
	if since_last_attack > ATTACK_DELAY:
		since_last_attack = 0
		look_at(target.global_transform.origin, Vector3(0, 1, 0))
		fire_at(target)

func compute_mode(target):
	if target != null:
		return Mode.fighting
	else:
		return Mode.walking

func _process(delta):
	var target = validate_target()
	match compute_mode(target):
		Mode.walking:
			walk(delta)
		Mode.fighting:
			attack_if_ready(delta)

func die():
	# should do some sort of animation
	queue_free()

func hit(from, damage):
	HEALTH -= damage
	if HEALTH < 0:
		die()

# FIXME: This is wrong, minions should pick a target on a regular tick
# not based on when something enters.
func _on_DetectRadius_area_entered(area):
	var mob = area.get_parent()
	if mob.TEAM != TEAM:
		TARGET_REF = weakref(mob)
