# Battle.gd
# Controla el flujo principal del combate por turnos.
# - Mostrar mensajes de batalla
# - Procesar ataques y defensa
# - Ejecutar turno enemigo (decidido por EnemyAI)
# - Detectar victoria/derrota
# Dependencias:
# - State.gd (datos del jugador, autoload)
# - AIMemory.gd (historial de acciones del jugador, autoload)
# - EnemyAI.gd (lógica de decisión del enemigo)
# - BaseEnemy.gd (datos del enemigo)
# - Scene nodes: Textbox, ActionsPanel, AnimationPlayer
extends Control

signal textbox_closed

@export var enemy: Resource = null

@export var ai_difficulty: EnemyAI.Difficulty = EnemyAI.Difficulty.MEDIUM

var current_player_health = 0
var current_enemy_health = 0
var is_defending = false
var is_enemy_defending = false

func _ready():
	AiMemory.reset()

	set_health($EnemyContainer/ProgressBar, enemy.health, enemy.health)
	set_health($PlayerPanel/PlayerData/ProgressBar, State.current_health, State.max_health)
	set_mp($PlayerPanel/PlayerData/ProgressBar2, State.current_mp, State.max_mp)
	$EnemyContainer/Enemy.texture = enemy.texture

	current_player_health = State.current_health
	current_enemy_health = enemy.health
	current_player_mp = State.current_mp


	$Textbox.hide()
	$ActionsPanel.hide()

	display_text("A wild %s appears!" % enemy.name.to_upper())
	await self.textbox_closed
	$ActionsPanel.show()


func set_health(progress_bar, health, max_health):
	# Actualiza la barra visual y el texto de HP.
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]

func set_mp(progress_bar, mp, max_mp):
	# Actualiza la barra visual y el texto de MP.
	progress_bar.value = mp
	progress_bar.max_value = max_mp
	progress_bar.get_node("Label").text = "MP: %d/%d" % [mp, max_mp]



func _input(event):
	if (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and $Textbox.visible:
		$Textbox.hide()
		emit_signal("textbox_closed")


func display_text(text):
	$ActionsPanel.hide()
	$Textbox.show()
	$Textbox/Label.text = text


# ---------------------------------------------------------------------
# Turno del jugador
# ---------------------------------------------------------------------
func _on_Run_pressed():
	display_text("Got away safely!")
	await self.textbox_closed
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()


func _on_Attack_pressed():
	_log_player_action("attack")

	display_text("You swing your piercing sword!")
	await self.textbox_closed

	# El dragón está defendiendo
	if is_enemy_defending:
		is_enemy_defending = false

		display_text("%s blocked your attack!" % enemy.name)
		await self.textbox_closed

		enemy_turn()
		return

	# El dragón NO está defendiendo → recibe daño normalmente
	current_enemy_health = max(0, current_enemy_health - State.damage)
	set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)

	$AnimationPlayer.play("enemy_damaged")
	await $AnimationPlayer.animation_finished

	display_text("You dealt %d damage!" % State.damage)
	await self.textbox_closed

	if current_enemy_health == 0:
		await _handle_victory()
		return

	enemy_turn()
func _on_Defend_pressed():
	_log_player_action("defend")
	is_defending = true
	display_text("You prepare defensively!")
	await self.textbox_closed
	await get_tree().create_timer(0.25).timeout
	enemy_turn()

# Placeholder para cuando tu compañero termine el menú de Skills.
# Conectá los botones "Skill1"/"Skill2" a estas funciones (o renombralas
# según cómo las llame él) y ajustá el daño/costo de MP según corresponda.
func _on_Skill1_pressed():
	_log_player_action("skill_1")
	# TODO: lógica real de la skill 1 cuando esté implementada.
	enemy_turn()

func _on_Skill2_pressed():
	_log_player_action("skill_2")
	# TODO: lógica real de la skill 2 cuando esté implementada.
	enemy_turn()

func _log_player_action(action_name: String) -> void:
	var hp_pct = float(current_player_health) / float(State.max_health)
	AiMemory.log_action(action_name, hp_pct)

func _handle_victory() -> void:
	display_text("%s was defeated!" % enemy.name)
	await self.textbox_closed
	$AnimationPlayer.play("enemy_died")
	await $AnimationPlayer.animation_finished
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()

# ---------------------------------------------------------------------
# Turno del enemigo (decidido por EnemyAI en base al historial del jugador)
# ---------------------------------------------------------------------
func enemy_turn():
	var player_hp_pct = float(current_player_health) / float(State.max_health)
	var enemy_hp_pct = float(current_enemy_health) / float(enemy.health)
	var decision = EnemyAI.decide_action(
		ai_difficulty,
		player_hp_pct,
		enemy_hp_pct,
		is_defending
	)

	match decision:
		"defend":
			is_enemy_defending = true
			display_text("%s braces for the next attack!" % enemy.name)
			await self.textbox_closed
		"skill_1":
			display_text("%s uses a special attack!" % enemy.name)
			await self.textbox_closed
			await _enemy_do_attack()
		"skill_2":
			display_text("%s unleashes a powerful attack!" % enemy.name)
			await self.textbox_closed
			await _enemy_do_attack()
		_:  # "attack" por defecto
			display_text("%s launches at you fiercely!" % enemy.name)
			await self.textbox_closed
			await _enemy_do_attack()

	if current_player_health == 0:
		await _handle_defeat()
		return

	$ActionsPanel.show()

