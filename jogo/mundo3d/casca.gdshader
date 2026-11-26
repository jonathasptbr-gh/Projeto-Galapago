// Casca invertida — contorno escuro desenhado como passe extra (next_pass) ou
// como malha própria (a casca do terreno já vem inflada: espessura = 0).
// Contrato:
//   cor_contorno   source_color — cor da linha
//   espessura      unidades 3D que a casca cresce para fora
//   forma          0 = pela normal (malhas lisas: esfera, cápsula)
//                  1 = caixa centrada na origem (VERTEX += sign(VERTEX)·esp:
//                      cresce a caixa inteira, sem rachar nos cantos)
//                  2 = cilindro centrado (raio em xz + sign(y) em y)
//                  3 = terreno (ilha.gd): a malha vem pronta; só a ABA do topo
//                      (vértices com UV.x = 1) sai NORMAL·espessura, e encolhe
//                      até sumir quando a parede (NORMAL, horizontal) vira de
//                      frente para a câmera — borda de frente não ganha linha
// cull_front: só as faces de trás aparecem, e só onde passam da silhueta.
// No passe de SOMBRA a casca some (vértices colapsados): como next_pass ela
// projetaria a sombra inflada do objeto sobre ele mesmo.
// Mobile (Vulkan) e Compatibility (OpenGL 3): só vertex/fragment e IN_SHADOW_PASS.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 cor_contorno : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float espessura = 0.05;
uniform int forma = 0;

void vertex() {
	if (IN_SHADOW_PASS) {
		VERTEX = vec3(0.0);
	} else if (forma == 3) {
		vec3 n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 tras = INV_VIEW_MATRIX[2].xyz;  // da cena para a câmera
		vec2 h = tras.xz;
		float frente = dot(n.xz, h) / max(length(h), 0.0001);
		VERTEX += NORMAL * espessura * UV.x * (1.0 - smoothstep(0.1, 0.6, frente));
	} else if (forma == 1) {
		VERTEX += sign(VERTEX) * espessura;
	} else if (forma == 2) {
		vec2 r = VERTEX.xz;
		float l = length(r);
		if (l > 0.0001) {
			VERTEX.xz += r / l * espessura;
		}
		VERTEX.y += sign(VERTEX.y) * espessura;
	} else {
		VERTEX += NORMAL * espessura;
	}
}

void fragment() {
	ALBEDO = cor_contorno.rgb;
}
