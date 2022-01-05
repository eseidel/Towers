extends Spatial

var SPAWN_DELAY = 10
var TIME_SINCE_SPAWN = SPAWN_DELAY

enum SpawnType {
	Caster,
	None,
}

var SPAWN_PATTERN = [
	[3, SpawnType.Caster],
	[3, SpawnType.Caster],
	[3, SpawnType.Caster],
	[5, SpawnType.None], # A break between waves
]

var spawn_pattern_offset = 0

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

func spawn_caster():
	var clone = minion_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)
	clone.global_transform = self.global_transform
	clone.TEAM = TEAM
	clone.waypoints = $"/root/Testing_Area/Waypoints".get_children()

func spawn_next_minion():
	var next_spawn = SPAWN_PATTERN[spawn_pattern_offset][1]
	match next_spawn:
		SpawnType.Caster:
			spawn_caster()
	spawn_pattern_offset = (spawn_pattern_offset + 1) % SPAWN_PATTERN.size()

func _process(delta):
	TIME_SINCE_SPAWN += delta
	var current_delay = SPAWN_PATTERN[spawn_pattern_offset][0]
	if TIME_SINCE_SPAWN >= current_delay:
		spawn_next_minion()
		TIME_SINCE_SPAWN = 0

