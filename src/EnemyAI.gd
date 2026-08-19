# EnemyAI.gd
extends Node
class_name EnemyAI

enum Difficulty { EASY, MEDIUM, HARD }

const ACTIONS = ["attack", "defend", "skill_1", "skill_2", "skill_3"]


static func decide_action( # aca se almacenan valores importantes para tomar decisiones 
	difficulty: int,
	player_health_percent: float,
	enemy_health_percent: float,
	is_player_defending: bool
) -> String:
	match difficulty:
		Difficulty.EASY:
			return _decide_easy()
		Difficulty.MEDIUM:
			return _decide_medium(player_health_percent, enemy_health_percent)
		Difficulty.HARD:
			return _decide_hard(player_health_percent, enemy_health_percent, is_player_defending)
		_:
			return "attack"

static func _decide_easy() -> String:
	var last = AiMemory.get_last_actions(1)
	if randf() < 0.7 or last.is_empty(): # tiene un 70% de ignorar lo que hace el jugador 
		return ACTIONS[randi() % ACTIONS.size()]
	if last[0] == "attack":
		return "defend" if randf() < 0.5 else "attack"
	return "attack"
	
static func _decide_medium(player_hp_pct: float, enemy_hp_pct: float) -> String:
	var window = 5
	var attack_freq = AiMemory.get_frequency("attack", window)
	var defend_freq = AiMemory.get_frequency("defend", window)
	
	if enemy_hp_pct < 0.25 and randf() < 0.6: # toma acciones dependiedndo de la vida 
		return "defend"
	if attack_freq > 0.6:
		return "defend" if randf() < 0.5 else "skill_1"

	# Si el jugador se defiende mucho, el enemigo presiona con skills
	if defend_freq > 0.4:
		return "skill_2" if randf() < 0.6 else "skill_2" # rompe la defenza y causa daño

	# Si no hay una tendencia clara: mezcla razonable.
	var roll = randf()
	if roll < 0.5:
		return "attack"
	elif roll < 0.75:
		return "skill_1"
	else:
		return "defend"

static func _decide_hard(player_hp_pct: float, enemy_hp_pct: float, is_player_defending: bool) -> String:
#analiza todos lo smovivientos y prevee el siguiente ataque 
	var pattern = AiMemory.find_repeating_pattern(2)
	if not pattern.is_empty():
		var predicted_next = pattern[0]  
		if predicted_next == "attack":
			return "defend"
		elif predicted_next == "defend":
			return "skill_2" # rompe la defenza y causa daño 

	var most_common = AiMemory.most_common_action()
	var attack_freq = AiMemory.get_frequency("attack")


	if player_hp_pct < 0.3:# si el player ajo de vida castga fuerte 
		return "skill_3"

	if attack_freq > 0.5:
		return "skill_1" if randf() < 0.5 else "defend"

	if enemy_hp_pct < 0.3: # si bajo de vida se proteje 
		return "defend"

	match most_common:
		"attack":
			return "skill_1"
		"defend":
			return "attack"
		_:
			return "attack"
