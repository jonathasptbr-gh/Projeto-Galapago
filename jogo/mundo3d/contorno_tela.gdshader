// Contorno em ESPAÇO DE TELA pela profundidade — pós-processo 3D num quad de
// tela cheia dentro do mundo do SubViewport (padrão "advanced post-processing"
// do Godot 4: QuadMesh 2×2, POSITION em clip space, extra_cull_margin grande;
// quem monta é a vista.gd). Substitui a casca invertida (casca.gdshader).
// Regra: o pixel vira LINHA se algum vizinho num disco de raio `raio` px
// estiver MAIS PERTO da câmera que ele por mais de `limiar` (unidades de
// mundo; a câmera é ortográfica, então profundidade de vista = distância ao
// longo do olhar). A linha cai por FORA do objeto da frente:
//  - base de contato (tronco, ator, quina de plataforma no chão): a diferença
//    vai a zero no contato ⇒ a linha afina e some sozinha;
//  - copa sobre o animal: linha sobre o animal, na borda da copa;
//  - sombra, marcas do chão e faixas do toon não são profundidade: sem linha;
//  - fundo sem geometria (profundidade = far) só vira linha encostado em
//    objeto, como qualquer fundo.
// Plano inclinado (chão visto em ângulo, parede rasante): o próprio pixel
// estima a inclinação local (diferença de 1 px, o MENOR dos dois lados em
// cada eixo — robusto encostado numa borda) e desconta |o|·g de cada vizinho:
// o chão não se contorna e a borda interna de esfera não engrossa.
// AA: 16 amostras (8 a `raio`, 8 a 0,55·`raio` giradas 22,5°); cada uma
// conta smoothstep(limiar_inicio, limiar, diferença); cobertura =
// soma / `saturacao` (≈ 3 no liso: borda externa suave, largura parecida em
// qualquer ângulo; 1 no Pixel Pass: 1 px nítido).
// Uniforms:
//   cor_contorno   source_color — cor da linha (a mesma da casca)
//   raio           px da textura de profundidade (= px renderizados)
//   limiar         unidades de mundo: diferença que dá linha cheia
//   limiar_inicio  unidades de mundo: onde a linha começa a aparecer (afinar)
//   saturacao      soma de amostras que dá cobertura 1
// Compila no Mobile (Vulkan) e no Compatibility (OpenGL 3): hint_depth_texture,
// INV_PROJECTION_MATRIX, VIEWPORT_SIZE e CURRENT_RENDERER (NDC z de 0..1 no
// Vulkan, −1..1 no OpenGL) — nada exclusivo do Forward+.
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

uniform vec4 cor_contorno : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float raio = 3.0;
uniform float limiar = 0.25;
uniform float limiar_inicio = 0.08;
uniform float saturacao = 3.0;
uniform sampler2D profundidade : hint_depth_texture, filter_nearest, repeat_disable;

void vertex() {
	// clip space direto: o quad 2×2 cobre a tela; z = 1 é o plano de perto
	// (reverse-z). O teste de profundidade está desligado de todo jeito.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// distância de vista (positiva) de uma profundidade crua
float vista_z(float d, mat4 inv_proj) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	float z = d * 2.0 - 1.0;
#else
	float z = d;
#endif
	// x, y não mexem em z/w (ortográfica e perspectiva simétrica)
	vec4 v = inv_proj * vec4(0.0, 0.0, z, 1.0);
	return -v.z / v.w;
}

float z_em(vec2 uv, mat4 inv_proj) {
	return vista_z(texture(profundidade, uv).r, inv_proj);
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float zc = z_em(uv, INV_PROJECTION_MATRIX);
	float zl = z_em(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float zr = z_em(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float zd = z_em(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float zu = z_em(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	vec2 g = vec2(min(abs(zr - zc), abs(zc - zl)), min(abs(zu - zc), abs(zc - zd)));

	float soma = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 dir = vec2(cos(a), sin(a));
		vec2 o = dir * raio;
		float dz = zc - z_em(uv + o * px, INV_PROJECTION_MATRIX) - dot(abs(o), g);
		soma += smoothstep(limiar_inicio, limiar, dz);
		vec2 o2 = vec2(cos(a + 0.392699), sin(a + 0.392699)) * (raio * 0.55);
		float dz2 = zc - z_em(uv + o2 * px, INV_PROJECTION_MATRIX) - dot(abs(o2), g);
		soma += smoothstep(limiar_inicio, limiar, dz2);
	}
	ALBEDO = cor_contorno.rgb;
	ALPHA = clamp(soma / saturacao, 0.0, 1.0) * cor_contorno.a;
}
