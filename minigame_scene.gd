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

# --- KORREKTUR 1 (Unbenutzter Parameter) ---
func _on_spikes_2_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.

# --- KORREKTUR 2 (Fehlende Funktion) ---
func _on_game_over_timer_timeout():
	pass # Diese Funktion wurde vom GameOverTimer in der .tscn-Datei erwartet
