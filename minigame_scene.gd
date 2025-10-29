# MinigameScene.gd

extends Node2D

# Dieses Signal wird an die MainScene (die den Level geladen hat) gesendet
signal minigame_finished(success: bool)

# KEINE _ready() FUNKTION HIER. Das ist wichtig.

# Die Funktion für das Tor (Erfolg)
func _on_door_body_entered(body):
	if body.name == "Player":
		# Erfolg: Szene sofort freigeben
		minigame_finished.emit(true)
		queue_free()


# Methode, die vom Player oder Gegner aufgerufen wird, wenn er stirbt
func player_died():
	print("!!! player_died() aufgerufen. Szene wird sofort entfernt. !!!")
	
	if get_tree().paused:
		get_tree().paused = false 
	
	minigame_finished.emit(false)
	queue_free()
