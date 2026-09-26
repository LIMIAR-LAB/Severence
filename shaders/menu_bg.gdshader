// Tela inicial animada: dá vida à ilustração estática assets/ui/menu.png sem precisar recortá-la.
// Tudo é calculado por região e por cor do pixel (fogo, brilho ciano, raios, olhos, água).
// O painel pintado à esquerda (x < 415 px) fica parado.
shader_type canvas_item;

uniform vec2 image_size = vec2(1344.0, 752.0);
uniform float flash = 0.0;         // relâmpago (0..1), controlado por scripts/menu_background.gd
uniform float bolt_crackle = 0.0;  // tremulação extra dos raios pintados
// engrenagens que giram: (x, y, raio, velocidade rad/s)
uniform vec4 gears[5];
// destroços que flutuam: (x, y, raio, fase)
uniform vec4 floaters[10];

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
vec2 rot(vec2 v, float a) { float c = cos(a); float s = sin(a); return vec2(c * v.x - s * v.y, s * v.x + c * v.y); }

void fragment() {
	vec2 px = UV * image_size;
	vec2 suv = UV;
	bool art = px.x > 415.0;   // fora do painel do menu
	float t = TIME;
	if (art) {
		// engrenagens girando (o pixel é buscado no ângulo girado dentro do círculo)
		for (int i = 0; i < 5; i++) {
			vec4 g = gears[i];
			if (g.z <= 0.0) continue;
			vec2 d = px - g.xy;
			float len = length(d);
			if (len < g.z) {
				float k = smoothstep(g.z, g.z - 4.0, len);
				suv = (g.xy + rot(d, t * g.w * k)) / image_size;
			}
		}
		// destroços flutuando no céu (sobe e desce devagar)
		for (int i = 0; i < 10; i++) {
			vec4 f = floaters[i];
			if (f.z <= 0.0) continue;
			vec2 d = px - f.xy;
			float k = smoothstep(f.z, f.z * 0.55, length(d));
			if (k > 0.0) {
				vec2 off = vec2(sin(t * 0.7 + f.w) * 1.6, sin(t * 1.1 + f.w * 1.7) * 3.2) * k;
				suv -= off / image_size;
			}
		}
		// água do porto: ondulação horizontal
		float water = smoothstep(990.0, 1030.0, px.x) * smoothstep(470.0, 500.0, px.y) * (1.0 - smoothstep(610.0, 640.0, px.y));
		if (water > 0.0) {
			suv.x += sin(px.y * 0.42 + t * 2.2) * 1.4 / image_size.x * water;
			suv.y += sin(px.x * 0.06 + t * 1.3) * 0.7 / image_size.y * water;
		}
		// calor sobre o fogo das casas à esquerda
		float heat = smoothstep(415.0, 440.0, px.x) * (1.0 - smoothstep(590.0, 620.0, px.x)) * smoothstep(380.0, 420.0, px.y) * (1.0 - smoothstep(560.0, 580.0, px.y));
		suv.x += sin(px.y * 0.25 - t * 6.0) * 0.8 / image_size.x * heat;
	}
	vec4 col = texture(TEXTURE, suv);
	if (art) {
		vec3 c = col.rgb;
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		// fogo e luzes quentes: tremulam
		float fire = step(0.72, c.r) * step(0.28, c.g) * step(c.g, 0.85) * step(c.b, 0.38);
		if (fire > 0.0) {
			float n = noise(px * 0.045 + vec2(0.0, -t * 3.0)) * 0.6 + noise(px * 0.11 + vec2(t * 1.5, -t * 5.0)) * 0.4;
			c *= 0.82 + 0.42 * n;
			c += vec3(0.12, 0.05, 0.0) * n;
		}
		// brilho ciano (núcleo e olhos do robô, óculos, armas): pulsa
		float cyan = step(0.55, c.g) * step(0.65, c.b) * step(c.r, 0.55);
		if (cyan > 0.0) {
			float p = 0.5 + 0.5 * sin(t * 2.6 + (px.x > 780.0 && px.x < 900.0 ? 0.0 : px.x * 0.01));
			c += vec3(0.08, 0.35, 0.4) * p;
		}
		// raios roxos/azuis pintados no céu: crepitam e acendem com o relâmpago
		float sky = 1.0 - smoothstep(330.0, 430.0, px.y);
		float bolt = sky * step(0.55, lum) * step(0.7, c.b) * step(c.g, 0.95);
		if (bolt > 0.0) {
			float crack = noise(px * 0.08 + vec2(t * 9.0, t * 4.0));
			c *= 0.75 + 0.45 * crack + 0.6 * flash + 0.3 * bolt_crackle;
		}
		// olhos do monstro (amarelos no céu): pulsam devagar
		float eye = step(px.y, 210.0) * step(0.8, c.r) * step(0.6, c.g) * step(c.b, 0.45);
		if (eye > 0.0) c += vec3(0.5, 0.35, 0.0) * (0.5 + 0.5 * sin(t * 1.4));
		// reflexos no mar e na calçada molhada: cintilam
		float reflect = step(420.0, px.y) * step(0.6, c.r) * step(0.35, c.g) * step(c.b, 0.4) * smoothstep(600.0, 680.0, px.x);
		if (reflect > 0.0) c *= 0.8 + 0.5 * step(0.6, noise(px * 0.2 + vec2(t * 2.0, 0.0)));
		// clarão do relâmpago: céu azulado, tudo um pouco mais claro
		c += vec3(0.28, 0.26, 0.55) * flash * (0.35 + 0.65 * sky);
		col.rgb = c;
	}
	COLOR = col;
}
