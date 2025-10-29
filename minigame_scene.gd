# minigame_scene.gd
extends Node2D

signal minigame_finished(success: bool)

func _on_door_body_entered(body):
    if body.name == "Player":
        minigame_finished.emit(true)
        queue_free()

func player_died():
    print("!!! player_died() aufgerufen !!!")
    if get_tree().paused:
        get_tree().paused = false 
    minigame_finished.emit(false)
    queue_free()
