extends Node

const PUMP       = preload("res://Scenes/Entity Scenes/Pump.tscn")
const EXPLOSION  = preload("res://Scenes/Entity Scenes/ExplosionFX.tscn")
const SCORELABEL = preload("res://Scenes/Entity Scenes/ScoreLabel.tscn")

const LEVELS = [
	preload("res://Scenes/Levels/Level1.tscn"),
	preload("res://Scenes/Levels/Level2.tscn"),
	preload("res://Scenes/Levels/Level3.tscn"),
	preload("res://Scenes/Levels/Level4.tscn"),
	preload("res://Scenes/Levels/Level5.tscn"),
	preload("res://Scenes/Levels/Level6.tscn")
]

const PUMP_EXPLOSION_SFX = preload("res://Audio/SFX/enemy_death_pump.wav")
const ROCK_EXPLOSION_SFX = preload("res://Audio/SFX/enemy_death_crush.wav")
const PLAYER_DEATH_SFX   = preload("res://Audio/SFX/player_death_sfx.wav")
const PUMP_LAUNCH_SFX  = preload("res://Audio/SFX/pump_launch.wav")

const GAME_START_SFX = preload("res://Audio/Music/game_start.wav")
const GAME_OVER_SFX = preload("res://Audio/Music/game_over.wav")
