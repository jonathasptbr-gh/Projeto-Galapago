# Pedidos em espera — a fila de pacotes

> **Só o operador adiciona ou remove pendências** (conceito e conteúdo de
> criação, confirmados com ele); o GDD não vira pacote sozinho, e decisões de
> história são respondidas quando ele puxar o assunto. Regra completa:
> [`AGENTS.md`](../AGENTS.md) ("Resíduos e pendências").

> **Nada aqui está autorizado por estar na fila: pergunte ao operador qual
> pacote seguir.** Lê-se só o pacote escolhido. Um pacote cabe numa sessão; se
> não couber, divide-se antes de começar.

> **Esta é a LISTA ÚNICA de próximos planos** (reorganizada em 2026-11-26).
> Todo plano novo **confirmado pelo operador** entra aqui como pacote `Pn`
> (2026-11-27: antes dizia "todo plano novo entra aqui", sem a confirmação);
> o que mora em outro lugar está apontado em "Onde mais há pendência", no fim
> do índice.

> **Manutenção registrada (2026-11-24):** a faxina documental A (v0.14.1) e o
> guardião offline B (v0.14.2) já foram feitos; o protocolo de agentes e o
> multi-sessão (P21) ficaram na v0.14.3; o P22 (fila enxuta) foi entregue na
> v0.14.4 e o registro dele fechado na v0.15.0; o P23 (oráculo com baseline)
> ficou na v0.16.0; o P28 (triagem dos resíduos) foi um commit comum em
> 2026-11-26, e o fechamento com as decisões do operador outro, em 2026-11-27. Os pacotes feitos moram em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md), não aqui.

