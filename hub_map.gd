# hub_map.gd
extends Control

var main_scene_node: Node 

func _ready():
	# WICHTIG: Findet die MainScene über die Eltern-Hierarchie
	if is_instance_valid(get_parent()) and is_instance_valid(get_parent().get_parent()):
		main_scene_node = get_parent().get_parent()
	else:
		print("FEHLER (HubMap): MainScene konnte nicht gefunden werden.")


# Zentrale Funktion, die von den Button-Funktionen aufgerufen wird
func _on_mission_button_pressed(level_index: int):
	
	if is_instance_valid(main_scene_node) and main_scene_node.has_method("goto_combat"):
		
		# Starte den Kampf in der MainScene.
		main_scene_node.goto_combat(level_index)
		
	else:
		print("FEHLER KRITISCH (HubMap): MainScene ist ungültig ODER goto_combat() existiert nicht.")


# --- KORRIGIERTE SIGNAL-VERBINDUNGEN ---

func _on_mission_1_button_pressed():
	_on_mission_button_pressed(0)

func _on_mission_2_button_pressed():
	_on_mission_button_pressed(1)

func _on_mission_3_button_pressed():
	_on_mission_button_pressed(2)
	
func _on_mission_4_button_pressed():
	_on_mission_button_pressed(3)
	
func _on_mission_5_button_pressed():
	_on_mission_button_pressed(4)
