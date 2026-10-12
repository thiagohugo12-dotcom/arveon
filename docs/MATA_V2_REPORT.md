# Mata V2 — Andar 1

## Entrega e escopo
Aplicação autorizada pelo pedido de Thiago em 11/10/2026. Referências:
image(20261011-045221/045228/045310/045335/045345).png e a nova remessa
image(20261011-050011/050015/050019/050026).png. Inspecionadas; usadas como
linguagem visual, nunca recortadas como mapa ou reutilizadas como fundo.
Somente a aparência externa do Andar 1 muda. Main seleciona o tema pela
identidade do andar; FloorView conserva seu desenho anterior nos Andares 2–5.
Nenhum campo novo de save. Não depende de progresso salvo para escolher tema.

Verde vivo amarelado, areia dourada com borda pixelada irregular, copas
orgânicas arredondadas verdes/laranja, troncos curtos, sombras discretas,
rochas/vegetação, cabana de madeira, vendedor/forja e Torre de pedra/musgo.
Arestas nearest-neighbor. Explorador, NPCs, inimigos, habilidades e HUD atuais
preservados; sem nova spritesheet de personagem, mapa ou mecânica.

## Arquitetura
FloorV2View é um pintor RefCounted, substituível, usado somente quando
FloorView.visual_v2 está ativo. Todos os comandos são registrados no canvas
do FloorView durante _draw. Não cria nós, colisores, timers ou processamento
por quadro. Os helpers existentes continuam a pintar cercas, baú e objetos
nas mesmas âncoras. TowerView e ExplorationView recebem o mesmo flag visual.
Trilhas usam a lista original e suas larguras, preparada offline numa textura
600x450 desenhada a 2x. Isso evita milhares de comandos de stamps por desenho.

Protegidos: cenário 1200x900, arquivos .tscn do mundo/arena, gerador físico,
28 pés de árvores, 57 colisores, posição da Torre, NPCs/serviços, coletas,
rotas, combate, progressão, saves e controles. Não há alterações a main/PRODUÇÃO.

## Assets / geração
- assets/art/mata_v2/nature.png: atlas 256x112, 18.678 bytes.
- assets/art/mata_v2/camp.png: atlas 256x176, 25.357 bytes.
- assets/art/mata_v2/paths.png: textura 600x450, 5.071 bytes.
Total: 49.106 bytes PNG. Texturas compartilhadas; alpha 0/255.
Geração pelo imagegen integrado, seguida de isolamento de sprites, redução
nearest-neighbor e 24 cores por prop. Nenhuma dependência nova em runtime.
Pillow é usado somente no preparo offline, não na exportação ou no jogo.
tools/generate_mata_v2_paths.py reproduz caminhos lendo as constantes vigentes.

Prompts: sprites originais de RPG top-down acolhedor, pixel art comercial
simplificada, clusters nítidos, poucos tons e massas largas de luz/sombra;
copas orgânicas arredondadas verde/laranja, troncos curtos expressivos, pedra,
arbusto, grama e flores; separado numa folha transparente sem chão/texto.
Segundo conjunto: pequena cabana artesanal de madeira/telha terracota,
barraca de lona amarela com cestos, forja/anvil, portal antigo de pedra/musgo
com abertura escura. Luz superior esquerda, cores quentes/vivas; evitar
polígonos genéricos, círculos montados, ruído, suavização, gradientes, rótulos,
cenário inteiro ou cópia dos recursos de Moonlighter.

## Validação local
Godot 4.5.1: importação sem erros; 1317 verificações existentes sem falhas.
Journal: 9 testes sem falhas. QA real novo: 34 verificações sem falhas, com
16 capturas, alternância do tema, preservação de âncoras/colisores/inventário,
viagem real aos Andares 2–5 mantendo tema original e retorno ao 1.
Resoluções: 360x640, 390x844, 640x360 e 960x540. Capturas são framebuffers reais
GL Compatibility com software Mesa; não são montagens ou conceitos.
CI executa a suíte completa, 233 capturas totais, export Web e os 24 testes
Chromium de save/campanha/amostra. Resultado final deve ser confirmado na entrega.

Diagnóstico local: 154 nós / 57 colisores, igual ao baseline. Abertura 662,83 ms
nesta execução (não é benchmark comparável entre máquinas). Memória estática
32.744,5 KiB, aproximadamente +2,5 MiB pelo carregamento/cache da arte nova.
Não medimos FPS em celular físico. Sem shaders, partículas, iluminação dinâmica
ou novos processos. As rochas respeitam o retângulo físico existente; suas
proporções variam para continuar representando toda a região sólida.

## Como testar
Abrir TESTE normal, carregar/começar no Andar 1, observar acampamento, caminhar
pelas trilhas e visitar Torre no extremo leste. Joystick/Dash/interações continuam
iguais. Se já houver Andar 2 desbloqueado, viajar e confirmar visual anterior,
depois voltar ao 1. Save não exige reset; não usar cheats no save do jogador.
A amostra separada anterior continua sendo uma demonstração independente.
