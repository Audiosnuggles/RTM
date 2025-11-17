shader_type canvas_item;

uniform float open_amount : hint_range(0.0, 1.0, 0.01);
uniform float edge_blur_amount : hint_range(0.0, 1.0, 0.01);
uniform vec3 color : source_color;

void fragment() {
	float blur = edge_blur_amount * 0.5;
	float v = open_amount + edge_blur_amount * open_amount;
	float d1 = (2.0 * v * pow(UV.x - 0.5, 2.0) - v/2.0 + 0.5) - (UV.y+v/(2.0));
	float d2 = -(-2.0 * v * pow(UV.x - 0.5, 2.0) + v/2.0 + 0.5) + (UV.y-v/(2.0));
	float d = max(d1, d2);

	if (d > -blur){
		COLOR = vec4(color, (-d-blur)/-blur);
	} else {
		COLOR = vec4(0.0);
	}
}
