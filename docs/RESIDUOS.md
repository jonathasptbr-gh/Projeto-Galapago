# Resíduos — o que o lote viu e não consertou

> Toda versão deixa uma linha aqui antes do push, mesmo que seja "nenhum".

| versão | onde | o quê | tamanho |
|---|---|---|---|
| v0.1.0 | `jogo/main.gd` `_draw` | traço de 1 px sai com falhas nas diagonais (snap de vértice + `draw_polyline` largura 1) | pequeno — trocar por desenho por pixel (Bresenham) ou largura 2 quando a arena chegar (P3) |
| v0.1.0 | `ci.yml` | ~~oráculo llvmpipe/x86_64 não provado~~ — **resolvido**: CI #1 (`cfdbb34`) verde com o passo de quadros | — |
| v0.1.1 | cofre / histórico da sessão | a chave do PixelLab passou pelo chat: está no log da sessão de 2026-11-20 | operador gera chave nova e troca no cofre; agente reinicia/confirma com `get_balance` |
| v0.3.0 | jogo | sem altura nem colisão: a criatura anda sobre o mar e sobe o planalto como chão | P3/P4 (ver `docs/gdd/mapa.md`) |
| v0.3.0 | `arte/criaturas/cao_base_prova.png` | sprite de LADO num mapa visto de CIMA | P6 decide a vista da criatura |
| v0.3.1 | atualizador | o caminho Android (shell_open → FileProvider → instalador) foi conferido no código do Godot, NÃO num aparelho | o operador reinstala uma vez e testa a próxima atualização |
| v0.3.1 | git (público) | `tools/android/galapago-dev.keystore` + senha seguem no histórico | revogado na prática; nunca reutilizar |
| v0.3.0 | `tools/pixellab-tileset.mjs` | com o job FALHO no servidor, fica esperando ~2,5 min em vez de falhar logo | pequeno — consultar o status antes de baixar |
| v0.3.0 | `arte/cenarios/objetos/arvore.png` | sombra desenhada na arte (desligamos a nossa para não dobrar) — as outras artes não têm | P6: padronizar (sombra sempre nossa) |
| v0.2.0 | `ci.yml` | Actions avisa: `checkout@v4`, `setup-java@v4`, `cache@v4` ainda miram Node 20 (forçadas a Node 24) | pequeno — subir as versões quando houver v5 confirmadas |
| v0.2.0 | `tools/android/exportar.sh` passo 5 | no CI #6 o `apksigner verify` não imprimiu linha (o `aapt` sim); a assinatura foi conferida localmente com `keytool -printcert -jarfile` | pequeno — investigar a saída do apksigner 37 no próximo lote do CI |
| v0.2.0 | `export_presets.cfg` | pacote `com.projetogalapago.jogo` e keystore de dev são provisórios; trocar qualquer um obriga desinstalar | decidir antes da 1ª distribuição externa |
| v0.2.0 | P2 | o APK não foi testado em aparelho pelo agente (instalar é do operador) | o operador instala e risca |
| v0.1.1 | `arte/fonte/p1-cao-base-pixen.png` | prova sem paleta-mestra (64 cores livres) e câmera ainda não decidida — não é asset do jogo | resolve no P6 (âncora de arte) |
