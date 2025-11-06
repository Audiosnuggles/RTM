# title_screen.gd (KORRIGIERTE VERSION)
extends Control

var main_scene_node: Node 

func _ready():
	# WICHTIG: Findet die MainScene über die Eltern-Hierarchie
	var parent_ui = get_parent()
	
	if is_instance_valid(parent_ui) and is_instance_valid(parent_ui.get_parent()):
		main_scene_node = parent_ui.get_parent()
		print("DEBUG (TitleScreen): MainScene gefunden: ", main_scene_node.name) # Debug-Ausgabe
	else:
		print("FEHLER (TitleScreen): MainScene konnte nicht gefunden werden.")

# Muss mit dem "Button_Start" verbunden sein
func _on_button_start_pressed():
	
	if not is_instance_valid(main_scene_node):
		print("FEHLER (TitleScreen): MainScene-Referenz ist ungültig.")
		return
		
	# KORREKTUR: Fügen wir hier die Fade-Logik ein, die wir in main_scene.gd haben, 
	# damit wir den Zoom sanft stoppen können, bevor wir weiterleiten.
	# Da dies in title_screen.gd nicht geht (da dort die fade_screen-Variable nicht existiert),
	# muss die Logik in main_scene.gd ausgeführt werden.
	
	# Der Aufruf an die MainScene ist korrekt:
	if main_scene_node.has_method("_on_button_start_pressed"):
		# Wir rufen die Hauptfunktion in MainScene auf, die den Zoom beendet und navigiert
		main_scene_node._on_button_start_pressed()
	else:
		print("FEHLER (TitleScreen): Methode '_on_button_start_pressed' existiert nicht in MainScene!")
