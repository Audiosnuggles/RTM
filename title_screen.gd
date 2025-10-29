# title_screen.gd
extends Control

var main_scene_node: Node 

func _ready():
	# WICHTIG: Findet die MainScene über die Eltern-Hierarchie
	if is_instance_valid(get_parent()) and is_instance_valid(get_parent().get_parent()):
		main_scene_node = get_parent().get_parent()
	else:
		print("FEHLER (TitleScreen): MainScene konnte nicht gefunden werden.")

# Muss mit dem "Button_Start" verbunden sein
func _on_button_start_pressed():
	
	if not is_instance_valid(main_scene_node):
		print("FEHLER (TitleScreen): MainScene-Referenz ist ungültig.")
		return

	if main_scene_node.has_method("goto_story_intro"):
		hide() 
		main_scene_node.goto_story_intro()
	else:
		print("FEHLER (TitleScreen): Methode 'goto_story_intro' existiert nicht in MainScene!")
