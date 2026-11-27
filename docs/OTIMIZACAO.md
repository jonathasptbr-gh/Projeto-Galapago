# Otimização gráfica — o plano do P25 (fonte única)

> **Este guia é o plano vivo da otimização do cenário 3D** (pacote P25 da
> [fila](PEDIDOS-EM-ESPERA.md#p25--cenário-3d-medir-e-otimizar-o-custo-gráfico)),
> pensado para ser retomado por qualquer sessão nova sem o chat anterior.
> Coordena também o que P26 (destruição), P27 (elementos/água) e P29 (modelo)
> precisam da otimização — sem implementar esses pacotes por conta própria.
> Criado em 2026-11-27 a pedido do operador ("deixe ele bem documentado e salvo").

## 1. Retomar numa sessão nova — nesta ordem

1. `tools/estado.sh --ci` (versão, HEAD, CI) e o [`AGENTS.md`](../AGENTS.md)
   inteiro, como manda o contrato.
2. Ler **só as seções 2 a 4 deste guia**: a regra de ritmo, o estado com a
   **PRÓXIMA ETAPA** marcada e a referência medida. O registro (seção 8) é
   consulta, não leitura obrigatória. **Desde a v0.40.0 (etapa 1.5) a
   referência do aparelho vem do REGISTRO COPIADO** (botão COPIAR REGISTRO com
   o painel DIAGNÓSTICO ligado, colado no chat pelo operador): cabeçalho,
   resumo de até 60 s e uma linha por janela — não mais da foto do painel.
3. Conferir se o código citado na próxima etapa ainda é o descrito (o HEAD de
   referência de cada registro está anotado). Divergência → reconferir antes de
   propor.
4. **Pedir autorização ao operador** com o modelo da seção 6. Sem resposta
   positiva no chat, nada começa — nem agente, nem leitura cara, nem build.
5. Ao terminar a etapa: atualizar a tabela da seção 3, acrescentar o registro
   na seção 8, salvar (commit comum `docs:`/`jogo:` ou publicação, conforme o
   escopo autorizado) e **parar**.

## 2. Regra de ritmo e gastos (decisão do operador, 2026-11-27)

- **Cada etapa, em cada grupo, exige autorização individual no chat.**
  Aprovar o plano não libera a execução dele inteira.
- **Cada acionamento de subagente também** (inclusive retomar um agente que
  parou, chamar revisor ou repetir uma tentativa). O pedido diz quantos agentes
  e para quê; o padrão é **um** agente por etapa, ou nenhum quando o gerente
  faz sozinho (documentação, conferência).
- Publicação de APK, commit/push, chamada paga (PixelLab), download de modelo e
  instalação de dependência **só se declarados no pedido autorizado**.
- Falha fora do escopo autorizado volta ao operador; não se abre ciclo de
  reparo ampliado. Teto de auto-reparo do
  [protocolo](PROTOCOLO-AGENTES.md#critério-de-aceite-e-teto-de-reparo) vale.
- Ao concluir: relatar o que foi feito, a prova, os limites e a próxima opção;
  **parar**. Nenhum agente fica trabalhando depois da entrega.
- Nenhum valor monetário estimado sem fonte; nenhuma promessa de FPS ou ganho
  sem medição no aparelho.

## 3. Estado das etapas

Legenda: ✔ concluída · ◐ concluída em parte · ▶ **próxima (aguarda
autorização)** · ○ aguardando autorização · ? proposta nova, a confirmar.

| etapa | o quê | estado |
|---|---|---|
| 1.1 | Inventário do código e protocolo de medição | ✔ 2026-11-27 |
| 1.2 | Painel DIAGNÓSTICO opcional na HUD | ✔ 2026-11-27 (publicado na v0.38.0) |
| 1.3 | APK instrumentado + referência no aparelho | ◐ 2026-11-27: v0.38.0 publicada; 1 leitura no S24 Ultra (seção 4) |
| 1.4 | Tempo de render CPU/GPU por viewport no painel + corrigir sobreposição | ✔ 2026-11-27: v0.39.0 + leitura no S24 Ultra (seção 4) |
| 1.5 | Painel resumido (FPS e tempos de render) + COPIAR REGISTRO completo | ✔ 2026-11-27: publicada na v0.40.0; prova local técnica/visual, sem benchmark Android |
| **2.1** | **Sombras: copa simplificada só para sombra** | **◐ v0.41.0: código publicado; ganho e aceite no aparelho AINDA NÃO MEDIDOS** |
| 2.2 | Sombras: resolução do atlas, isolada | ○ |
| 3.1 | Copas leves na vista alta, completas na íntima | ○ |
| 3.2 | Vegetação decorativa: detalhe e densidade | ○ |
| 4.1 | Escala de resolução só do 3D liso | ○ |
| 4.2 | MSAA comparado isoladamente | ○ |
| 5.1 | Mapa do chão redesenhado só quando muda | ○ |
| 5.2 | Marcas persistentes separadas das animadas | ○ |
| 6.1 | Granulação dos setores de MultiMesh | ○ |
| 6.2 | Solo indexado | ○ |
| 6.3 | Solo por trechos / malha leve em terra plana | ○ |
| 7.1–7.3 | Assets 3D: ficha de custo → avaliar → importar aprovado | ○ |
| 8.1–8.3 | Destruição (P26) com estado na sim e lotes locais | ○ |
| 9.1–9.3 | Água de grade (P27) com custo controlado | ○ |
| 10.1–10.5 | Elementos (P27): contrato comum, fogo, ar, terra, combinações | ○ |
| 11.1–11.2 | Perfis de qualidade e fechamento sustentado | ○ |

**▶ Próxima ação do plano:** comparar a 2.1 no aparelho, no mesmo enquadramento,
com registros separados por modo; nenhuma diferença de GPU está demonstrada.
A 2.2 e os grupos seguintes continuam sem autorização. COMPLETAS permanece
padrão até decisão explícita do operador; publicar a chave não aprova qualidade.

Escopo e aceite de cada etapa: seção 5. A ordem é a inicial; um resultado
pode justificar **propor** outra ordem, nunca executá-la sem autorização.

## 4. Referência medida no aparelho

### 2026-11-27 — Samsung Galaxy S24 Ultra, v0.39.0-b137 (captura do operador)

| campo | valor |
|---|---|
| renderizador / API | `mobile` / `vulkan` |
| modo / resoluções | 3D liso, MSAA 4×; interna = alvo = física **1440×3120 px** |
| FPS (callbacks/relógio real) | **35,81** |
| intervalo real médio / máximo | **27,9 ms / 34,7 ms** (delta do motor 27,4 ms) |
| 3D (vista.sv), média da janela | **CPU 0,78 ms · GPU 23,18 ms** |
| Chão (mapa) | CPU 0,26 ms · GPU 0,47 ms |
| Tela (HUD+imagem) | CPU 0,54 ms · GPU 2,26 ms |
| draw calls / primitivas (globais, último quadro) | **345 / 505.257** |
| janela | **uma** janela de 0,53 s (amostra única, não sustentada) |
| cena | vista alta, criatura **andando** (rota 70%) sob copas densas, hostilidade desligada |

**O que esta leitura diz (sem generalizar além dela):**

- Nesta cena o quadro **não fecha em 16,7 ms**: ~28 ms por quadro, ~36 FPS.
  A leitura anterior (v0.38.0, criatura parada, outra posição) estava no teto
  de 60 — cena, movimento e instrumentação diferem; as duas não se comparam
  como antes/depois.
- A captura mostra **GPU do 3D em 23 ms** e CPU de render <1 ms por viewport.
  Isso sugere investigar o desenho 3D (sombras, copas, resolução/MSAA), mas
  **não comprova gargalo, regressão nem causa**: é uma janela isolada.
- Tempos são por viewport e à parte (soma ≠ quadro). Impacto da instrumentação
  **e da captura de tela desconhecido**; a hipótese do operador de que a captura
  pausa/interfere no jogo não foi descartada nem comprovada.
- Esta foto é contexto histórico, não baseline sustentada. Desde 1.5 a fonte
  técnica é o registro copiado, com duração e janelas explícitas. A cópia não
  altera as janelas já congeladas, mas pode afetar as seguintes; também não
  mede à parte o custo da instrumentação.


### 2026-11-27 — Samsung Galaxy S24 Ultra, v0.38.0-b135 (captura do operador)

| campo | valor |
|---|---|
| renderizador / API | `mobile` / `vulkan` (sem fallback) |
| modo | 3D liso (PIXEL ART desligado), MSAA 4× pelo código ([`vista.gd`](../jogo/mundo3d/vista.gd)) |
| resolução 3D interna = alvo = física | **1440×3120 px** (o liso renderiza na resolução nativa) |
| FPS (callbacks/relógio real) | **60,09** |
| intervalo real médio / máximo | **16,6 ms / 18,7 ms** |
| delta médio do motor | 16,7 ms |
| draw calls / primitivas (globais, último quadro) | **260 / 501.469** |
| janela | **uma** janela de 0,52 s (amostra única, não sustentada) |
| cena | vista alta, criatura parada sob copa (copa vazada visível), hostilidade desligada |
| calor | operador: "em pouco tempo ele não aqueceu" (sessão curta) |

**O que esta leitura diz:**

- No S24 Ultra o jogo fica **no teto de 60 FPS** (refresh/VSync), com picos
  curtos de até 18,7 ms. Há folga, mas **o FPS não mostra quanto**.
- Por isso **o FPS deste aparelho não serve para comparar otimizações**: uma
  melhoria real continuaria marcando 60. É preciso o **tempo de render da GPU
  e da CPU** (etapa 1.4) ou um aparelho médio.
- O alvo declarado do projeto é o **celular médio**
  ([P24](PEDIDOS-EM-ESPERA.md#p24--fundação-3d)); o S24 Ultra é topo de linha.
  Uma leitura num aparelho médio, se o operador tiver um, vale mais que muitas
  no S24.
- A resolução nativa 1440×3120 com MSAA 4× é custo grande em aparelho médio:
  reforça o grupo 4 (resolução/AA), sem conclusão antes de medir.
- ~500 mil primitivas por quadro incluem o passe de sombra: coerente com o
  grupo 2 ser o primeiro candidato, a confirmar com tempo de GPU.

**Defeito visto na captura (corrigido na 1.4, v0.39.0):** o botão "Verificar
atualização" (canto superior direito, `TOPO + 350`) ficava **por cima do painel
DIAGNÓSTICO**; agora mora na coluna da esquerda, abaixo do botão DIAGNÓSTICO
([`hud.gd`](../jogo/hud.gd), `_criar_verificar`).

## 5. Plano por grupos — escopo e aceite

Cada linha é uma autorização separada. As verificações de cada etapa são
detalhadas no pedido (seção 6); o gate do repositório vale se houver commit.

| etapa | escopo e entrega delimitados | aceite da etapa |
|---|---|---|
| 1.1 | Inventário do código e protocolo comparativo, sem executar o jogo | configuração e limitações registradas; nenhuma alegação de ganho |
| 1.2 | Painel diagnóstico opcional: FPS, tempo de quadro, calls/primitivas quando disponíveis, resolução e renderizador efetivos; sem otimizar | métricas com origem/escopo; CPU/GPU indisponível como tal; painel desligável; testes seletivos |
| 1.3 | Versão instrumentada publicada e referência no aparelho | leitura registrada; nenhum dado de render por CPU usado como desempenho do APK |
| 1.4 | Ligar `RenderingServer.viewport_set_measure_render_time` **só com o painel ligado** no SubViewport 3D (e no mapa do chão, se útil) e mostrar `viewport_get_measured_render_time_cpu/gpu` com rótulo de escopo; corrigir a sobreposição do botão "Verificar atualização"; publicar para medir | tempo GPU/CPU do 3D visível no aparelho, `n/d` onde a API devolver 0/indisponível; desligado não mede; layout sem sobreposição; nova referência S24 (e aparelho médio, se houver) |
| 1.5 | Painel na tela só com o útil ao operador: FPS, quadro médio/pior e GPU/CPU do 3D em ms × orçamento de 60 FPS (CPU de render, não uso total do processador ou % de ocupação). Histórico só com o painel ligado: uma linha por janela ≥ 0,5 s, anel dos **últimos 60 s** (teto 120 linhas), zerado ao religar. Botão **COPIAR REGISTRO** (só com o painel ligado) põe na área de transferência (`DisplayServer.clipboard_set`) um texto legível com **todos** os dados — cabeçalho (versão, data, aparelho/sistema quando a API der, GPU, renderizador, tela, modo, MSAA, resoluções, vista, hostilidade), resumo, tabela e notas de escopo — para colar no chat em vez de foto | painel curto e legível; registro copiado completo, com rótulos e unidades; `n/d` mantido; desligado não mede nem grava; testes do formato, do anel e do layout |
| 2.1 | Sombras: chave diagnóstica completa/desligada e copa simplificada só para sombra (`SHADOWS_ONLY`), folhas reais sem projetar; atlas inalterado | proxy coerente com a árvore; mesmo enquadramento; diferença de GPU registrada |
| 2.2 | Sombras: resolução do atlas, separada do proxy | custo × imagem registrados; pés, bordas, serrilhado e bias conferidos; não zerar blur |
| 3.1 | Árvores internas leves na vista alta (variante `simples` de [`malhas.gd`](../jogo/mundo3d/natureza/malhas.gd)), completas na íntima | silhueta e copa vazada preservadas; transição estável (histerese), guiada pela vista ortográfica |
| 3.2 | Vegetação decorativa: menos sobreposição/densidade onde pouco contribui | mesma regra/ocupação; cobertura tática intacta; sem trocar por cards transparentes |
| 4.1 | Escala de resolução só do 3D liso; HUD nítida | toque, marcas e coordenadas corretos; AA fixo durante a comparação; Pixel Pass segue opcional |
| 4.2 | MSAA 4×/2×/off comparado isoladamente | custo e serrilhado das folhas registrados; visual padrão só muda com aceite do operador |
| 5.1 | Mapa do chão por invalidação, com último quadro de limpeza | caminho, mira e avisos vivos; nada congelado nem marca fantasma |
| 5.2 | Marcas persistentes separadas das animadas, só se o perfil justificar | queimaduras reaproveitáveis sem atrasar avisos |
| 6.1 | Granulação dos MultiMeshes já setorizados, uma família por vez | compromisso CPU/submissões × descarte registrado; lotes ≠ draw calls |
| 6.2 | Solo indexado | mesmos atributos, cores, margens e alturas; gameplay igual |
| 6.3 | Solo por trechos e malha leve em terra plana | mudança local não reconstrói o mapa; vaus/margens preservados; base para terra destrutível |
| 7.1 | Ficha de custo de modelo 3D: malhas, materiais, ossos, clipes, texturas, licença | critérios registrados; nada baixado, comprado ou escolhido |
| 7.2 | Avaliar UM modelo nomeado pelo operador | ficha e prancha no chat; licença/crédito conferidos; aprovar análise ≠ aprovar importação |
| 7.3 | Preparar/importar só o aprovado: materiais compartilhados, texturas proporcionais, clipes necessários, LOD se útil | ajuste reproduzível ([MODELOS-3D](MODELOS-3D.md)); GLB só por script com crédito; sem refazer rig |
| 8.1 | P26: IDs estáveis de árvores/vegetação na sim, ocupação e deltas por setor | testes puros; planta omitida pelo detalhe gráfico continua existindo na regra |
| 8.2 | P26: vegetação baixa removida por impacto; efeitos reutilizáveis e marcas | só lotes atingidos atualizados; teto visual não impede destruição lógica |
| 8.3 | P26: árvore sai do lote, tomba em objeto reutilizável, vira tronco estático e obstáculo | regra e imagem sincronizadas; sombra acompanha; pico de quedas medido; porte/limiar decididos antes |
| 9.1 | P27: recuperar e conferir isolado o ensaio de água do commit `64f0d2f` | testes de conservação, embalo, barreiras e riacho; o protótipo não volta inteiro ao jogo |
| 9.2 | P27: passo fixo, buffers e células ativas com vizinhança | igual à referência; determinístico; continua fora da câmera; nunca trocar por fluxo só de diferença de nível |
| 9.3 | P27: campo visual por regiões alteradas, lâmina orgânica, espuma/filetes, umidade (`usar_umidade` de [`natural.gdshader`](../jogo/mundo3d/natureza/natural.gdshader)) | campo e obstáculos alinhados; custo de upload medido; Mobile e Compatibility; sem compute, SSR ou partículas de fluido |
| 10.1 | P27: contrato comum de altura, ocupação, combustível/umidade e ordem de interação | regras abertas fechadas com o operador antes; sim testável; sem bloqueio fantasma |
| 10.2 | Fogo: propagação na grade e chamas/cinza/marcas limitadas e reutilizáveis | fogo lógico independe do teto visual; umidade testada; pico medido |
| 10.3 | Ar: vento visual no shader; empurrão/queda na sim | nenhum nó ou processo por folha |
| 10.4 | Terra: relevo e bloqueios locais sincronizados com a água | buraco/rampa/represa coerentes; só o trecho afetado é atualizado |
| 10.5 | UMA combinação por autorização, nomeada no chat | testes locais por célula; cenário misto medido |
| 11.1 | Perfis conservador/equilibrado/econômico a partir do medido | mesma sim/regras em todos; padrão escolhido pelo operador; qualidade não oscila a cada quadro |
| 11.2 | Fechamento: comparação integrada sustentada | regressões, picos e limites reais registrados; sem FPS universal prometido |

**Dependências:** 1.4 precede as decisões de ganho dos grupos 2–6 (no S24 o
FPS está no teto). Grupos 8–10 seguem P26/P27 e o porte/elemento de P5; cada
regra aberta é perguntada antes. 6.3 prepara o relevo do grupo 10; 8.1 e 10.1
precisam ser coerentes com 9.2/9.3. O grupo 7 depende da escolha do modelo
(P29) e não bloqueia a mata autoral. O grupo 11 só usa o que já foi aprovado.

## 6. Modelo de pedido de autorização (copiar e preencher)

```text
Etapa X.Y — <nome curto>
Escopo: <o que muda, em 1–3 linhas>
Não toca: <sim/, gestos, defaults visuais, outros grupos…>
Entrega: <local | commit comum | publicação vX.Y.Z com APK>
Verificações: <testes seletivos, gate completo, oráculo, medição no aparelho>
Agentes: <0 (gerente) | 1 agente de implementação>
Custo extra: <nenhum | PixelLab/modelo — só se necessário e cotado>
Autoriza?
```

O briefing do agente segue os cinco campos do
[protocolo](PROTOCOLO-AGENTES.md#o-briefing-do-trabalhador): objetivo,
arquivos, restrições, verificação, resposta. Sempre incluir: "você é o único
agente; não delegue; entregue e pare".

## 7. Invariantes — otimizar sem atrapalhar água, elementos e destruição

1. **Limita-se o que se desenha, nunca o que acontece.** Detalhe gráfico
   reduzido, planta omitida ou chama não desenhada continuam existindo na
   `sim/` (bloqueiam, queimam, recebem impacto).
2. **A regra é da `sim/`** ([ARQUITETURA](ARQUITETURA.md#as-duas-camadas-a-regra-que-mais-se-paga)):
   destruição encenada, não física; água de grade com canos virtuais; nada de
   regra decidida em shader.
3. **Água fora da câmera continua correndo.** Otimiza-se o desenho e as
   regiões atualizadas, não a conservação nem o embalo.
4. **Atualização local:** impacto, fogo, terra ou água atualizam só os lotes,
   trechos e regiões afetados. Nunca `construir()` inteiro por evento
   ([`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd)).
5. **Sombra simplificada acompanha a árvore**: cai, queima e some junto.
6. **Avisos de combate nunca congelam** por economia (mira, perigos, caminho).
7. **Mobile e Compatibility:** nada exclusivo do RenderingDevice (compute),
   nada certo só em cor linear ou só em sRGB.
8. **Controles e gestos maduros não mudam** sem pedido do operador.
9. **Uma variável por vez** em cada comparação; imagem conferida além dos
   números; oráculo por software prova imagem, não desempenho.

## 8. Registro das etapas

### 1.1 — inventário e protocolo (2026-11-27, HEAD `c065837`)

Gerente, sem agente; só documentação. Pontos conferidos no código:

| ponto | evidência | consequência |
|---|---|---|
| Mobile com fallback OpenGL | [`project.godot`](../project.godot), `[rendering]` | registrar o renderizador efetivo (1.4 mostrou `vulkan` no S24) |
| Atlas direcional 4096 no mobile, filtro suave 2 | [`project.godot`](../project.godot) | proxy (2.1) e atlas (2.2) em comparações separadas |
| Liso: janela física + MSAA 4×; Pixel Pass: alvo reduzido sem MSAA | [`vista.gd`](../jogo/mundo3d/vista.gd), `_reconfigurar` | Pixel Pass mistura resolução, AA e pós: não isola causa |
| Contorno de tela fora da mata (`layers = 0`) | [`main.gd`](../jogo/main.gd) | não otimizar primeiro um passe inativo |
| Setores 12×12 de MultiMesh; árvore `simples` só na moldura | [`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd), `SETOR`, `_lote` | instancing já existe; medir granulação |
| Folhas com duas faces e `discard` da copa vazada (sem alpha) | [`folha.gdshader`](../jogo/mundo3d/natureza/folha.gdshader) | o dither não reduz o passe de sombra |
| Mapa do chão `UPDATE_ALWAYS`, até 2048 px de lado | [`chao.gd`](../jogo/mundo3d/chao.gd) | comparar repouso × marcas animadas |
| Solo: 92×124 quadras, sem índices | [`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd), `_terreno` | grupo 6.2/6.3 |
| Riacho estático; água de grade removida (escolhida) | [`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd), `_agua`; [P27](PEDIDOS-EM-ESPERA.md#p27--os-quatro-elementos-no-cenário) | água/fogo/queda não pesam hoje |

**Protocolo de comparação:**

1. Anotar build, aparelho, renderizador/API, resoluções, modo visual, MSAA,
   sombras, detalhe e limite de FPS. Mesma semente, enquadramento, percurso e
   atores.
2. Condições repetíveis (brilho, energia, calor). Sustentado: aquecer ~2 min e
   3 amostras de ~30 s por cenário — duração confirmada no pedido da etapa.
3. Cenários: repouso, caminho, giro 360°, sob copas, combate atual. Vista alta
   é a principal. Picos de água/fogo/quedas só quando existirem.
4. FPS, intervalo e picos; tempo GPU/CPU só de API real (1.4); calls e
   primitivas com escopo declarado. Indisponível é `n/d`, nunca estimativa.
5. Uma variável por vez; no teto de FPS, comparar tempo de GPU, não FPS.
6. Oráculo/CI por software: prova de imagem, não de desempenho.

### 1.2 — painel DIAGNÓSTICO (2026-11-27, 1 agente, local; publicado em 1.3)

- Módulo [`diagnostico.gd`](../jogo/diagnostico.gd); botão DIAGNÓSTICO na HUD
  ([`hud.gd`](../jogo/hud.gd)), desligado por padrão; ligado, ocupa o lugar da
  legenda; o texto ignora toque. CONFIG oculto e vista íntima **suspendem** a
  coleta. Atalho `--diagnostico` para o oráculo ([`main.gd`](../jogo/main.gd)).
- Métricas: FPS = intervalos de `_process` ÷ tempo real (`Time.get_ticks_usec`),
  janela ≥ 0,5 s sem histórico; delta do motor separado; render/API por
  `RenderingServer.get_current_rendering_*`; resoluções `vista.tamanho_interno()`,
  `vista.sv.size`, `Window.size`; calls/primitivas por
  `get_rendering_info(RENDERING_INFO_TOTAL_*_IN_FRAME)`, globais, último
  quadro; ≤ 0 vira `n/d`. CPU/GPU `n/d` (resolvido em 1.4).
- Prova: [`test_diagnostico.gd`](../testes/test_diagnostico.gd) (5 testes) +
  integração de câmera e mapa: 13 testes, 0 falhas; prévia de 3 quadros no
  oráculo local (Compatibility/softpipe), não benchmark.

### 1.3 — publicação v0.38.0 e primeira referência (2026-11-27, 1 agente)

- Gate completo `tools/testes.sh`: 191 testes GDScript, 0 falhas; parser de 51
  scripts; guardião documental. Commit `bdd25d6` (v0.38.0), CI #135 verde
  (testes, apk, preview). Release `dev`: `versao_codigo` 135, `0.38.0-b135`,
  26.654.004 bytes, commit conferido pelo gerente no manifesto público.
- O agente parou antes do relatório final, depois de publicar; o gerente
  conferiu CI e manifesto diretamente, sem novo agente.
- Leitura do operador no S24 Ultra: seção 4. **Em parte:** uma janela só, sem
  amostras sustentadas nem custo da instrumentação — ficam para 1.4.

### 1.4 — tempo de render por viewport e sobreposição (2026-11-27, 1 agente, v0.39.0)

- [`diagnostico.gd`](../jogo/diagnostico.gd): com o painel **ligado**,
  `RenderingServer.viewport_set_measure_render_time(rid, true)` em três
  viewports, cada um com rótulo de escopo: **"3D (vista.sv)"** (o SubViewport do
  mundo 3D), **"Chão (mapa)"** (o SubViewport 2D de
  [`chao.gd`](../jogo/mundo3d/chao.gd)) e **"Tela (HUD+imagem)"** (o viewport
  raiz: HUD e a imagem do 3D composta). A API mede cada viewport à parte: a soma
  não é o quadro inteiro (o painel diz isso). Desligar o painel, ocultar com o
  CONFIG, entrar na vista íntima ou sair da árvore chama `false` em todos:
  desligado não mede. `medindo()` devolve os rótulos ligados (consultável no
  teste). A medição segue o objeto Viewport e é conferida a cada janela (o Pixel
  Pass só redimensiona o mesmo `sv`; trocar de SubViewport religa sozinho).
- Valor mostrado: **média das leituras > 0** de
  `viewport_get_measured_render_time_cpu/gpu` na janela ≥ 0,5 s (2 getters por
  viewport por quadro); nenhuma leitura > 0 → `n/d`, nada estimado. Substitui a
  linha "CPU/GPU: n/d".
- [`hud.gd`](../jogo/hud.gd): "Verificar atualização" saiu do canto direito
  (`TOPO + 350`, sobre o painel) para a coluna da esquerda, `(20, TOPO + 418)`,
  abaixo do DIAGNÓSTICO; continua sumindo com o CONFIG. O aviso "ATUALIZAR" do
  [`atualizador.gd`](../jogo/atualizador.gd), quando há versão nova, segue no
  canto direito e fica por cima do painel (ação tem prioridade; comentário
  atualizado).
- Prova: [`test_diagnostico.gd`](../testes/test_diagnostico.gd) 8 testes (3
  novos: `tempo_ms`/`media`, liga/desliga + média injetada, HUD oculta/íntima
  desligando a medição e o retângulo do Verificar fora do painel). Oráculo
  `--diagnostico` (Compatibility/softpipe, com o botão forçado só na cópia
  local): painel x ≈ 362–704, botão x 20–260; tempos `n/d` por software,
  esperado — prova de imagem, não de desempenho.
- Gate `tools/testes.sh`: 194 testes GDScript, 0 falhas; parser de 51
  scripts; guardião documental (35 Markdown). Commit `4bb65cd` (v0.39.0), CI
  #137 verde (testes, apk, preview). Release `dev`: `versao_codigo` 137,
  `0.39.0-b137`, 26.658.100 bytes, commit `4bb65cd` no manifesto.
- Leitura do operador no S24 Ultra (v0.39.0-b137): seção 4 — 35,81 FPS, GPU do
  3D 23,18 ms. Etapa concluída. Pedido seguinte do operador: 1.5 (painel
  resumido + COPIAR REGISTRO), para a próxima publicação.

### 1.5 — painel resumido e COPIAR REGISTRO (2026-11-27, 1 agente, v0.40.0)

- [`diagnostico.gd`](../jogo/diagnostico.gd): o **painel** caiu para 6 linhas
  em fonte 20 — janela, `FPS`, `Quadro: <médio> ms · pior <máx> ms`,
  `GPU 3D: x / 16,7 ms`, `CPU render 3D: x / 16,7 ms` (média da janela contra o
  orçamento de 60 FPS, `ORCAMENTO_MS`; sem leitura `n/d / 16,7 ms`) e
  `Mais dados: COPIAR (N s)`. Escopos, resoluções, calls e notas
  saíram do painel para o registro. Vírgula decimal (`num`).
- **Histórico:** com o painel ligado, uma linha por janela ≥ 0,5 s (t, FPS,
  intervalo médio/máximo, delta, CPU/GPU médios de cada viewport medido, calls,
  primitivas) num **anel** de `TETO_LINHAS` = 120 posições, cortado pelo tempo
  aos últimos `HISTORICO_S` = 60 s terminados na última janela concluída.
  Só entram **janelas inteiras cujo início está dentro do recorte**: a janela
  que cruza o corte sai sem rateio (inclusive uma travada >60 s, mesmo sozinha).
  A duração informada é real e pode ser menor que 60 s. **Política:** desligar,
  ocultar com CONFIG, entrar na vista íntima ou trocar modo/resolução/MSAA
  **descarta** histórico e janela incompleta; ao religar começa vazio. A cópia
  também confere a configuração antes de congelar os dados.
- **Registro** (`montar_registro(cab, linhas)`, estática e pura; `resumir`,
  `texto_painel`, `ms_orcamento` também): cabeçalho (jogo, versão — a mesma
  string do título, `Hud.texto_versao()` —, data/hora, `OS.get_model_name`,
  `OS.get_name`/`get_version`, processador (`n/d` no Android, como a API
  documenta) e núcleos, GPU `RenderingServer.get_video_adapter_*`,
  renderizador/API, taxa da tela, VSync, limite de FPS, modo PIXEL ART, MSAA,
  resoluções, vista, hostilidade); resumo (duração, janelas, FPS médio/mín/máx,
  quadro médio e pior pico, GPU/CPU de render 3D médio e pior janela).
  FPS = total de quadros/tempo; média de CPU de render/GPU = somas originais
  divididas pelas contagens **independentes** de leituras válidas por quadro,
  preservadas em cada janela (não média simples de janelas, nem ausência como
  zero). Pior = maior média de janela, não pico de GPU por quadro. Tabela com
  colunas separadas por ` | ` e legenda; notas (soma ≠ quadro, primitivas ≠
  triângulos, `n/d`, custo desconhecido de instrumentação/captura/cópia,
  orçamento de 16,7 ms como referência, não medida).
- [`hud.gd`](../jogo/hud.gd): botão **COPIAR REGISTRO** em `(20, TOPO + 418)`,
  visível só com o painel ligado e escondido pelo CONFIG/vista íntima;
  "Verificar atualização" desceu para `(20, TOPO + 460)`. O toque chama
  `area_transferencia` (padrão `DisplayServer.clipboard_set`, injetável no
  teste) e mostra `COPIADO: N janelas` por 1,5 s.
- Prova: [`test_diagnostico.gd`](../testes/test_diagnostico.gd) **16 testes**,
  0 falhas no seletivo: anel de 60 s/120 linhas, janelas desiguais e travada
  >60 s, duração/FPS/contagens válidas diferentes e leitura ausente, mudança de
  configuração, formato `x / 16,7 ms`/`n/d`, registro, cópia injetada sem
  clipboard real headless, aviso e layout dos botões (incluindo Verificar).
  `lint_diagnostics` chamado: sem linter GDScript/Markdown no harness; parser e
  gate do projeto são a prova executável. No host proot a API de nome da CPU
  avisa que não encontrou modelo e retorna vazio, convertido em `n/d`.
- Oráculo `DEMO_ARGS="--diagnostico" tools/quadros.sh 3
  /root/tmp/etapa15-quadros`, exit 0: **3 PNG**, Compatibility/OpenGL 3.3/softpipe;
  último **aberto** e copiado para `/root/tmp/etapa15-quadro.png`: painel
  legível à direita, COPIAR na coluna esquerda sem sobreposição. Verificar
  não nasce no build local; posição abaixo de COPIAR conferida pelo teste de
  retângulos. É prova visual, **não desempenho** (Movie Maker/software).
- Exemplo `/root/tmp/etapa15-registro-exemplo.txt` regenerado pela função pura
  com janelas e contagens coerentes: **EXEMPLO FICTÍCIO INJETADO — NÃO É
  BENCHMARK** no cabeçalho. Temporários fora do git. Nenhum ganho alegado;
  render, AA, sombras, resolução e Pixel Pass intocados. Escopo 1.5 concluído;
  grupos 2+ não executados, exigem outra autorização.
- Gate `tools/testes.sh`, exit 0: guardião **35 Markdown/49 testes**, **202
  testes GDScript, 0 falhas**, parser **51 scripts, 0 erros**. Log local
  `/root/tmp/etapa15-gate.log`; seletivo `/root/tmp/etapa15-seletivo.log`.
  `git diff --check` limpo e busca de padrões de segredo sem ocorrências.
  Commit de publicação e CI identificados no relatório de entrega; não se abre
  outro commit apenas para registrar CI ainda em andamento.


### 2.1 — alternância de sombras e copas proxy (2026-11-27, 1 agente, v0.41.0)

- Autorização delimitada à **2.1**, testes, imagens e publicação. **Código
  publicado; ganho e aceite no aparelho AINDA NÃO MEDIDOS.** Nenhuma diferença
  de GPU concluída; nenhum modo de qualidade aprovado por esta publicação.
- **CONFIG → SOMBRAS:** um toque cicla **COMPLETAS → SIMPLIFICADAS →
  DESLIGADAS → COMPLETAS**, sem reconstruir a mata, mover câmera/criatura ou
  trocar resolução/MSAA/atlas. COMPLETAS continua padrão em cada partida;
  escolha só de sessão, sem persistência. O controle aparece mesmo com o painel
  desligado, some com CONFIG/vista íntima e reaparece na mesma escolha.
- COMPLETAS: folhas reais e madeira projetam como antes. SIMPLIFICADAS:
  **somente as folhas das copas** deixam de projetar; troncos/ramos, plantas
  baixas e atores conservam seus estados. DESLIGADAS: `shadow_enabled=false`
  na **luz direcional de toda a cena**, inclusive atores, chão e madeira — não
  é apenas “sem copa”. Folhas voltam ao estado original; proxies ocultos.
- [`malhas.gd`](../jogo/mundo3d/natureza/malhas.gd): um octaedro fechado de
  **8 triângulos por ramúsculo**, inscrito na caixa das folhas efetivamente
  geradas naquele ramo, inclusive os três ponteiros. Completas: 544 triângulos
  proxy contra 3.264 de folhas; moldura: 232 contra 976. Não se chama de novo
  `arvore(..., true)` para aproximar uma árvore completa: isso alteraria os
  ramos da variante. As caixas são derivadas **sem consumir RNG** e sem mudar
  vértices, normais ou cores visíveis. Faces com normal geométrica para fora;
  winding e produto normal × centro da face conferidos em teste.
- [`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd): uma malha proxy compartilhada
  por variante (4 internas + moldura), instanciada nos **mesmos transforms e
  setores** das folhas. Emissor `SHADOWS_ONLY`, visível só em SIMPLIFICADAS,
  **filho do lote de folhas**, com transform local identidade: remover/mover
  o lote leva sua sombra. Não cria nó por planta; não prepara destruição nem
  muda a sim. Proxies não entram nas estatísticas de geometria **visível**.
- [`main.gd`](../jogo/main.gd) aplica o modo à mata e ao sol;
  [`hud.gd`](../jogo/hud.gd) emite a escolha. Botão SOMBRAS em
  `(20, TOPO + 460)`; Verificar atualização desceu para `TOPO + 502`.
  [`diagnostico.gd`](../jogo/diagnostico.gd): modo no painel, em cada janela e
  no cabeçalho do **COPIAR REGISTRO**, com a semântica de DESLIGADAS explícita.
  Cada troca limpa **imediatamente** anel, somas e janela incompleta, inclusive
  antes da cópia; uma nova janela não herda leituras antigas. Aviso COPIADO
  anterior também sai na troca. Sem alteração de gestos ou regras.
- Comparação executável com `b5904de`, fontes temporárias fora do git:
  **20 malhas de árvore** (madeira/folhas, 5 seeds, completa/moldura), mapas
  seeds **500/501/20261126**, todos os buffers reais de transforms/cores dos lotes e
  alinhamento dos proxies — **0 falhas**, Compatibility/softpipe. Mesma seed
  500: **82 árvores, 30 moldura, 341 lotes, 1.459 instâncias visíveis,
  691.195 triângulos visíveis instanciados**, idênticos ao original.
  Script/log em `/root/tmp/galapago-2-1-evidencias/comparar.gd` e `comparar.log`.
- Testes focados: **23 testes, 0 falhas** (diagnóstico + natureza), incluindo
  ciclo pelo botão, padrão e nova partida, histórico/registro, luz desligada,
  identidade dos lotes, geometria/caixas/normais externas, proxies filhos,
  sombra da madeira e layout por retângulos. `lint_diagnostics` chamado a cada
  arquivo: harness não tem linter GDScript/Markdown; a prova é o parser/gate do
  projeto. O aviso preexistente de nome da CPU no proot retorna vazio → `n/d`.
- Escopo intocado: atlas **4096**, filtro/bias/blur do sol, resolução/MSAA,
  Pixel Pass, geometria/cores visíveis, densidade/LOD, `sim/`, gestos, dados,
  CI e pendências de conteúdo. Nenhuma dependência, asset, PixelLab ou download
  pago. **Sem benchmark GPU no Android**; software/Movie Maker só prova imagem.
- Oráculo Vulkan local: `LD_PRELOAD=/root/tmp/lvpshim/shim.so
  SHIM_FEATS='-sve,-sve2' MESA_SHADER_CACHE_DISABLE=true QUADROS_RENDER=vulkan
  GALLIUM_DRIVER=llvmpipe DEMO_ARGS='--diagnostico --sombras=<modo>'
  tools/quadros.sh 2 /root/tmp/galapago-2-1-<modo>-vulkan`, uma captura por vez,
  modos `completas`, `simplificadas`, `desligadas`: **6 PNG, exit 0**.
  `q00000001.png` dos três **abertos**; logs confirmam **Vulkan 1.4.318,
  Forward Mobile, llvmpipe (LLVM 20.1.2)**. Mesma seed padrão 20261126, câmera e
  instante de demo (quadro 1, 30 FPS fixos). Árvores/folhas visíveis intactas;
  sombra simplificada é mais maciça/poligonal (troca explícita de qualidade),
  desligada remove as sombras; botão e painel legíveis sem sobreposição.
  Verificar atualização não nasce no build local: retângulo coberto pelo teste.
  Os números exibidos nesta gravação são de software/tempo fixo, **não Android**.
- Prévia local: `DEMO_ARGS='--diagnostico --sombras=<modo>' tools/quadros.sh 2
  /root/tmp/galapago-2-1-<modo>-previa-final`, mesmos três modos, sequenciais:
  **6 PNG, exit 0**, Compatibility/OpenGL 3.3/softpipe; os três
  `q00000001.png` **abertos**. Confirma layout e árvore intacta, não equivalência
  de cor com Vulkan. Uma captura anterior foi cancelada antes da correção de
  winding; não é usada como evidência final.
- Gate imediatamente antes do commit: `tools/testes.sh`, **205 testes
  GDScript, 0 falhas**, parser **51 scripts, 0 erros**, guardião **35 Markdown,
  49 testes**. Log `/root/tmp/galapago-2-1-evidencias/gate.log`; foco
  `/root/tmp/galapago-2-1-evidencias/foco-final.log`; seletivo
  `/root/tmp/galapago-2-1-evidencias/seletivo-final.log`. `git diff --check`
  limpo e busca de segredos do BUILD sem ocorrências. Commit/CI no relatório de
  entrega, sem novo commit só para registrar run ainda em andamento.
