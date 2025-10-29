# MinigameScene.gd

extends Node2D

# Dieses Signal wird an die MainScene (die den Level geladen hat) gesendet
signal minigame_finished(success: bool)


# NEUE _READY FUNKTION
func _ready():
	# Finde die Kamera in DIESER Szene
	var camera = get_node_or_null("Player/Camera2D")
	if is_instance_valid(camera):
		# Mache sie zur aktiven Kamera, sobald das Minigame startet
		camera.make_current()
	else:
		print("FEHLER in minigame_scene.gd: Player/Camera2D nicht gefunden!")


# --- (Dein bisheriger Code bleibt gleich) ---

# Die Funktion für das Tor (Erfolg)
func _on_door_body_entered(body):
	if body.name == "Player":
		# Erfolg: Szene sofort freigeben
		minigame_finished.emit(true)
		queue_free()


# Methode, die vom Player oder Gegner aufgerufen wird, wenn er stirbt
func player_died():
	print("!!! player_died() aufgerufen. Szene wird sofort entfernt. !!!")
	
	# Sicherstellen, dass die Pause aufgehoben ist, falls sie in einem früheren Frame gesetzt wurde
	if get_tree().paused:
		get_tree().paused = false 
	
	# Sende das Misserfolgssignal an die MainScene und beende das Minigame
	minigame_finished.emit(false)
	queue_free()
