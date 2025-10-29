# Door.gd

extends Area2D

# ENTFERNT: signal minigame_success  <-- DIESE ZEILE ENTFERNEN

func _on_body_entered(body):
	# Prüfen, ob das Element, das kollidiert ist, der Spieler ist
	if body.name == "Player":
		# Wenn der Spieler die Tür erreicht, senden wir das Erfolgssignal an die Root-Szene
		# Wir rufen direkt die Funktion in MinigameScene.gd auf
		get_parent()._on_door_body_entered(body)
