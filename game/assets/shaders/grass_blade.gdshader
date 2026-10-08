// ใบหญ้าแบบเบา (ทีมทำเอง · license own) ใช้กับ world/grass_field.gd
// รูปใบหญ้าวาดจาก UV ไม่ต้องใช้ภาพ · ปลายใบโยกตามลม
shader_type spatial;
render_mode cull_disabled;

// สีโคนใบ
uniform vec3 base_color : source_color = vec3(0.16, 0.24, 0.08);
// สีปลายใบ
uniform vec3 tip_color : source_color = vec3(0.5, 0.56, 0.3);
// ลมแรงแค่ไหน (เมตรที่ปลายใบ)
uniform float wind_strength = 0.12;
// ลมพัดเร็วแค่ไหน
uniform float wind_speed = 1.4;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float bend = UV.y * UV.y;
	float wave = sin(TIME * wind_speed + world.x * 0.35 + world.z * 0.27);
	VERTEX.x += wave * wind_strength * bend;
	VERTEX.z += cos(TIME * wind_speed * 0.8 + world.x * 0.2) * wind_strength * 0.5 * bend;
}

void fragment() {
	// ใบหญ้า 7 ใบต่อแผ่น: เรียว กว้างที่โคน แหลมที่ปลาย
	float x = fract(UV.x * 7.0) - 0.5;
	float width = 0.28 * (1.0 - UV.y);
	if (abs(x) > width) {
		discard;
	}
	ALBEDO = mix(base_color, tip_color, UV.y);
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.25);
}
