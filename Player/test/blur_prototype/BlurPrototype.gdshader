shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float inner_iterations: hint_range(0.0, 50.0, 1.0) = 12.0;

uniform vec2 center = vec2(0.5);
uniform float inner_power: hint_range(-10.0, 10.0, 0.01) = 2.0;

uniform float radius: hint_range(0.0,1.0, 0.01) = 0.0;
uniform float outer_radius: hint_range(0.0,1.0, 0.01) = 0.0;


void fragment() {
	vec2 uv = UV;
	vec2 dir = center - uv;
	float magnitude_x = center.x - UV.x;
	float magnitude_y = center.y - UV.y;
	float len = sqrt(pow(magnitude_x, 2.0) + pow(magnitude_y, 2.0));
	vec2 norm_dir = dir/len;

	vec2 outer_radi_point = abs(norm_dir) * (radius + outer_radius + 0.5) ;
	float intensity = sqrt(pow(UV.x - outer_radi_point.x, 2.0) + pow(UV.y - outer_radi_point.y, 2.0));

	vec2 blur = norm_dir * inner_power  * intensity * 0.01;
	vec4 color = textureLod(screen_texture, UV, 0.0);

	if (len >= radius && len <= radius + outer_radius){
		for (float i = 0.0; i < inner_iterations; i++){
			color += texture(screen_texture, uv);
			uv += blur;
		}

		color /= inner_iterations;
		COLOR = color;

	}
}