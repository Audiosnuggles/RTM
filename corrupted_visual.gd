# corrupted_visual.gd
extends Sprite2D

var initial_scale: Vector2 = Vector2(1, 1) 
var click_flash_color: Color = Color(0.0, 0.8, 1.0) 
var sprite_switched = false # Status, um den Wechsel nur einmal auszuführen

func _ready():
	initial_scale = scale
	
# KORRIGIERT: Akzeptiert das 'position'-Argument
func apply_healing_visual(position: Vector2): 
	# (Die Position wird derzeit nicht verwendet, aber das Argument ist für das Signal notwendig)
	scale *= 1.15
	modulate = Color(1.0, 1.0, 1.0) 

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		if is_instance_valid(Combat) and not Combat.is_corrupted_healed:
			if is_visible_in_tree() and self.get_rect().has_point(to_local(event.position)):
				
				Combat.perform_click_impulse()
				
				scale *= 1.05 
				modulate = click_flash_color

func _process(_delta):
	# 1. Skalierung sanft zur Ursprungsgröße zurückführen
	self.scale = lerp(self.scale, initial_scale, _delta * 5.0)

	if is_instance_valid(Combat):
		
		# 2. Visueller Wechsel, wenn geheilt
		if Combat.is_corrupted_healed and not sprite_switched:
			switch_to_healed_sprite_internal() 
			sprite_switched = true
			
		elif not Combat.is_corrupted_healed:
			sprite_switched = false 
			
			# Farb-Steuerung für den HEILUNGS-FORTSCHRITT
			var percent = Combat.corrupted_current_health / Combat.corrupted_max_health
			var target_color = Color(1.0 - percent, 0.2, percent) 
			
			self.modulate = lerp(self.modulate, target_color, _delta * 10.0)

# Wird durch das Signal in Combat_Logic aufgerufen und setzt den Status
func switch_to_healed_sprite():
	if is_instance_valid(Combat):
		Combat.is_corrupted_healed = true

# Interne Funktion, die den visuellen Wechsel IMMER ausführt (wird in _process aufgerufen)
func switch_to_healed_sprite_internal():
	modulate = Color(1.0, 1.0, 1.0)
	
	var current_region = region_rect
	current_region.position.x = current_region.size.x 
	region_rect = current_region