> **Decisões do operador (2026-11-26) — faxina:** o padrão de criatura passa a
> ser **modelo 3D pronto importado do Sketchfab, com pequenos ajustes**. O rig
> próprio (2D e 3D), o mapa Wang 2D, o ensaio da água e o piloto da natureza
> saíram do repositório; **P6, P9 e P10 foram descartados** (registro em
> [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md#p6-p9-e-p10--descartados-commit-comum-2026-11-26)).
> Os resíduos de rig viraram `descartado (rig removido)` em
> [`RESIDUOS.md`](RESIDUOS.md).

> **Decisões do operador (2026-11-25):**
> - **P9 e P10 congelados** (superada em 2026-11-26: descartados, acima).
> - **Controles e gestos maduros e estáveis:** não mexer sem pedido do
>   operador.
> - **P24 — Fundação 3D autorizado** (mesma data): o mundo vira 3D, com
>   Pixel Pass opcional; a câmera gira 360°. Ele autoriza mexer na conversão
>   tela→chão e na câmera; o vocabulário de gestos continua o mesmo.

> **Pedidos diretos do operador (2026-11-26), fora de pacote:** piloto de
> natureza 3D (commit 1842ba3; a cena saiu em 2026-11-26) e o mapa de testes NATUREZA jogável com cores
> vivas (v0.36.0). Os desdobramentos que ele pediu — otimizar o cenário,
> cenário destrutível e os quatro elementos no cenário — viraram P25–P27.

### Frentes (os temas, na ordem em que dependem um do outro)

| frente | pacotes | situação |
|---|---|---|
| Núcleo de jogo | P5 → P8 · P30 | P5 é o próximo do núcleo; P8 é conversa de design; P30 (vida, dano e morte) vai ter, mas não agora |
| Cenário 3D e arena | P24 ✔ → P25 → P26 → P27 | P24 entregue; P25 mede antes de P26/P27 crescerem o custo |
| Personagem e arte | P29 | P6, P9 e P10 descartados (2026-11-26): padrão novo = modelo 3D pronto + ajustes ([MODELOS-3D](MODELOS-3D.md)); P29 escolhe o modelo do cão/lobo; contorno do ator pendente (em P24) |
| Fatia vertical | P7 | junta núcleo + cenário + personagem |
| Manutenção | P28 ✔ | triagem dos resíduos feita (commit comum, 2026-11-26): 25 `obsoleto (3D)`, 20 `resolvido`; registro em [`PEDIDOS-FEITOS.md`](PEDIDOS-FEITOS.md#p28--triagem-dos-resíduos-commit-comum-2026-11-26); decisões do operador aplicadas em 2026-11-27 (104 linhas fechadas) |

### Índice

| pacote | o quê | depende de | estado |
|---|---|---|---|
| P5 | Vivência → evolução (sim) + simulação em massa | P4 ✔ | **próximo do núcleo** |
| P7 | Fatia vertical: arena + cão + gestos + 1 evolução | P2–P5 | na fila |
| P8 | GDD do loop diário no laboratório/ilha | — | na fila (design, conversa) |
| P24 | Fundação 3D: mundo 3D, Pixel Pass opcional, câmera orbital 360° | — | **entregue na v0.35.0**; mapa NATUREZA na v0.36.0 e mapa único em 2026-11-27 (a ilha Fundação saiu); contorno do ator descartado |
| P25 | Cenário 3D: medir e otimizar o custo gráfico | v0.36.0 ✔ | 1.1 e 1.2 concluídas; 1.3 em andamento (validação/publicação v0.38.0 e preparação de coleta autorizadas; referência Android ainda não coletada); demais etapas aguardam autorização individual |
| P26 | Cenário destrutível: vegetação, árvores que caem, arena que se abre | P25 | na fila (pedido 2026-11-26) |
| P27 | Os quatro elementos no cenário (fogo, terra, ar, água) | P26 · P5 (porte) | na fila (design + sim; pedido 2026-11-26) |
| P29 | Modelo do lobo/cão: o Wolf.glb é o melhor disponível? | — | na fila (pedido 2026-11-26) |
| P30 | Vida, dano e morte | design com o operador | na fila — vai ter, **não agora** (decisão 2026-11-27) |

### Onde mais há pendência (apontada daqui, não copiada)

- [`RESIDUOS.md`](RESIDUOS.md): o que cada publicação deixou para trás (0
  linhas `aberto` desde a limpeza de 2026-11-27, "pode limpar todos esses
  resíduos": eram 38; o custo do mapa do chão virou `movido para P25`).
- [`gdd/historia.md`](gdd/historia.md#decisões-pendentes): decisões de
  história — **não são pendência**: respondidas quando o operador puxar o
  assunto (regra de 2026-11-27, `AGENTS.md`).

---

## P5 — Vivência → evolução

- Contadores de vivência (calor, saltos, estudo, …) → perfil de traços →
  regras de limiar → ramo. Ramos em dados.
- `tools/simular.sh`: N vidas com sementes → distribuição de ramos (tabela).
  Ramo inalcançável ou dominante demais = falha de design visível.

## P7 — Fatia vertical

- Uma arena, o cão-base, trajetória + 4 gestos, afinidade baixa × alta
  visível, uma evolução (raposa alada de fogo). APK para o operador.
- **2026-11-26:** P6 (âncora de arte) saiu da dependência, descartado; o
  cão-base virá do padrão novo (modelo 3D do Sketchfab + ajustes).

## P8 — GDD do loop diário

- Conversa de design com o operador → `docs/gdd/loop-diario.md`.

## P24 — Fundação 3D

- **Decisões do operador (2026-11-25):** o cenário passa a ser **3D real**,
  com materiais estilizados (luz em faixas + contorno) e o **Pixel Pass como
  camada final desligável** (baixa resolução interna, quantização, dither
  Bayer ancorado no mundo, ampliação *nearest*). Personagens em **3D** (não
  sprite 2D), para não travar a escolha estética. **Câmera ortográfica
  orbital, giro livre 360°** em volta do foco, pela **barra tátil no topo da
  tela** (retrato): deslizar de um lado ao outro gira. **Vista alta é a
  padrão**; a vista íntima (baixa/perto) é extra bem-vindo, não requisito.
  Compatibilidade com o build 2D atual **não** é requisito; alvo = celular
  médio (otimização fica para depois). Arquitetura definitiva, não protótipo.
- **Medido antes (2026-11-25, cena de teste fora do repo):** 3D + SubViewport
  362×642 + pós + toon + casca + sombra roda no oráculo local (Compatibility,
  softpipe): 120 quadros em 309 s. Vulkan (Mobile e Forward+) com lavapipe
  **cai com sinal 4** neste celular (o mesmo JIT do llvmpipe).
- **Renderizador (decisão do gerente, delegada pelo operador):** **Mobile**
  (Vulkan) como alvo, com *fallback* para OpenGL; shaders escritos para rodar
  também no Compatibility, que vira a **prévia local** do oráculo
  (`--rendering-method gl_compatibility`); a verdade visual é o CI com
  lavapipe. Se o CI não renderizar Vulkan, fica o Compatibility.
- **Fatias (um escritor por vez):**
  1. Renderizador + oráculo + CI (prova: quadros Vulkan no CI verde).
  2. `sim/camera3d.gd` puro: foco, yaw, vistas, snap de texel + resto,
     chão⇄tela como `Transform2D` (ortográfica ⇒ afim). Testes.
  3. `jogo/mundo3d/`: SubViewport, Pixel Pass liga/desliga, shaders toon e
     casca, ilha e objetos a partir de `sim/mundo.gd`, criatura e adversário
     provisórios em 3D.
  4. Integração no `jogo/main.gd`: mundo 3D no lugar das camadas 2D, overlays
     (trilha, mira, perigos, efeitos) na tela pela transformação afim, toque
     pela câmera nova, barra de giro, chave do Pixel Pass, demo girando.
  5. Docs + publicação + APK.
- **Aceite:** no APK, a ilha aparece em 3D, gira 360° pela barra do topo sem
  atrapalhar o desenho do caminho, o caminho cai no chão certo em qualquer
  ângulo e a chave troca pixel art ⇄ 3D liso; testes e CI verdes; quadros
  revisados no chat.
- **Retorno do operador (2026-11-26, no aparelho):** o contorno do animal
  está **bem ruim** no pescoço, no bico/focinho e nos detalhes — mais
  precário que o do cenário. Código conferido: o contorno de tela vale para
  os atores (mesmo passe), mas a linha é por profundidade (afina perto do
  chão) e o vinco (>75°) ignora as formas redondas do ator provisório
  (`jogo/mundo3d/ator.gd`), então quase não há linha interna. Ver os
  resíduos do contorno da v0.35.2/v0.35.4 em [`RESIDUOS.md`](RESIDUOS.md).
  Não consertado; decidir com o operador (ajustar o passe ou esperar a pele
  3D).

## P25 — Cenário 3D: medir e otimizar o custo gráfico

- **Pedido do operador (2026-11-26):** mapas detalhados mais baratos de
  processar, para sobrar folga para destruição e elementos (P26/P27).
- **Antes de otimizar, medir:** instrumentar o APK, isolar uma variável por
  comparação e registrar o resultado. ~691 mil triângulos instanciados e 341
  MultiMeshes são números documentais da v0.36.0, não benchmark desta sessão,
  nem triângulos visíveis/draw calls por quadro. FPS ainda não aferido aqui.
- **Aceite:** comparação antes/depois no aparelho, sem mudar regras/gestos;
  aparência da vista alta aprovada pelo operador; testes e CI verdes quando
  houver entrega de código. Sem promessa de ganho antes da medição.

### Controle de execução — decisão do operador em 2026-11-27

- O operador aprovou inicialmente organizar estas recomendações e iniciar
  **somente 1.1**; depois autorizou **somente 1.2**, com um agente de
  implementação e entrega local, sem commit/CI/APK. Depois de pedido explícito
  com UM agente, suíte completa, commit/push, APK via CI e preparação da medição
  guiada, autorizou **1.3** ("Prossiga para a próxima etapa"). Não autoriza
  otimização nem 2.1. Aprovação do plano não libera as demais etapas nem fecha
  decisões de design.
- **Cada etapa e cada acionamento de agente exigem autorização individual no
  chat.** Antes: apresentar ID, escopo, o que não será tocado, entrega,
  verificações incluídas e número de agentes. Pode-se pedir, na mesma pergunta,
  autorização para UMA etapa e UM agente claramente identificado por função.
- Sem antecipar próxima etapa, criar tarefas automáticas, disparar agentes
  paralelos, retomar agente, chamar revisor ou iniciar nova tentativa ampliada
  sem autorização. Verificação delimitada pertence à etapa autorizada; falha
  fora desse escopo volta ao operador, sem ciclo de reparo aberto.
- Publicação de APK/CI e geração/compra de arte só quando declaradas no escopo
  autorizado. Na etapa documental 1.1 não houve chamada PixelLab, download de
  modelo, publicação, commit ou push; 1.3 autoriza apenas a publicação declarada
  acima, sem arte/modelos. Nenhum valor monetário estimado sem fonte.
- Ao concluir: informar o que foi feito, prova, limites e próxima opção; **parar
  para o operador controlar o ritmo**. Não manter agentes trabalhando ao parar.
- Este roteiro coordena P25, P26, P27 e a avaliação de assets de P29; não cria
  outro pacote, não implementa P5/P30 e não escolhe criatura automaticamente.

### Plano de ação por grupos

Todas as etapas abaixo, exceto **1.1 concluída**, **1.2 concluída localmente**
e **1.3 em andamento/autorizada**, estão **aguardando autorização**.
A ordem é inicial; resultados podem justificar propor outra ordem, nunca
executá-la automaticamente. Cada linha é uma autorização separada, não um lote.
As verificações e limites de cada implementação serão explicitados no briefing
antes da autorização; usar teste seletivo e cumprir o gate do repo se commitar.

| etapa | escopo e entrega delimitados | aceite da etapa |
|---|---|---|
| **1.1** | **Medição — inventário do código e protocolo comparativo**, sem executar o jogo | configuração e limitações registradas abaixo; nenhuma alegação de ganho |
| 1.2 | Medição — painel diagnóstico opcional: FPS, tempo de quadro, chamadas/primitivas quando disponíveis, resolução e renderizador efetivos; sem otimizar | métricas identificadas por viewport/escopo; CPU/GPU indisponível aparece como tal; painel desligável e testes seletivos |
| 1.3 | Medição — versão instrumentada e sessão de referência no aparelho, com publicação declarada no pedido de autorização | amostras comparáveis registradas; custo da instrumentação identificado; nenhum dado do render por CPU usado como desempenho do APK |
| 2.1 | Sombras — comparação completa/desligada e copa simplificada só para sombra, sem alterar atlas | chave diagnóstica, proxy coerente com árvore e comparação no enquadramento fixo |
| 2.2 | Sombras — comparar resolução do atlas separadamente do proxy | diferença de custo e imagem registrada; conferir pés, bordas, serrilhado e bias; não zerar blur cegamente |
| 3.1 | Copas — versão leve das árvores internas na vista alta, detalhada na íntima | silhueta/copa vazada preservadas; transição estável com histerese, guiada por tamanho projetado e vista ortográfica |
| 3.2 | Vegetação — reduzir detalhe/sobreposição e densidade somente decorativa pouco relevante | mesma regra/ocupação, sem sumir cobertura tática; comparar sob copas e em giro; sem trocar automaticamente por cards transparentes |
| 4.1 | Resolução — escala ajustável só do 3D liso, interface nítida | coordenadas/toque/marcas corretos; comparar escala mantendo AA fixo; aparência pixelada continua opcional |
| 4.2 | Antisserrilhado — comparar MSAA isoladamente da resolução | medir custo e serrilhado das folhas/silhuetas, sem mudar visual padrão antes do aceite |
| 5.1 | Chão — redesenho por invalidação, inclusive último quadro de limpeza | caminho, mira e avisos continuam vivos; nada congelado nem marca fantasma |
| 5.2 | Chão — separar marcas persistentes de conteúdo animado somente se o perfil justificar | queimaduras reaproveitáveis sem atrasar avisos; não acrescentar alvos/passes sem benefício medido |
| 6.1 | Setores — comparar granulação dos MultiMeshes já existentes, uma família por vez | registrar compromisso CPU/submissões versus descarte; não igualar número de lotes a draw calls |
| 6.2 | Solo — indexar vértices equivalentes e verificar custo de construção/quadro | mesmos atributos, cores, margem e alturas; sem mudar gameplay |
| 6.3 | Solo — dividir atualização por trechos e avaliar malha mais leve em terra plana | mudança local não reconstrói mapa inteiro; vaus/margens preservados; base para terra destrutível |
| 7.1 | Assets 3D — definir ficha de custo por candidato: malhas, materiais, ossos, clipes, texturas e licença | critérios registráveis, sem baixar/comprar/escolher modelo nesta etapa |
| 7.2 | Assets 3D — avaliar um modelo individual explicitamente escolhido para análise | ficha e prancha no chat; licença/crédito conferidos; aprovação de análise não é aprovação de importação |
| 7.3 | Assets 3D — preparar/importar apenas o aprovado; materiais compartilhados, texturas proporcionais, clipes necessários e LOD se útil | ajuste reproduzível, silhueta/animação conferidas; GLB alterado só por script e crédito; sem refazer rig |
| 8.1 | Destruição/P26 — IDs estáveis e estado de vegetação/árvores na sim, ocupação e deltas por setor | testes puros; planta omitida pelo detalhe gráfico continua existindo na regra |
| 8.2 | Destruição/P26 — vegetação baixa removida por impacto, efeitos reutilizáveis e marcas | atualizar só lotes atingidos; limite visual não impede destruição lógica |
| 8.3 | Destruição/P26 — árvore sai do lote, tomba em objeto reutilizável, vira tronco estático e obstáculo | regra e imagem sincronizadas, sombra acompanha, medir pico de quedas; porte/limiar definidos antes de implementar |
| 9.1 | Água/P27 — recuperar e conferir isoladamente o ensaio escolhido, antes de otimizar | testes de conservação com fontes/evaporação, embalo, barreiras e riacho; não restaurar o protótipo inteiro no jogo |
| 9.2 | Água/P27 — passo fixo, buffers e células ativas com vizinhança | comparação com referência, determinismo e continuidade fora da câmera; nenhuma troca por fluxo só de diferença de nível |
| 9.3 | Água/P27 — campo visual atualizado por regiões alteradas, lâmina orgânica, espuma/filetes e umidade | campo e obstáculos alinhados; medir custo de upload/passes; Mobile e Compatibility; sem exigir compute, SSR ou fluido de partículas |
| 10.1 | Elementos/P27 — contrato comum de altura, ocupação, combustível/umidade e ordem de interação | fechar com operador as regras ainda pendentes; sim testável, sem alteração apenas visual que deixe bloqueios fantasmas |
| 10.2 | Fogo/P27 — propagação na grade e representação limitada/reutilizável de chamas, cinza e marcas | fogo lógico independe do teto visual; testar umidade e medir pico, não só cena já limpa |
| 10.3 | Ar/P27 — vento visual no shader e efeitos de regra separados | sem nó/processo por folha; empurrão/queda dependem da sim, não do shader |
| 10.4 | Terra/P27 — relevo e bloqueios locais sincronizados com a água | buraco/rampa/represa coerentes, atualização só do trecho afetado e testes de fluxo/ocupação |
| 10.5 | Combinações/P27 — integrar uma combinação por autorização adicional, explicitando qual no chat | testes locais por célula e medição de cenário misto; esta linha não libera todas as combinações de uma vez |
| 11.1 | Perfis — montar opções conservadora/equilibrada/econômica a partir do que foi medido | mesma sim/regras em todas; padrão visual decidido pelo operador; sem qualidade oscilando a cada quadro |
| 11.2 | Fechamento — comparação integrada sustentada, inclusive destruição/elementos quando existirem | registrar regressões, picos e limites reais; publicação só no escopo autorizado; sem prometer FPS universal |

**Dependências:** 1.3 precede decisões de ganho dos grupos 2–6. Grupos 8–10
seguem P26/P27 e o porte/elemento previsto em P5; cada regra ainda aberta será
perguntada antes de sua implementação. 6.3 prepara o relevo do grupo 10; 8.1 e
10.1 precisam ser coerentes com 9.2/9.3. Grupo 7 depende da escolha do modelo,
não bloqueia otimizar a mata autoral. Grupo 11 usa apenas recursos já aprovados
e implementados; não é autorização para antecipar sistemas futuros.

### Etapa 1.1 — inventário e protocolo (concluída em 2026-11-27)

**Autorização:** pedido direto no chat para organizar o plano e iniciar a
primeira etapa do primeiro grupo. Execução pelo gerente, sem subagente: o
registro do ritmo depende da conversa completa. Só documentação foi editada.

**Base conferida:** `tools/estado.sh --ci`: publicação v0.37.0, HEAD `c065837`,
Godot 4.7.2, árvore inicialmente limpa, CI #134 success. Isso é estado do
repositório, **não medição de desempenho**. A referência de código deste
inventário é esse HEAD; nova alteração exige reconferir os pontos afetados.

| ponto conferido | evidência | consequência para a medição |
|---|---|---|
| Mobile com fallback OpenGL | [`project.godot`](../project.godot), seção rendering | registrar API/renderizador efetivo no aparelho; não assumir Vulkan só pela configuração |
| Atlas direcional 4096 no mobile | [`project.godot`](../project.godot), directional_shadow | comparar proxy e atlas em experiências distintas |
| Liso usa janela física e MSAA 4×; Pixel Pass usa alvo reduzido sem MSAA | [`vista.gd`](../jogo/mundo3d/vista.gd), `_reconfigurar` | Pixel Pass mistura resolução/AA/pós; não isola gargalo sozinho |
| Contorno de tela excluído do mapa por layers = 0 | [`main.gd`](../jogo/main.gd), montagem da mata | não gastar primeiro em otimizar um passe inativo |
| Árvores agrupadas em setores 12×12; simples só na moldura | [`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd), `SETOR`, `construir`, `_lote` | já existe instancing/setorização; medir granulação, não refazer como novidade |
| Chão usa UPDATE_ALWAYS | [`chao.gd`](../jogo/mundo3d/chao.gd), `_init` | comparar repouso e marcas animadas, preservando avisos |
| Riacho atual é estático; ensaio escolhido removido | [`mapa.gd`](../jogo/mundo3d/natureza/mapa.gd), `_agua`; P27 abaixo | água dinâmica, fogo e destruição não entram como carga já existente |

**Protocolo definido (a executar só em 1.3 ou comparação autorizada):**

1. Identificar build/hash, aparelho, renderizador efetivo, resolução física e
   interna, modo visual, MSAA, sombras, detalhe e limite de FPS/VSync. Usar a
   mesma semente, enquadramento, percurso e quantidade de atores.
2. Aquecer de forma repetível, manter brilho/energia e condições térmicas
   comparáveis. Proposta inicial: aquecimento de 2 minutos e três amostras de
   30 segundos por cenário; confirmar a duração no escopo de 1.3, antes de
   iniciar. Avaliação sustentada mais longa fica explicitada no grupo 11.
3. Cenários: repouso sem marcas, deslocamento com caminho, giro 360°, sob
   copas e combate atual. Vista alta é a principal; íntima é comparação
   adicional. Picos de água/fogo/quedas entram apenas quando implementados.
4. Registrar FPS, tempo por quadro e picos; mediana/p95 quando houver amostras
   adequadas; draw calls/primitivas com origem e escopo da métrica. Tempo CPU e
   GPU só se houver ferramenta/API válida no aparelho; indisponível não vira
   estimativa, e tempo de script não é tempo total de CPU/GPU.
5. Mudar uma variável por vez, repetir a referência e comparar imagem além
   dos números. Se estiver preso no limite de FPS, FPS igual não prova custo
   igual: buscar tempos/folga com suporte real, sem inventar economia.
6. Oráculo/CI por CPU serve para correção visual, não benchmark da GPU Android.
   Validar cores e shader em Mobile e Compatibility; sem custo artificial de
   diagnóstico contínuo que invalide a comparação.

**Resultado desta etapa:** inventário e método estabelecidos. Não houve
benchmark, painel, APK novo, otimização, compra/geração de arte ou agente.
Próxima opção: **1.2**, mediante autorização explícita para a etapa e para
**um agente de implementação**, com consulta de API, testes seletivos e limites
apresentados no pedido. Commit/CI/publicação não estão automaticamente liberados.

### Etapa 1.2 — painel diagnóstico opcional (concluída localmente em 2026-11-27)

**Autorização:** somente 1.2, um agente de implementação, sem subagentes,
commit, push, CI, publicação, APK, arte ou otimização. As alterações anteriores
do gerente neste plano e no contrato foram preservadas. **1.3 não iniciada.**

**Uso:** botão DIAGNÓSTICO na HUD de CONFIG, desligado por padrão. Ligado,
substitui a legenda no alto à direita; o texto ignora toque, não captura gestos.
CONFIG e vista íntima ocultam e suspendem a coleta; reabrir preserva a escolha,
mas inicia uma janela nova. O atalho explícito `--diagnostico` serve ao oráculo.
Não altera câmera, resolução, sombras, AA, Pixel Pass ou regras/gestos.

**Fontes, escopos e limites** ([módulo](../jogo/diagnostico.gd)):

- FPS = quantidade de intervalos entre callbacks `_process` dividida pelo
  tempo real de `Time.get_ticks_usec`; intervalo médio/máximo usa o mesmo
  relógio. Escopo: laço do jogo, inclui espera/VSync/limites e a instrumentação.
- Delta médio de `_process` é separado: intervalo do motor, sujeito a tempo
  simulado/limites/Movie Maker; **não é tempo gasto em CPU nem GPU**. CPU/GPU
  aparecem como `n/d`, não coletados nem inferidos.
- Janela sem histórico, fechada no primeiro callback após **>=0,5 s reais**;
  exibe duração efetiva. Primeiro callback após ligar/reabrir só fixa a origem.
- Interna útil = `vista.tamanho_interno()`; alvo com margem = `vista.sv.size`;
  física = `Window.size`. Renderizador/API = métodos `get_current_rendering_*`
  do `RenderingServer`, nunca a configuração pretendida. Leituras instantâneas
  no fechamento da janela; dimensões inválidas são `n/d`.
- Draw calls/primitivas = `RenderingServer.get_rendering_info` nos respectivos
  `RENDERING_INFO_TOTAL_*_IN_FRAME`: **globais do motor**, último quadro
  disponível, não média da janela nem contadores isolados do mundo 3D.
  Primitivas podem ser pontos/linhas/triângulos; calls não são MultiMeshes.
  Não se conta MultiMesh nem se deriva triângulo de inventário. Sem render,
  antes de dois quadros ou retorno <=0: `n/d`. A API também usa zero para
  indisponível; política conservadora omite até um zero legítimo, sem fingir
  detecção de suporte.
- Custo declarado: relógio/acumuladores por quadro somente ligado; consultas
  RS/dimensões e formatação de texto no fechamento da janela (no máximo 2 Hz).
  Custo não aferido no Android. Desligado/oculto desativa `_process` do módulo.

**Verificação local:** API exata consultada por `tools/godot-api.sh`; import
Godot e parser `--check-only` dos quatro scripts: exit 0. Execução explícita
`GALAPAGO_TESTES=test_diagnostico.gd,test_camera_integracao.gd,test_mapa_natureza_jogo.gd`
com `godot --headless --path . -s res://testes/run.gd`: **13 testes, 0 falhas**,
sem erro de script. O teste novo cobre padrão desligado, cadência/relógios,
indisponibilidade, pausa/reabertura e integração sem mudar render/ações da HUD.
Uma falha inicial (CONFIG reexibia painel desligado) foi corrigida seletivamente.
GDScript/Markdown não têm linter integrado; parser/testes e `tools/docs.sh`
são as verificações apropriadas. Não se rodou suíte completa.

**Oráculo:** `DEMO_ARGS="--diagnostico" tools/quadros.sh 3 /root/tmp/p25-12-painel-final`
(exit 0); PNG final `q00000002.png` aberto e revisado. Houve ajuste delimitado
para ancorar o painel à direita, sem sobrepor o status; controles existentes,
barra e centro do jogo legíveis. Log confirma **Compatibility/OpenGL 3.3 /
softpipe**, 720×1280, Movie Maker fixo 30 FPS. O próprio painel identifica o
Movie Maker como prévia, não benchmark: o delta e o intervalo real divergem.
Aviso local de VSync não suportado registrado; não houve crash/erro de script.
Nenhuma gravação em `/sdcard`. Mobile/Vulkan e desempenho Android não aferidos;
nenhuma alegação de ganho. A entrega local de 1.2 pode ser fechada, sem liberar 1.3.

### Etapa 1.3 — versão instrumentada e referência (em andamento em 2026-11-27)

**Autorização:** "Prossiga para a próxima etapa", após pedido delimitado com
UM agente para suíte completa, commit/push em `main`, publicação do APK pelo CI
e preparação da coleta guiada. A publicação v0.38.0 entrega o painel de 1.2;
não otimiza gráficos nem altera render, AA, sombras, LOD, controles ou simulação.
Sem agentes adicionais, arte, modelos, instalação ou controle do aparelho.

**Validação local:** `tools/testes.sh` completo exit 0 (191 testes GDScript,
0 falhas; parser de 51 scripts sem erro; guardião de 34 Markdown com 49 testes;
ferramentas Node offline). `git diff --check` limpo e grep de segredos sem
ocorrências. Nenhuma correção adicional de código foi necessária.

**Estado:** validação e publicação fazem parte desta execução; a etapa **não
está concluída nem medida** só porque o APK fica disponível. A referência Android
depende de dados enviados pelo operador nesta sessão. A evidência visual local
de 1.2 foi preservada, sem renderização cara adicional; CI valida o oráculo
Mobile/Vulkan por software, que não mede desempenho Android.

**Primeira coleta proposta, leve:** atualizar pela Release `dev`/atualizador,
confirmar versão/build e manter vista **ALTA**, mesmo enquadramento e modo visual.
Ligar DIAGNÓSTICO na HUD visível (MOSTRAR reabre a HUD se CONFIG a ocultou).
Após estabilizar brevemente, observar cerca de **10 segundos em repouso** e
mandar uma captura do painel com modelo do aparelho, modo liso/Pixel Pass,
renderizador/API, resoluções física/interna/alvo, FPS, intervalo real médio/máximo
e duração da janela. Registrar condições de energia/calor e limite de FPS/VSync
se conhecidos, sem mudar configuração só para medir. Esta coleta inicial não é
as três amostras sustentadas propostas em 1.1, nem permite inferir p95 ou ganhos.

**Limites:** CPU/GPU seguem `n/d`; delta do motor não é custo de CPU/GPU.
Draw calls/primitivas são globais do último quadro disponível, não média da
janela nem só o mundo 3D. A janela inclui a instrumentação; seu custo Android
não foi aferido. CONFIG oculto e vista íntima suspendem o painel/coleta;
Movie Maker/softpipe/lavapipe são provas visuais, não benchmark do aparelho.
Nenhuma gravação em `/sdcard`, download/instalação de APK ou medição automática
no aparelho foi autorizada por este roteiro. Entregar os links e parar, sem 2.1.

## P26 — Cenário destrutível

- **Pedido do operador (2026-11-26):** o mapa detalhado deve ser o mais
  destrutível possível no hardware atual — árvores caem quando uma criatura
  maior esbarra nelas durante um ataque, o tiro destrói vegetação e árvores,
  o fogo queima (fogo é P27). Objetivo: imersão e a **arena de combate**, uma
  área que se abre ao longo da batalha e favorece estratégia.
- **Princípio:** destruição **encenada, não física** — a regra é da `sim/`
  (grade de células, semente, testável); o `jogo/` só anima. Sem motor de
  física para lascas.
- **Fatias:**
  1. vegetação baixa (capim, samambaia, arbusto): o tiro a remove; partículas
     curtas e marca no mapa do chão;
  2. árvores com resistência: caem quando o golpe vence a resistência (porte
     da criatura × força do golpe; tiro forte também), tombando na direção do
     golpe numa animação de ~1 s; o tronco caído vira obstáculo nas células
     que ocupa e pode ser destruído depois;
  3. estado persistente durante a batalha (a arena "abre"); regenerar ou não
     entre batalhas é decisão de design.
- **Dependência:** "criatura maior" pede um **porte** por criatura (não existe
  ainda; rig próprio removido, evolução é P5) — começar com um porte provisório em
  dados.
- **Custo:** baixo a médio — trocar uma instância de MultiMesh por um nó
  animado e voltar a ela é barato; a destruição **reduz** o que se desenha.

## P27 — Os quatro elementos no cenário

- **Pedido do operador (2026-11-26):** fogo, terra, ar e água são os elementos
  do combate das criaturas e afetam o cenário. Análise registrada para a
  conversa de design:
  - **fogo:** empurra, destrói, derruba (um "objeto invisível" com área) e
    **espalha** por uma grade de combustível/umidade (perto do rio queima
    menos); árvore queimada vira tronco carbonizado; limite fixo de chamas
    visíveis (10–15), o resto é cor/cinza no chão;
  - **terra:** como o fogo no impacto, mas **permanente** — muda a grade
    (barreira, rampa, buraco), o que a sim já sabe representar por célula;
  - **ar:** empurra e derruba sem destruir; sacode copas e vegetação (vento
    visual barato), espalha ou apaga fogo e água;
  - **água:** **sem simulação de fluido** (cara demais para o celular e
    imprevisível). Proposta: água como **campo na grade** — cada célula guarda
    um nível de água que se espalha para as vizinhas mais baixas e evapora com
    o tempo (temporária), desenhada como superfície rasa e poças; efeitos de
    regra: apaga fogo, deixa o chão encharcado (mais lento, escorregadio),
    empurra no jato, enche buracos da terra. É "física mínima" barata:
    alguns milhares de células atualizadas poucas vezes por segundo.
- **Conceito escolhido para a água (decisão do operador, 2026-11-26):** o do
  ensaio do commit `64f0d2f` — **água de grade**: canos virtuais na sim (fluxo
  com embalo e atrito, conserva, não sobe parede, riacho com nível fixo,
  evaporação sobretudo da água parada, umidade do chão), desenhada como
  **lâmina suave com borda orgânica** (a grade vira textura suavizada; borda
  da poça por limiar com ruído, espuma e filetes no sentido do fluxo) e **chão
  úmido** que escurece onde molhou. Lição: o modelo só por diferença de nível
  era lento demais em encosta suave (a água virava película); os canos
  virtuais resolveram. O ensaio (`sim/agua.gd`, `testes/test_agua.gd`,
  `agua_ensaio.tscn`/`.gd`, `agua.gdshader`) saiu do repositório na faxina de
  2026-11-26 e é **recuperável por esse commit**; no jogo ficou só o
  `usar_umidade` (desligado) do `natural.gdshader`.
- **Referências de jogos (de memória, não conferidas):** superfícies de
  combate do *Divinity: Original Sin 2* (poças, combinações, temporárias),
  água por bloco/célula do *Minecraft* e do *Terraria* (barata, roda em
  celular), fogo pelo capim e vento do *Zelda: Breath of the Wild*. O caro é
  fluido de verdade (*From Dust*, *Noita*) — fora do escopo.
- **Combinações** dão a profundidade tática: água apaga fogo, terra represa
  água, ar espalha fogo, fogo seca lama.
- **Depende de:** P26 (estado destrutível na grade) e P5 (elemento/porte da
  criatura). Decisões do operador pendentes: duração dos efeitos, se a água
  sobe de nível em buracos, se o fogo pode sair do controle.

## P29 — Modelo do lobo/cão: o Wolf.glb é o melhor disponível?

- **Pedido do operador (2026-11-26), para o futuro:** analisar se o `Wolf.glb`
  (Quaternius, CC0 — candidato registrado em
  [MODELOS-3D](MODELOS-3D.md#candidatos-registrados-2026-11-26)) é o melhor
  modelo de lobo/cão disponível para a criatura-base.
- Comparar com os outros candidatos do arquétipo (husky, shiba, raposa) e com
  busca nova (`tools/sketchfab.mjs buscar wolf|dog`): licença do padrão,
  clipes que o jogo pede (andar, correr, pular, atacar, parado), faces, estilo
  ao lado da mata. Prancha por CPU de cada finalista, mostrada no chat.
- Entrega: recomendação com opções; a escolha é do operador. O escolhido entra
  em `arte/modelos/` com o `.credito.txt` (fluxo do guia).

## P30 — Vida, dano e morte

- **Decisão do operador (2026-11-27):** o jogo **vai ter** vida, dano e
  morte, **mas não agora**. Até lá vale o que está no código: os golpes
  empurram e atordoam, ninguém perde vida (`dados/adversario.json`, "NÃO há
  vida nem dano", v0.14; [`RESIDUOS.md`](RESIDUOS.md) v0.5.0 `combate`).
- Resíduos que fecham aqui (estado `movido para P30` em
  [`RESIDUOS.md`](RESIDUOS.md)): v0.23.1 `morte` (tomba e para, sem vida nem
  renascimento), v0.23.0 `vida/dano` (`hit`/`death` dormentes) e v0.21.0
  `combate` (`hit`/`death` no catálogo, sem regra de vida). Relacionado: v0.25.0
  `animação` (`shot`/`hit`/`death` sem acionar), `descartado (operador)` em
  2026-11-27 com a máquina de animação 2D, que saiu.
- A decidir com o operador antes de codar: quem tem vida (criatura, inimigo,
  ambos), o que tira vida (golpe, tiro, perigos, água), o que acontece na
  derrota (renascer onde, o que se perde) e como a vida aparece na tela.
- Regra na `sim/` com teste (`AGENTS.md`); os clipes `hit`/`death` vêm do
  modelo 3D escolhido (P29/P7).
