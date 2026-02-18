shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Color a eliminar
uniform float similarity : hint_range(0.0, 1.0) = 0.4; // Qué tanto se parece
uniform float smoothness : hint_range(0.0, 1.0) = 0.08; // Suavizado de bordes

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	float diff = distance(texture_color.rgb, key_color.rgb);
	float alpha = smoothstep(similarity, similarity + smoothness, diff);
	COLOR = vec4(texture_color.rgb, texture_color.a * alpha);
}