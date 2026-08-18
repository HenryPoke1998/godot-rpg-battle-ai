# EnemyAI.gd
# "Cerebro" de decisión del enemigo. NO es un autoload: se instancia o se
# llama de forma estática desde Battle.gd en cada enemy_turn().
#
# Usa AIMemory (autoload) para leer el historial del jugador y decide
# qué acción tomar según la dificultad configurada.
extends Node
class_name EnemyAI

enum Difficulty { EASY, MEDIUM, HARD }

# Acciones posibles del enemigo. Ajustá los nombres cuando tu compañero
# defina las skills reales (ej: "skill_1" -> "fireball").
const ACTIONS = ["attack", "defend", "skill_1", "skill_2"]


static func decide_action(
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


# ---------------------------------------------------------------------
# FÁCIL: memoria corta, decisiones mayormente aleatorias con algo de
# error. Solo mira la última acción del jugador.
# ---------------------------------------------------------------------
static func _decide_easy() -> String:
	var last = AiMemory.get_last_actions(1)

	# 70% de las veces, ignora el patrón y actúa random (simula "errores").
	if randf() < 0.7 or last.is_empty():
		return ACTIONS[randi() % ACTIONS.size()]

	# 30% de las veces, reacciona de forma simple a la última acción.
	if last[0] == "attack":
		return "defend" if randf() < 0.5 else "attack"
	return "attack"


# ---------------------------------------------------------------------
# MEDIO: analiza una ventana de las últimas acciones (frecuencia) y
# reacciona a la tendencia general del jugador. Comete pocos errores.
# ---------------------------------------------------------------------
static func _decide_medium(player_hp_pct: float, enemy_hp_pct: float) -> String:
	var window = 5
	var attack_freq = AiMemory.get_frequency("attack", window)
	var defend_freq = AiMemory.get_frequency("defend", window)

	# Si el enemigo está bajo de vida, prioriza defenderse (poca lógica
	# de autoconservación, pero simple y creíble).
	if enemy_hp_pct < 0.25 and randf() < 0.6:
		return "defend"

	# Si el jugador ataca mucho, el enemigo se defiende más seguido.
	if attack_freq > 0.6:
		return "defend" if randf() < 0.5 else "skill_1"

	# Si el jugador se defiende mucho, el enemigo presiona con skills
	# (asumiendo que hacen más daño que el ataque básico).
	if defend_freq > 0.4:
		return "skill_2" if randf() < 0.6 else "skill_1"

	# Sin tendencia clara: mezcla razonable.
	var roll = randf()
	if roll < 0.5:
		return "attack"
	elif roll < 0.75:
		return "skill_1"
	else:
		return "defend"


# ---------------------------------------------------------------------
# DIFÍCIL: analiza todo el historial, busca patrones repetidos y
# anticipa la próxima acción del jugador. Reacciona casi siempre bien.
# ---------------------------------------------------------------------
static func _decide_hard(player_hp_pct: float, enemy_hp_pct: float, is_player_defending: bool) -> String:
	# 1. Si detecta una rutina (ej: ataca, ataca, defiende, ataca, ataca,
	#    defiende...) intenta anticipar la siguiente acción del patrón.
	var pattern = AiMemory.find_repeating_pattern(2)
	if not pattern.is_empty():
		var predicted_next = pattern[0]  # el patrón se repite, así que el
										  # primer elemento suele ser lo próximo
		if predicted_next == "attack":
			# Anticipa el golpe: se defiende para anularlo.
			return "defend"
		elif predicted_next == "defend":
			# El jugador va a defenderse: usa una skill fuerte, no
			# desperdicies el ataque básico contra una defensa.
			return "skill_2"

	# 2. Sin patrón claro: usa el historial completo (no solo ventana).
	var most_common = AiMemory.most_common_action()
	var attack_freq = AiMemory.get_frequency("attack")

	# El jugador se cura/defiende mucho cuando tiene poca vida: si el
	# jugador está bajo, castiga fuerte en vez de atacar normal.
	if player_hp_pct < 0.3:
		return "skill_2"

	# Jugador muy ofensivo -> el enemigo intercala defensa para no
	# perder tanta vida y contraatacar con skills.
	if attack_freq > 0.5:
		return "skill_1" if randf() < 0.5 else "defend"

	# Enemigo bajo de vida -> prioriza sobrevivir.
	if enemy_hp_pct < 0.3:
		return "defend"

	# Fallback: repite lo que mejor le ha funcionado al jugador,
	# usado en contra suya (heurística simple de "adaptación").
	match most_common:
		"attack":
			return "skill_1"
		"defend":
			return "attack"
		_:
			return "attack"
