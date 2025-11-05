shader_type canvas_item;

// Wie rund die Ecken sein sollen (0.0 = eckig, 0.5 = voll abgerundet)
uniform float corner_radius : hint_range(0.0, 0.5) = 0.1;


// Helfer-Funktion, die die Formel für ein abgerundetes Rechteck definiert
float sd_rounded_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}


// Die Haupt-Funktion, die jeden Pixel zeichnet
void fragment() {
	// (COLOR enthält bereits die Textur *multipliziert* mit dem Modulate-Wert (Glow))
	
	// Berechnen, wie weit der Pixel von der Kante entfernt ist
	vec2 uv_dist = abs(UV - vec2(0.5));
	
	// Prüfen, ob der Pixel im "abgerundeten" Bereich liegt
	float in_rect = sd_rounded_box(uv_dist * 2.0, vec2(1.0), corner_radius);
	
	// --- KORREKTUR: Pixel komplett verwerfen ---
	// Wenn der Pixel außerhalb liegt (in_rect > 0.0), verwirf ihn.
	if (in_rect > 0.0) {
		discard; // Statt COLOR.a = 0.0;
	}
	
	// Nur Pixel, die NICHT verworfen wurden, werden gezeichnet (und leuchten).
}