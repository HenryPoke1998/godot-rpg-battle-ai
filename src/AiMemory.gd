#AiMemory.gd
extends Node

var action_history: Array[String] = [] # aca se guard el historial de acciones
var health_at_action: Array[float] = [] # aca se guarda la vida del jugador 

func log_action(action_name: String, player_health_percent: float = -1.0) -> void:
	action_history.append(action_name)
	health_at_action.append(player_health_percent)

func reset() -> void: # limpia los valores despues de cada combate 
	action_history.clear()
	health_at_action.clear()

func get_last_actions(n: int) -> Array[String]:
	if action_history.is_empty():
		return []
	var start = max(0, action_history.size() - n)
	return action_history.slice(start, action_history.size())


func get_frequency(action_name: String, window: int = -1) -> float:
	var pool = action_history
	if window > 0:
		pool = get_last_actions(window)
	if pool.is_empty():
		return 0.0
	var count = 0
	for a in pool:
		if a == action_name:
			count += 1
	return float(count) / float(pool.size())


func most_common_action(window: int = -1) -> String:
	var pool = action_history
	if window > 0:
		pool = get_last_actions(window)
	if pool.is_empty():
		return ""
	var counts := {}
	for a in pool:
		counts[a] = counts.get(a, 0) + 1
	var best_action = ""
	var best_count = -1
	for key in counts.keys():
		if counts[key] > best_count:
			best_count = counts[key]
			best_action = key
	return best_action


func find_repeating_pattern(pattern_length: int = 2) -> Array[String]:
	# Busca si las últimas 'pattern_length' acciones ya se repitieron
	# antes en el historial (indicio de que el jugador tiene una rutina).
	# Devuelve el patrón si lo encuentra, o [] si no hay suficiente data.
	if action_history.size() < pattern_length * 2:
		return []
	var recent = get_last_actions(pattern_length)
	var search_end = action_history.size() - pattern_length
	for i in range(search_end):
		var slice = action_history.slice(i, i + pattern_length)
		if slice == recent:
			return recent
	return []
