# MinigameScene.gd (Sofortige Szene-Freigabe ohne Pause/Timer)

extends Node2D

# Dieses Signal wird an die MainScene (die den Level geladen hat) gesendet
signal minigame_finished(success: bool)

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
