# MinigameScene.gd
# NEUE VERSION (OHNE queue_free())

extends Node2D

# Dieses Signal wird an die MainScene (die den Level geladen hat) gesendet
signal minigame_finished(success: bool)

# Die Funktion für das Tor (Erfolg)
# (Diese muss im Editor mit dem 'body_entered'-Signal des Door-Nodes verbunden werden!)
func _on_door_body_entered(body):
	if body.name == "Player":
		# Erfolg: Nur das Signal senden. MainScene kümmert sich um das Löschen.
		minigame_finished.emit(true)
		
		# "queue_free()" HIER ENTFERNT


# Methode, die vom Player (MinigamePlayer.gd) aufgerufen wird, wenn er stirbt
func player_died():
	print("!!! player_died() aufgerufen. Sende Signal an MainScene. !!!")
	
	if get_tree().paused:
		get_tree().paused = false 
	
	# Misserfolg: Nur das Signal senden. MainScene kümmert sich um das Löschen.
	minigame_finished.emit(false)
	
	# "queue_free()" HIER ENTFERNT
