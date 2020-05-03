extends Node2D
class_name LevelHandler

# Simple map handler for scripts that need access to tilemap
# Checks for every node in group "needs_map_handler" and gives it a reference
# to itself, allowing for access without using NodePaths or relative paths
# 
# Need to improve: rock handling

onready var GROUND_MAP := $DugMap as TileMap
const MAP_DIMS = Rect2(0, 1, 12, 13)
var last_player_pos : Vector2
var dug_tile_id

signal dug_tile

func _ready():
	print("Level Handler Ready!")
	
	for needy_obj in get_tree().get_nodes_in_group("grid_entities"):
		if needy_obj.has_method("set_level_handler"):
			needy_obj.set_level_handler(self)
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.connect("enemy_died", self, "spawn_enemy_death_effects")
	
	for rock in get_tree().get_nodes_in_group("obstacles"):
		rock.connect("rock_fallen", self, "spawn_score_text")
	
	dug_tile_id = GROUND_MAP.tile_set.find_tile_by_name("Hole")

# Improve this
func _on_Player_dug_at_position(pos):
	last_player_pos = pos
	var rel_player_pos = GROUND_MAP.world_to_map(pos)
	if GROUND_MAP.get_cellv(rel_player_pos) != dug_tile_id:
		GROUND_MAP.set_cellv(rel_player_pos, dug_tile_id)
		GROUND_MAP.update_bitmask_area(rel_player_pos)
		emit_signal("dug_tile")

func is_tile_dug(pos):
	return GROUND_MAP.get_cellv(GROUND_MAP.world_to_map(pos)) == dug_tile_id

func is_in_bounds(pos : Vector2) -> bool:
	var map_pos = GROUND_MAP.world_to_map(pos)
	if map_pos.x < MAP_DIMS.position.x or map_pos.x > MAP_DIMS.end.x-1:
		return false
	elif map_pos.y < MAP_DIMS.position.y or map_pos.y > MAP_DIMS.end.y-1:
		return false
	
	return true

func has_obstacle_at(pos : Vector2) -> bool:
	var map_pos = GROUND_MAP.world_to_map(pos)
	var OBSTACLES = get_tree().get_nodes_in_group("obstacles")
	for obstacle in OBSTACLES:
		var obstacle_map_pos = GROUND_MAP.world_to_map((obstacle as Node2D).position)
		if map_pos == obstacle_map_pos and obstacle.is_waiting():
			return true
	
	return false

func get_map_grid() -> Vector2:
	return GROUND_MAP.cell_size

func spawn_enemy_death_effects(pos, score, rock_kill):
	var explosion = RESOURCES.EXPLOSION.instance()
	explosion.position = pos + Vector2(16,16)
	add_child(explosion)
	explosion.explode(rock_kill)
	
	if not rock_kill:
		spawn_score_text(pos, score)

func spawn_score_text(pos : Vector2, score : int):
	if score != 0:
		var score_text = RESOURCES.SCORELABEL.instance()
		score_text.set_score(score)
		score_text.position = pos
		add_child(score_text)

func clean_up_map():
	for entity in get_tree().get_nodes_in_group("grid_entities"):
		entity.queue_free()
