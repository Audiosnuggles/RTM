# HubMap.gd
extends Control

var main_scene_node: Node 

func _ready():
	# WICHTIG: Findet die MainScene über die Eltern-Hierarchie
	# Geht davon aus: HubMap -> UI_Layer -> MainScene (Root Node)
	if is_instance_valid(get_parent()) and is_instance_valid(get_parent().get_parent()):
		main_scene_node = get_parent().get_parent()
		print("HubMap gefunden. MainScene-Knotenname: " + main_scene_node.name)
	else:
		print("FEHLER: MainScene konnte über die Eltern-Knoten nicht gefunden werden.")


# Zentrale Funktion, die von den Button-Funktionen aufgerufen wird
func _on_mission_button_pressed(level_index: int):
	
	print("Button pressed für Level: " + str(level_index))
	
	# Sicherstellen, dass die MainScene und die Ziel-Funktion existieren
	if is_instance_valid(main_scene_node) and main_scene_node.has_method("goto_combat"):
		
		# Starte den Kampf in der MainScene.
		main_scene_node.goto_combat(level_index)
		
	else:
		print("FEHLER KRITISCH: MainScene ist ungültig ODER goto_combat() existiert nicht.")
		print("Aktueller MainScene Node-Status: ", is_instance_valid(main_scene_node))


# --- KORRIGIERTE SIGNAL-VERBINDUNGEN (ALLES KLEIN GESCHRIEBEN) ---
# Die Button-Signale im Editor MÜSSEN mit diesen Funktionen verbunden sein!

func _on_mission_1_button_pressed():
	# Level-Index 0
	_on_mission_button_pressed(0)

func _on_mission_2_button_pressed():
	# Level-Index 1
	_on_mission_button_pressed(1)

func _on_mission_3_button_pressed():
	# Level-Index 2
	_on_mission_button_pressed(2)
