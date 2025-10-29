# StoryIntro.gd
extends Control

var main_scene_node: Node 

func _ready():
	# 1. FALLS-SICHERE SUCHE NACH DER MAIN SCENE
	# Wir suchen im gesamten Baum nach der Scene, die das Haupt-Skript haelt
	
	# Pruefe den direkten Parent des UI_Layer's
	if get_parent() and get_parent().get_parent():
		var assumed_main_scene = get_parent().get_parent()
		if is_instance_valid(assumed_main_scene) and assumed_main_scene.is_class("Node2D"):
			main_scene_node = assumed_main_scene
			print("DEBUG (StoryIntro): MainScene-Node ueber Parent-Pfad gefunden: ", main_scene_node.name)

	# Fallback-Suche
	if not is_instance_valid(main_scene_node):
		var root_children = get_tree().root.get_children()
		for child in root_children:
			if child.name.to_lower() == "mainscene":
				main_scene_node = child
				print("DEBUG (StoryIntro): MainScene-Node ueber Root-Baum gefunden: ", main_scene_node.name)
				break
			
	if not is_instance_valid(main_scene_node):
		print("FEHLER KRITISCH (StoryIntro): MainScene-Node konnte NICHT gefunden werden.")

# KORRIGIERT: Methode MUSS klein geschrieben sein, um dem Signal zu entsprechen!
func _on_next_button_pressed():
	
	print("DEBUG (StoryIntro): Funktion _on_next_button_pressed() AUFGERUFEN. Starte Pruefung.")
	
	# 1. Pruefen, ob die MainScene-Referenz gueltig ist
	if not is_instance_valid(main_scene_node):
		print("FEHLER (StoryIntro): main_scene_node ist UNGUELTIG.")
		return

	# 2. Pruefen, ob die Ziel-Methode existiert
	if main_scene_node.has_method("goto_hub_map"):
		
		# 3. Navigation ausfuehren
		hide() 
		main_scene_node.goto_hub_map() 
		print("ERFOLG (StoryIntro): Navigation zur HubMap gestartet.")
	else:
		print("FEHLER (StoryIntro): Methode 'goto_hub_map' existiert NICHT in der gefundenen Scene (", main_scene_node.name, ")!")
