shader_type canvas_item;

// x = смещение по X, y = смещение по Y, z = наклон (skew)
uniform vec3 shadow_params = vec3(10.0, -15.0, 0.3);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec4 col = texture(TEXTURE, UV);

	// Рассчитываем UV для тени
	vec2 shadow_uv = UV;

	// 1. Применяем смещение из vec3.x и vec3.y
	shadow_uv -= vec2(shadow_params.x, shadow_params.y) * ps;

	// 2. Применяем наклон (skew) из vec3.z
	// Мы привязываем наклон к вертикальной координате (UV.y),
	// чтобы основание объекта оставалось на месте, а верхушка тени уходила вбок.
	shadow_uv.x += (UV.y - 1.0) * shadow_params.z;

	// Берем текстуру с новыми координатами
	vec4 shadow = texture(TEXTURE, shadow_uv);

	// Рисуем тень только там, где она не перекрывается основным спрайтом
	vec4 final_shadow = shadow_color;
	final_shadow.a *= shadow.a;

	// Смешиваем основной спрайт и тень
	COLOR = mix(final_shadow, col, col.a);
}