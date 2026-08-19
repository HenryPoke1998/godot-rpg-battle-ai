#state.gd
extends Node

var max_health = 200
var current_health = max_health
var damage = 7
var current_mp = 50
var max_mp = 50
var selected_difficulty: int = EnemyAI.Difficulty.MEDIUM  # valor por defecto
