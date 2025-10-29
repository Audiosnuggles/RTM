extends RichTextLabel

@export var typing_speed: float = 0.05 # Sekunden pro Zeichen (0.05s ist schnell)
@export var initial_delay: float = 0.5  # Verzögerung vor dem Start

var full_text: String = ""
var text_length: int = 0
var char_index: int = 0
var timer: Timer
var is_typing: bool = false # Status-Indikator

# Signal, das gesendet wird, wenn die Animation abgeschlossen ist
signal typing_finished

func _ready():
	# Timer Node erstellen
	timer = Timer.new()
	add_child(timer)
	
	# Timer mit der Methode _on_timer_timeout verbinden
	timer.timeout.connect(_on_timer_timeout)
	
	# Den vollen Text aus der Inspector-Eigenschaft speichern
	full_text = text
	
	# WICHTIG: Setze visible_characters auf 0, um den Text zu verstecken
	visible_characters = 0
	text_length = full_text.length()
	
	# Wenn ein Start-Delay definiert ist, diesen zuerst ablaufen lassen
	if initial_delay > 0:
		timer.start(initial_delay)
		await timer.timeout
	
	# Startet die Schreibanimation
	start_typing()

func start_typing():
	char_index = 0
	is_typing = true
	timer.wait_time = typing_speed
	timer.start()

func _on_timer_timeout():
	if char_index < text_length:
		# Erhöht die Anzahl der sichtbaren Zeichen
		char_index += 1
		visible_characters = char_index
		
		# Setzt den Timer neu für das nächste Zeichen
		timer.start()
	else:
		# Animation abgeschlossen
		timer.stop()
		is_typing = false
		typing_finished.emit()
		
func skip_typing():
	# Ermöglicht das Überspringen der Animation
	if is_typing:
		timer.stop()
		visible_characters = text_length
		char_index = text_length
		is_typing = false
		typing_finished.emit()
