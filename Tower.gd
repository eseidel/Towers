extends Spatial

# FIXME: Share code with Minion

enum Team {BLUE, RED}
export(Team) var TEAM setget set_team

export var DETECT_RADIUS = 15
var COLLISION_RADIUS = 2
var DEBUG_HALF_THICKNESS = 0.1

# One per second?
var ATTACK_DELAY = 1
var MOVE_SPEED = 5

var DAMAGE = 150
var MAX_HEALTH = 5000
var HEALTH = MAX_HEALTH setget set_health

var since_last_target_update = INF
var TARGET_UPDATE_DELAY = .25
var TARGET_REF = null


var missle_scene = preload("Missle.tscn")
var since_last_attack = INF

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
	set_health(MAX_HEALTH)
	$DetectRadius/Shape.shape.radius = DETECT_RADIUS
	$DetectRadius/Debug.inner_radius = DETECT_RADIUS - DEBUG_HALF_THICKNESS
	$DetectRadius/Debug.outer_radius = DETECT_RADIUS + DEBUG_HALF_THICKNESS

func fire_at(target):
	var clone = missle_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)

	clone.global_transform = self.global_transform
	clone.MISSLE_DAMAGE = DAMAGE
	clone.TARGET_REF = weakref(target)


func validate_target():
	if !TARGET_REF:
		return null
	var target = TARGET_REF.get_ref()
	if !target:
		TARGET_REF = null
		return null
	return target

func attack_if_ready(target, delta):
	since_last_attack += delta
	if since_last_attack > ATTACK_DELAY:
		since_last_attack = 0
		fire_at(target)

# https://leagueoflegends.fandom.com/wiki/Turret
# Towers pick the first thing to enter their range
# Towers will pick minions over champions if not locked on anything
# Towers have a call-for-help mechanic which I'm not implementing now.
# Towers pick minions in a specific order, probably otherwise closest.

class TargetSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false

func pick_target():
	var nearby_mob_areas = $DetectRadius.get_overlapping_areas()
	var nearby_mobs = []
	for area in nearby_mob_areas:
		var mob = area.get_parent()
		if mob.TEAM != TEAM:
			nearby_mobs.push_back(mob)

	if !nearby_mobs.empty():
		#nearby_mob_areas.sort_custom(TargetSorter, "sort_ascending")
		TARGET_REF = weakref(nearby_mobs.front())

func _process(delta):
	var target = validate_target()
	if target:
		attack_if_ready(target, delta)
	else:
		since_last_target_update += delta
		if since_last_target_update > TARGET_UPDATE_DELAY:
			pick_target()

func die():
	# should do some sort of animation
	queue_free()


func set_health(new_health):
	HEALTH = new_health
	$"Waypoint Anchor/Waypoint".set_text("%s / %s" % [HEALTH, MAX_HEALTH])

func hit(from, damage):
	set_health(HEALTH - damage)
	if HEALTH < 0:
		die()
