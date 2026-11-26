// Contorno em ESPAÇO DE TELA pela profundidade — pós-processo 3D num quad de
// tela cheia dentro do mundo do SubViewport (padrão "advanced post-processing"
// do Godot 4: QuadMesh 2×2, POSITION em clip space, extra_cull_margin grande;
// quem monta é a vista.gd). Substitui a casca invertida (casca.gdshader).
// Duas linhas, somadas pela maior cobertura:
// (1) PROFUNDIDADE (silhueta): o pixel vira LINHA se algum vizinho num disco
// de raio `raio` px estiver MAIS PERTO da câmera que ele por mais de `limiar`
// (unidades de mundo; a câmera é ortográfica, então profundidade de vista =
// distância ao longo do olhar). A linha cai por FORA do objeto da frente:
//  - base de contato (tronco, ator, quina de plataforma no chão): a diferença
//    vai a zero no contato ⇒ a linha afina e some sozinha — o VINCO continua;
//  - copa sobre o animal: linha sobre o animal, na borda da copa;
//  - sombra, marcas do chão e faixas do toon não são profundidade: sem linha;
//  - fundo sem geometria (profundidade = far) só vira linha encostado em
//    objeto, como qualquer fundo.
// Plano inclinado (chão visto em ângulo, parede rasante): o próprio pixel
// estima a inclinação local (diferença de 1 px, o MENOR dos dois lados em
// cada eixo — robusto encostado numa borda) e desconta |o|·g de cada vizinho
// (o = offset INTEIRO do texel lido: o filtro é nearest): o chão não se
// contorna e a borda interna de esfera não engrossa.
// AA: 16 amostras (8 a `raio`, 8 a 0,55·`raio` giradas 22,5°); cada uma
// conta smoothstep(limiar_inicio, limiar, diferença); cobertura =
// soma / `saturacao` (≈ 3 no liso: borda externa suave, largura parecida em
// qualquer ângulo; 1 no Pixel Pass: 1 px nítido).
// (2) VINCO (S7): linha onde a orientação da superfície muda bruscamente —
// parede×chão, topo×lateral de caixa, rampa×parede, quina que desce até o
// chão. Normal de vista pela profundidade: n = normalize(∂D/∂X, ∂D/∂Y, −1)
// (D = distância, X/Y em unidades de mundo: px × `w`, o tamanho do pixel no
// mundo da projeção ortográfica). No centro: o QUADRANTE mais plano (a
// diagonal confere; escolher x e y separados misturava os dois planos).
// MSAA (liso, `profundidade_msaa`): o resolve da profundidade (Vulkan Mobile:
// MAX = a sub-amostra mais perto; Forward+/OpenGL: média) dá ao pixel EM CIMA
// de uma quina um CHANFRO de ~1 px, fora dos dois planos — e só quando as
// faces caem em sub-amostras diferentes (depende do ângulo). Com `zc` nas
// diferenças a normal do centro saía híbrida e a linha clareava NO MEIO. Por
// isso o centro não usa `zc`: braços de 1 e 2 px para fora em x e y, cada um
// extrapola o plano no centro; erro = desencontro dos dois + a diagonal; `zp`
// (profundidade do PLANO no centro) substitui `zc` na oclusão e no ponto do
// meio; plano dos braços longe de `zc` (C na borda de objeto, braços no
// fundo) é penalizado. Pixel Pass (sem MSAA): diferenças de 1 px com `zc`.
// Anel do vinco: o interno (0,55·`raio`, reusado da linha 1) quando tem ≥ 2
// px; o externo no Pixel Pass (os 8 vizinhos). Em cada amostra S (geometria do
// texel lido), 2 vizinhos de 1 px PARA FORA; um salto ali (silhueta) descarta
// S. S conta (até 1) quando:
//  - o ângulo entre as normais passa de `limiar_vinco_graus` (rampa de
//    ±`banda_vinco_graus`): 75° deixa de fora as facetas da copa (51–58°), o
//    tronco (60°), a borda do topo da pedra (68°) e a cápsula do ator;
//  - o ponto do meio C→S cai num dos dois planos (um vinco só; faceta estreita
//    no meio, perto da silhueta da copa, não conta) — fora do Pixel Pass; com
//    MSAA, folga de meio px da diferença de inclinação (o meio que cai no
//    chanfro do próprio vinco não é faceta);
//  - não é oclusão com folga: centro à frente do plano de S e S atrás do plano
//    do centro (ou o inverso) por mais que `limiar_inicio`..`limiar` — aí a
//    linha (1) desenha. Vinco de verdade (convexo: os dois atrás do plano do
//    outro; côncavo: os dois à frente) ou oclusão encostada (contato) passa.
// Cobertura = soma / `saturacao_vinco` (2 no liso; 1 no Pixel Pass); a final é
// a maior das duas. Liso: linha CENTRADA no vinco (±0,55·`raio`, a largura da
// (1)). Pixel Pass (`vinco_um_lado`): só o lado mais rasante marca, 1 px.
// Leituras de profundidade por pixel: 1 centro + 4 em cruz + 4 diagonais +
// 4 braços de 2 px + 16 do anel (linha 1) + 16 vizinhos do vinco + 8 pontos
// do meio = 53 no liso (41 no Pixel Pass: sem braços de 2 px nem ponto do meio).
// Uniforms:
//   cor_contorno      source_color — cor da linha (a mesma da casca)
//   raio              px da textura de profundidade (= px renderizados)
//   limiar            unidades de mundo: diferença que dá linha cheia
//   limiar_inicio     unidades de mundo: onde a linha começa a aparecer (afinar)
//   saturacao         soma de amostras que dá cobertura 1
//   limiar_vinco_graus  ângulo entre normais que dá vinco (meio da rampa)
//   banda_vinco_graus   meia-largura da rampa do ângulo
//   saturacao_vinco     soma de amostras do vinco que dá cobertura 1
//   vinco_um_lado       só o lado mais rasante marca (Pixel Pass)
//   profundidade_msaa   profundidade resolvida de MSAA (liso): centro sem `zc`
// Compila no Mobile (Vulkan) e no Compatibility (OpenGL 3): hint_depth_texture,
// INV_PROJECTION_MATRIX, VIEWPORT_SIZE e CURRENT_RENDERER (NDC z de 0..1 no
// Vulkan, −1..1 no OpenGL) — nada exclusivo do Forward+ (sem
// hint_normal_roughness_texture).
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

