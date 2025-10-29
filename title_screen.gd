# TitleScreen.gd
extends Control

var main_scene_node: Node 

func _ready():
	# Suche den korrekten Haupt-Node (MainScene)
	var root_children = get_tree().root.get_children()
	
	# Durchlaufe alle Root-Nodes, um den Node mit dem Namen 'MainScene' zu finden
	for child in root_children:
		if child.name == "MainScene":
			main_scene_node = child
			print("DEBUG: Korrekter MainScene-Node gefunden: ", main_scene_node.name)
			break
			
	if not is_instance_valid(main_scene_node):
		print("FEHLER: MainScene-Node konnte im Baum NICHT eindeutig gefunden werden.")


# DIES IST DIE KORRIGIERTE FUNKTION: Sie muss mit dem Button-Namen übereinstimmen!
func _on_button_start_pressed():
	# 1. Prüfen, ob die MainScene-Referenz gültig ist
	if not is_instance_valid(main_scene_node):
		print("FEHLER: MainScene-Referenz ist ungültig. Kann nicht navigieren.")
		return

	# 2. Prüfen, ob die Navigationsmethode in der MainScene existiert
	if main_scene_node.has_method("goto_story_intro"):
		
		# 3. Bestätigung 
		print("ERFOLG: TitleScreen Button gedrückt. Rufe MainScene.goto_story_intro() auf.")
		
		# 4. Verstecke den Titelbildschirm
		hide() 
		
		# 5. Rufe die Navigationsfunktion auf
		main_scene_node.goto_story_intro()
	else:
		# Dieser Fehler sollte jetzt nicht mehr erscheinen!
		print("FEHLER: Die Methode 'goto_story_intro' existiert nicht in MainScene.gd!")
