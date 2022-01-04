extends Spatial

var SPAWN_DELAY = 10
var TIME_SINCE_SPAWN = SPAWN_DELAY

var minion_scene = preload("res://Minion.tscn")

# FIXME: Share with Minion
enum Team {BLUE, RED}
export(Team) var TEAM

func _team_material():
	match TEAM:
		Team.BLUE:
			return preload("res://Blue.tres")
		Team.RED:
			return preload("res://Red.tres")

func set_team(new_team):
	TEAM = new_team
	$CSGSphere.set_material(_team_material())

# Called when the node enters the scene tree for the first time.
func _ready():
	set_team(TEAM)

func spawn_minion():
	var clone = minion_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)
	clone.global_transform = self.global_transform
	clone.TEAM = TEAM

func _process(delta):
	TIME_SINCE_SPAWN += delta
	if TIME_SINCE_SPAWN >= SPAWN_DELAY:
		spawn_minion()
		TIME_SINCE_SPAWN = 0
