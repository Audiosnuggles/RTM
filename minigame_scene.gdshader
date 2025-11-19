// DIESER CODE GEHÖRT IN: minigame_scene.gdshader

shader_type canvas_item;

// Wir müssen SCREEN_TEXTURE in Godot 4 explizit anfordern
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// KORREKTUR: subdivisions zu float und Standardwert für sichtbare Wellen
uniform float subdivisions = 20.0; // How many subdivisions
uniform float movement: hint_range(0.0, 1.0, 0.01); // Control for animation

// --- (Noise/Random Funktionen bleiben gleich) ---
vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
              dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}
float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                   dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), uv_fract.x),
               mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                   dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), uv_fract.x), uv_fract.y) + 0.5;
}
// --- (Ende Noise/Random) ---


void fragment() {
    // 1. KORREKTUR: Erzeuge 2D-Noise (melt/jiggle)
    // Das Rauschen variiert in x UND y, um eine wellige Kante zu erzeugen.
	float noise_y_offset = noise(SCREEN_UV.xy * subdivisions); // Noise liegt im Bereich [0.0, 1.0]
    
    // 2. Berechnung der vertikalen Verzerrung (Wipe + Melt)
    // 0.2 ist die Stärke der Verwerfung. Der Gesamtversatz wird mit 'movement' skaliert.
	float distortion_offset = noise_y_offset * 0.2 * movement;
    
    // Die Y-Koordinate, aus der wir lesen: (Aktuelle Y) - (Gesamtversatz nach unten)
	float target_y = SCREEN_UV.y - (movement + distortion_offset);
    
    // 3. Texture Sampling und Maskierung
	vec4 game_color = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, target_y));
    
	vec4 bg_color = vec4(0.0, 0.0, 0.0, 1.0); // Schwarz
	
    // Erstelle Maske: Wenn target_y kleiner als 0.0 ist (Bild ist weggewischt), wird mask=0.0
	float mask = step(0.0, target_y);
	
	// Mische zwischen Schwarz (mask=0.0) und dem Spiel (mask=1.0)
	COLOR = mix(bg_color, game_color, mask);
}