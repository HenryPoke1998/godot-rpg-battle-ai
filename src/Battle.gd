# Battle.gd
# Controla el flujo principal del combate por turnos.
# - Mostrar mensajes de batalla
# - Procesar ataques y defensa
# - Ejecutar turno enemigo
# - Detectar victoria/derrota
# Dependencias:
# - State.gd (datos del jugador)
# - BaseEnemy.gd (datos del enemigo)
# - Scene nodes: Textbox, ActionsPanel, AnimationPlayer

extends Control

signal textbox_closed

@export var enemy: Resource = null

var current_player_health = 0
var current_enemy_health = 0
var is_defending = false
var current_player_mp = 0
var is_reflex_active = false

func _ready():
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

func enemy_turn():
	display_text("%s launches at you fiercely!" % enemy.name)
	await self.textbox_closed

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
	$ActionsPanel.show()

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

func _on_Attack_pressed():
	display_text("You swing your piercing sword!")
	await self.textbox_closed
	
	current_enemy_health = max(0, current_enemy_health - State.damage)
	set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)

	$AnimationPlayer.play("enemy_damaged")
	await $AnimationPlayer.animation_finished
	
	display_text("You dealt %d damage!" % State.damage)
	await self.textbox_closed
	
	if current_enemy_health == 0:
		display_text("%s was defeated!" % enemy.name)
		await self.textbox_closed
		
		$AnimationPlayer.play("enemy_died")
		await $AnimationPlayer.animation_finished
		
		await get_tree().create_timer(0.25).timeout
		get_tree().quit()

	enemy_turn()

func _on_Defend_pressed():
	is_defending = true
	
	display_text("You prepare defensively!")
	await self.textbox_closed
	
	await get_tree().create_timer(0.25).timeout
	
	enemy_turn()
