# DifficultySelect.gd
extends Node2D

func _on_FacilBTN_pressed():
	State.selected_difficulty = EnemyAI.Difficulty.EASY
	get_tree().change_scene_to_file("res://Battle.tscn")

func _on_MedioBTN_pressed():
	State.selected_difficulty = EnemyAI.Difficulty.MEDIUM
	get_tree().change_scene_to_file("res://Battle.tscn")

func _on_DificilBTN_pressed():
	State.selected_difficulty = EnemyAI.Difficulty.HARD
	get_tree().change_scene_to_file("Battle.tscn")
