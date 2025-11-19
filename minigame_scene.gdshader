/*
DOOM Melting Screen-like shader!
*/
shader_type canvas_item;

// Muss in Godot 4 fuer Screen-Space-Effekte verwendet werden
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform uint subdivisions = 2; // How many subdivisions
uniform float movement: hint_range(0.0, 1.0, 0.01); // Control for animation

// Random and noise code from godotshaders.com
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


void fragment() {
	// KORRIGIERT: SCREEN_UV und SCREEN_PIXEL_SIZE verwenden
	float offset = max(noise(vec2(SCREEN_UV.x / (SCREEN_PIXEL_SIZE.x * float(uint(textureSize(SCREEN_TEXTURE, 0).x) / subdivisions)), 1.0)), 0.0);
	
	// Offset column
	float target_y = SCREEN_UV.y - (movement + offset) * movement;
	
    // Hole die Farbe von der verschobenen Koordinate
	vec4 game_color = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, target_y));
    
    // Definiere die schwarze Hintergrundfarbe
    vec4 bg_color = vec4(0.0, 0.0, 0.0, 1.0); 
    
    // Erstelle Maske: step(0.0, target_y) wird 0.0 (Schwarz), wenn target_y < 0.0 ist
	float mask = step(0.0, target_y);
    
    // Mische zwischen Schwarz und dem Spielbild
	COLOR = mix(bg_color, game_color, mask);
}