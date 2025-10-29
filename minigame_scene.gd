# minigame_scene.gd
extends Node2D

signal minigame_finished(success: bool)

func _on_door_body_entered(body):
	if body.name == "Player":
		get_tree().paused = true
		
		# KORRIGIERT: Verwendet einen unpausierbaren SceneTreeTimer
		await get_tree().create_timer(0.5, false).timeout
		
		get_tree().paused = false
		
		minigame_finished.emit(true)
		queue_free()

func player_died():
	get_tree().paused = true
	
	# KORRIGIERT: Verwendet einen unpausierbaren SceneTreeTimer
	await get_tree().create_timer(1.0, false).timeout 
	
	get_tree().paused = false
	
	minigame_finished.emit(false)
	queue_free()