func _enemy_do_attack() -> void:

	if is_reflex_active:
		is_reflex_active = false
		if randf() < 0.75:  # 75% de probabilidad de esquivar
			$AnimationPlayer.play("mini_shake")
			await $AnimationPlayer.animation_finished
			display_text("¡Tu Super Reflejo te permitió esquivar el ataque!")
			await self.textbox_closed
			$ActionsPanel.show()
			return
		else:
			display_text("¡Intentaste esquivar, pero el ataque te alcanzó de todas formas!")
			await self.textbox_closed

	if is_defending:
		is_defending = false
		$AnimationPlayer.play("mini_shake")
		await $AnimationPlayer.animation_finished
		display_text("You defended successfully!")
		await self.textbox_closed
	else:
		current_player_health = max(0, current_player_health - enemy.damage)
		State.current_health = current_player_health
		set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)
		$AnimationPlayer.play("shake")
		await $AnimationPlayer.animation_finished
		display_text("%s dealt %d damage!" % [enemy.name, enemy.damage])
		await self.textbox_closed


func _handle_defeat() -> void:
	display_text("You were defeated...")
func _on_SuperReflejo_pressed():
	var cost = 20
	if current_player_mp < cost:
		close_skills_panel()
		display_text("¡No tienes suficiente MP!")
		await self.textbox_closed
		$ActionsPanel.show()
		return

	current_player_mp -= cost
	State.current_mp = current_player_mp
	set_mp($PlayerPanel/PlayerData/ProgressBar2, current_player_mp, State.max_mp)
	is_reflex_active = true

	close_skills_panel()
	display_text("¡Activaste Super Reflejo! Tienes altas probabilidades de esquivar el próximo ataque.")
	await self.textbox_closed

	enemy_turn()

func _on_GolpeCertero_pressed():
	var cost = 30
	if current_player_mp < cost:
		close_skills_panel()
		display_text("¡No tienes suficiente MP!")
		await self.textbox_closed
		$ActionsPanel.show()
		return

	current_player_mp -= cost
	State.current_mp = current_player_mp
	set_mp($PlayerPanel/PlayerData/ProgressBar2, current_player_mp, State.max_mp)

	close_skills_panel()
	display_text("¡Preparas un Golpe Certero!")
	await self.textbox_closed

	if randf() < 0.70:  # 70% de probabilidad de acertar el golpe crítico
		var crit_damage = int(State.damage * 2) #revisar y considerar el daño base
		current_enemy_health = max(0, current_enemy_health - crit_damage)
		set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)

		$AnimationPlayer.play("enemy_damaged")
		await $AnimationPlayer.animation_finished

		display_text("¡Golpe crítico! Causaste %d de daño!" % crit_damage)
		await self.textbox_closed
	else:
		display_text("¡Tu golpe falló y no logró conectar!")
		await self.textbox_closed

	if current_enemy_health == 0:
		display_text("%s was defeated!" % enemy.name)
		await self.textbox_closed

		$AnimationPlayer.play("enemy_died")
		await $AnimationPlayer.animation_finished

		await get_tree().create_timer(0.25).timeout
		get_tree().quit()
		return

	enemy_turn()
# --- Skills ---

func _on_Skills_pressed():
	$ActionsPanel/SkillsPanel.visible = not $ActionsPanel/SkillsPanel.visible

func close_skills_panel():
	$ActionsPanel/SkillsPanel.hide()

func _on_CuracionMenor_pressed():
	var cost = 10
	if current_player_mp < cost:
		close_skills_panel()
		display_text("¡No tienes suficiente MP!")
		await self.textbox_closed
		$ActionsPanel.show()
		return

	current_player_mp -= cost
	State.current_mp = current_player_mp
	set_mp($PlayerPanel/PlayerData/ProgressBar2, current_player_mp, State.max_mp)

	var heal_amount = int(State.max_health * 0.25)
	current_player_health = min(State.max_health, current_player_health + heal_amount)
	State.current_health = current_player_health
	set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)

	close_skills_panel()
	display_text("¡Te curaste %d puntos de vida!" % heal_amount)
	await self.textbox_closed

	enemy_turn() #REVISAR QUE PASA DESPUS DE AQUI, YA QUE DESPUES DE CURARNOS EL DRAGON ATACA
	#Y SI COMENTAMOS ESTO AL FINAL SE QUEDA COMO PEGADO LA PANTALLA
# --- Fin Skills ---

func _on_Run_pressed():
	display_text("Got away safely!")
	await self.textbox_closed
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()
