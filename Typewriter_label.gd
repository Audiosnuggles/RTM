# TypewriterLabel.gd

extends RichTextLabel

@export var typing_speed: float = 0.05 
@export var initial_delay: float = 0.5 

var full_text: String = ""
var text_length: int = 0
var char_index: int = 0
var timer: Timer
var is_typing: bool = false 

signal typing_finished

func _ready():
	# 1. Timer Node erstellen
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	
	# 2. Den vollen Text initial speichern
	full_text = text
	text_length = full_text.length()
	
	# NEU HINZUFÜGEN: BBCode-Parsing aktivieren, damit [color=red] funktioniert
	bbcode_enabled = true
	
	# 3. Text verstecken
	visible_characters = 0
	

# KORRIGIERT: Liest den Text neu aus, bevor die Animation startet
func start_typing():
	
	# LESE DEN NEUEN TEXT AUS DEM LABEL-NODE aus (falls extern geändert)
	full_text = text 
	text_length = full_text.length()
	
	if is_typing:
		return
		
	char_index = 0
	is_typing = true
	
	# Verzögerung starten
	if initial_delay > 0:
		timer.start(initial_delay)
		await timer.timeout 
		
	# Startet die eigentliche Tipp-Animation
	timer.wait_time = typing_speed
	timer.start()

func _on_timer_timeout():
	if char_index < text_length:
		char_index += 1
		visible_characters = char_index
		timer.start()
	else:
		timer.stop()
		is_typing = false
		typing_finished.emit()
		
func skip_typing():
	if is_typing:
		timer.stop()
		visible_characters = text_length
		char_index = text_length
		is_typing = false
		typing_finished.emit()
