# MinigameScene.gd
# KORRIGIERTE VERSION (Mit 3-Sekunden Verzögerung am Ende)

extends Node2D

# Dieses Signal wird an die MainScene (die den Level geladen hat) gesendet
signal minigame_finished(success: bool)

# Referenz auf den Game Over-Effekt-Layer
@onready var game_over_screen = $GameOverScreen
# Referenz auf den Game Over-Text-Layer
@onready var game_over_ui = $GameOverUI


func _ready():
	# 1. Beide Layer zu Beginn verstecken
	if is_instance_valid(game_over_screen):
		game_over_screen.hide()
		
		# 2. Den Shader-Parameter "movement" auf 0 zurücksetzen
		var shader_mat = game_over_screen.get_node("MeltEffect").material as ShaderMaterial
		if is_instance_valid(shader_mat):
			shader_mat.set_shader_parameter("movement", 0.0)
	
	# 3. Den UI-Layer verstecken und Text zurücksetzen
	if is_instance_valid(game_over_ui):
		game_over_ui.hide()
		var try_again_label = game_over_ui.get_node_or_null("TryAgainLabel")
		if is_instance_valid(try_again_label):
			try_again_label.modulate.a = 0.0


# Die Funktion für das Tor (Erfolg)
func _on_door_body_entered(body):
	if body.name == "Player":
		minigame_finished.emit(true)
		

# Diese Funktion wird "async", weil sie "await" verwendet
func player_died() -> void:
	print("!!! player_died() aufgerufen. Starte Game Over Sequenz. !!!")
	await start_game_over_sequence()


# Diese Funktion spielt die Schmelz-Animation ab
func start_game_over_sequence():
	
	# Hole Referenz zum Shader-Material
	var shader_mat = game_over_screen.get_node("MeltEffect").material as ShaderMaterial
	
	# Hole Referenz auf das Label
	var try_again_label = game_over_ui.get_node_or_null("TryAgainLabel")
	
	if not is_instance_valid(shader_mat):
		print("FEHLER: ShaderMaterial auf GameOverScreen/MeltEffect nicht gefunden!")
		minigame_finished.emit(false) 
		return
		
	shader_mat.set_shader_parameter("movement", 0.0)
	
	# Sicherstellen, dass das Label unsichtbar ist
	if is_instance_valid(try_again_label):
		try_again_label.modulate.a = 0.0
	
	# BEIDE Layer einblenden
	game_over_screen.show()
	game_over_ui.show()
	
	# Sag diesem Node (minigame_scene), dass er weiterlaufen soll
	self.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Spiel pausieren
	get_tree().paused = true 
	
	
	# --- TWEEN 1: DIE ANIMATION (SCHMELZEN & TEXT) ---
	var anim_tween = create_tween()
	
	# Animation 1: "movement"-Parameter animieren (Schmelzen)
	anim_tween.tween_property(shader_mat, "shader_parameter/movement", 1.0, 1.5)
	
	# Animation 2 (parallel): Text einblenden (mit 0.2s Verzögerung)
	if is_instance_valid(try_again_label):
		anim_tween.tween_property(try_again_label, "modulate:a", 1.0, 1.0).set_delay(0.2)
	
	# Warten, bis BEIDE Animationen fertig sind
	await anim_tween.finished
	
	
	# --- TWEEN 2: DIE 3-SEKUNDEN-VERZÖGERUNG (NEU) ---
	# (Dieser Tween funktioniert, weil 'self.process_mode' auf WHEN_PAUSED steht)
	var delay_tween = create_tween()
	delay_tween.tween_interval(3.0) # Warte 3 Sekunden
	await delay_tween.finished
	
	
	# --- AUFRÄUMEN ---
	
	# Layer wieder verstecken für den Neustart
	game_over_screen.hide()
	game_over_ui.hide()
	get_tree().paused = false 
	self.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Signal erst senden, NACHDEM die Verzögerung fertig ist
	minigame_finished.emit(false) 


# --- (Restliche Funktionen) ---

func _on_spikes_2_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.

func _on_game_over_timer_timeout():
	pass


func _on_herz_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_stomp_detector_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
