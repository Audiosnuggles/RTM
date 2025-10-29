# story_intro.gd
extends Control

var main_scene_node: Node 

func _ready():
	# WICHTIG: Findet die MainScene über die Eltern-Hierarchie
	if is_instance_valid(get_parent()) and is_instance_valid(get_parent().get_parent()):
		main_scene_node = get_parent().get_parent()
	else:
		print("FEHLER (StoryIntro): MainScene konnte nicht gefunden werden.")

# Muss mit dem "Next_Button" verbunden sein
func _on_next_button_pressed():
	
	if not is_instance_valid(main_scene_node):
		print("FEHLER (StoryIntro): Kann nicht navigieren, MainScene ist ungültig.")
		return

	if main_scene_node.has_method("goto_hub_map"):
		hide() 
		main_scene_node.goto_hub_map() 
	else:
		print("FEHLER (StoryIntro): Methode 'goto_hub_map' existiert NICHT in MainScene!")