uniform vec4 cor_contorno : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float raio = 3.0;
uniform float limiar = 0.25;
uniform float limiar_inicio = 0.08;
uniform float saturacao = 3.0;
uniform float limiar_vinco_graus = 75.0;
uniform float banda_vinco_graus = 5.0;
uniform float saturacao_vinco = 2.0;
uniform bool vinco_um_lado = false;
uniform bool profundidade_msaa = true;
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
	// tamanho do pixel no mundo (ortográfica: meia-extensão = INV_PROJ[i][i])
	vec2 w = 2.0 * px * abs(vec2(INV_PROJECTION_MATRIX[0][0], INV_PROJECTION_MATRIX[1][1]));
	float zc = z_em(uv, INV_PROJECTION_MATRIX);
	float zl = z_em(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float zr = z_em(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float zd = z_em(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float zu = z_em(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	vec2 g = vec2(min(abs(zr - zc), abs(zc - zl)), min(abs(zu - zc), abs(zc - zd)));
	float r2 = raio * 0.55;
	// o anel do vinco: o interno (0,55·raio) quando tem ≥ 2 px; no Pixel Pass
	// (raio 1) o externo, que pega os 8 vizinhos (o interno só pega os 4 em
	// cruz e a linha em escada saía tracejada)
	bool externo = r2 < 2.0;
	// diferença de 1 px que já é salto (silhueta), não inclinação: o maior
	// entre `limiar_inicio` e uma inclinação de ~80° (6 px de mundo por px)
	float salto = max(limiar_inicio, 6.0 * max(w.x, w.y));
	// inclinação do centro (por unidade de mundo) e `zp`, a profundidade do
	// PLANO do centro: o QUADRANTE mais plano — (lado x, lado y) cuja diagonal
	// cai no plano dos dois lados. Escolher x e y separados mistura os dois
	// planos de um vinco (normal híbrida: a linha saía oca/tracejada); o
	// quadrante plano é sempre de um plano só.
	vec2 sc = vec2(0.0);
	float zp = zc;
	float melhor = 1e20;
	if (profundidade_msaa) {
		// MSAA: o pixel EM CIMA da quina tem profundidade de chanfro (nenhum dos
		// dois planos) — por isso nada aqui usa `zc`: braços de 1 e 2 px PARA
		// FORA; inclinação dentro do braço; cada braço extrapola o plano no
		// centro (z0x, z0y); a diagonal confere e escolhe o z0 que acerta.
		float zl2 = z_em(uv - vec2(2.0 * px.x, 0.0), INV_PROJECTION_MATRIX);
		float zr2 = z_em(uv + vec2(2.0 * px.x, 0.0), INV_PROJECTION_MATRIX);
		float zd2 = z_em(uv - vec2(0.0, 2.0 * px.y), INV_PROJECTION_MATRIX);
		float zu2 = z_em(uv + vec2(0.0, 2.0 * px.y), INV_PROJECTION_MATRIX);
		for (int q = 0; q < 4; q++) {
			vec2 sq = vec2(q < 2 ? 1.0 : -1.0, (q == 0 || q == 3) ? 1.0 : -1.0);
			float a1 = sq.x > 0.0 ? zr : zl;
			float a2 = sq.x > 0.0 ? zr2 : zl2;
			float b1 = sq.y > 0.0 ? zu : zd;
			float b2 = sq.y > 0.0 ? zu2 : zd2;
			float zq = z_em(uv + sq * px, INV_PROJECTION_MATRIX);
			float da = a2 - a1;  // variação por px, para fora em x
			float db = b2 - b1;  // idem em y
			float z0x = a1 - da;
			float z0y = b1 - db;
			float ex = abs(zq - z0x - da - db);
			float ey = abs(zq - z0y - da - db);
			float z0 = ex <= ey ? z0x : z0y;
			// plano dos braços longe de C (C é a última fileira de um objeto
			// na frente, braços no fundo): não é o plano de C — penaliza
			float erro = abs(z0x - z0y) + min(ex, ey) + 1e-3 * (abs(da) + abs(db))
				+ 10.0 * max(abs(z0 - zc) - salto, 0.0);
			if (erro < melhor) {
				melhor = erro;
				sc = vec2(da, db) * sq / w;
				zp = z0;
			}
		}
		if (abs(zp - zc) > salto) {
			zp = zc;
		}
	} else {
		// sem MSAA (Pixel Pass): o centro é um ponto só; diferenças de 1 px
		for (int q = 0; q < 4; q++) {
			vec2 sq = vec2(q < 2 ? 1.0 : -1.0, (q == 0 || q == 3) ? 1.0 : -1.0);
			float dx = (sq.x > 0.0 ? zr : zl) - zc;
			float dy = (sq.y > 0.0 ? zu : zd) - zc;
			float zq = z_em(uv + sq * px, INV_PROJECTION_MATRIX);
			float erro = abs(zq - zc - dx - dy) + 1e-3 * (abs(dx) + abs(dy));
			if (erro < melhor) {
				melhor = erro;
				sc = vec2(dx, dy) * sq / w;
			}
		}
	}
	vec3 nc = normalize(vec3(sc, -1.0));

	float cos_alto = cos(radians(limiar_vinco_graus - banda_vinco_graus));
	float cos_baixo = cos(radians(limiar_vinco_graus + banda_vinco_graus));

	float soma = 0.0;
	float soma_v = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 dir = vec2(cos(a), sin(a));
		// offsets INTEIROS: o filtro é nearest, então o texel lido fica a
		// floor(o + 0,5) px do centro — é essa a distância que se compensa
		vec2 o = floor(dir * raio + 0.5);
		float z1 = z_em(uv + o * px, INV_PROJECTION_MATRIX);
		float dz = zc - z1 - dot(abs(o), g);
		soma += smoothstep(limiar_inicio, limiar, dz);
		vec2 o2 = floor(vec2(cos(a + 0.392699), sin(a + 0.392699)) * r2 + 0.5);
		float z2 = z_em(uv + o2 * px, INV_PROJECTION_MATRIX);
		float dz2 = zc - z2 - dot(abs(o2), g);
		soma += smoothstep(limiar_inicio, limiar, dz2);

		// --- vinco com a amostra S (o mesmo texel: offset inteiro `ov`) ---
		vec2 ov = externo ? o : o2;
		float zs = externo ? z1 : z2;
		vec2 uvs = uv + ov * px;
		// normal de S: 2 vizinhos de 1 px para FORA do centro (do lado de dentro
		// o vizinho cruzaria o próprio vinco quando ele passa a 1 px de S)
		vec2 h = vec2(ov.x < 0.0 ? -1.0 : 1.0, ov.y < 0.0 ? -1.0 : 1.0);
		float ex = z_em(uvs + vec2(h.x * px.x, 0.0), INV_PROJECTION_MATRIX) - zs;
		float ey = z_em(uvs + vec2(0.0, h.y * px.y), INV_PROJECTION_MATRIX) - zs;
		vec2 ss = vec2(ex, ey) * h / w;
		// salto no vizinho de 1 px = silhueta encostada em S: a inclinação
		// dela não se mede (e a linha 1 já cobre a silhueta) — S não conta
		float medivel = 1.0 - step(salto, max(abs(ex), abs(ey)));
		vec3 ns = normalize(vec3(ss, -1.0));
		float ang = 1.0 - smoothstep(cos_baixo, cos_alto, dot(nc, ns));
		// oclusão com folga: um à frente do plano do outro
		vec3 d = vec3(ov * w, zs - zp);
		float e_s = dot(d, nc);   // > 0: S à frente do plano do centro
		float e_c = -dot(d, ns);  // > 0: centro à frente do plano de S
		float ocl = min(max(e_c, 0.0), max(-e_s, 0.0)) + min(max(-e_c, 0.0), max(e_s, 0.0));
		// um vinco só entre os dois: o ponto do meio cai num dos dois planos.
		// Faceta estreita no meio (copa perto da silhueta, quina de faceta)
		// cai fora dos dois: não é vinco do centro com S. Sem meio no Pixel
		// Pass (S é vizinho imediato).
		float um_vinco = 1.0;
		if (!externo) {
			vec2 om = floor(ov * 0.5 + 0.5);
			float zm = om == vec2(0.0) ? zp : z_em(uv + om * px, INV_PROJECTION_MATRIX);
			float em = min(abs(zm - zp - dot(sc, om * w)), abs(zm - zs - dot(ss, (om - ov) * w)));
			float desvio = abs(zs - zp - dot(sc, ov * w)) + 1e-5;
			if (profundidade_msaa) {
				// meio EM CIMA do vinco: chanfro do resolve, fora dos dois planos
				// por até ~meio px da diferença de inclinação ao longo de C→S —
				// é o próprio vinco, não uma faceta no meio: essa folga não conta
				float folga = 0.5 * abs(dot(sc - ss, ov * w)) / length(ov);
				em = max(em - folga, 0.0);
			}
			um_vinco = 1.0 - smoothstep(0.12, 0.3, em / desvio);
		}
		float v = medivel * ang * um_vinco * (1.0 - smoothstep(limiar_inicio, limiar, ocl));
		if (vinco_um_lado) {
			v *= step(abs(nc.z), abs(ns.z));
		}
		soma_v += v;
	}
	float cobertura = max(soma / saturacao, soma_v / saturacao_vinco);
	ALBEDO = cor_contorno.rgb;
	ALPHA = clamp(cobertura, 0.0, 1.0) * cor_contorno.a;
}
