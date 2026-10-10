# Arquitetura
- `scenes/`: composição Godot. Main injeta HUD/InputDriver no Player; mapa isolado em world.
- `scripts/actors/`: Player e Enemy, movimentação e coordenação de componentes.
- `scripts/components/`: Health, AutoAttack e DashMotor. Sem dependência da arte/HUD.
- `scripts/input/`: converte teclado/touch em direção e pedido de dash; não move atores.
- `scripts/presentation/`: FloorView usa chão/trilhas proceduralmente estáticos e cinco sprites compactos da floresta; ActorView usa atlas de quadros por ator. GuardianView desenha o chefe. Hitboxes são independentes do desenho.
- `ui/`: joystick e ações touch, HP e morte. Só emite comandos e observa estado.
- `data/`: Resources tipados `.tres` para atores/arma. Balanceamento desacoplado.
- `assets/art/`: sprites pequenos em paleta limitada e atlas dos atores; `audio/` reservado.
- `tests/`: runner sem plugins; testes executáveis em SceneTree headless.
- `docs/`, `agents/`: contrato, decisões, responsabilidades.

## Fluxo
InputDriver → Player → CharacterBody2D/DashMotor. AutoAttack → seleção de alvo do grupo damageable_enemies → Health. Health → ActorView/HUD. Main compõe referências; não existe singleton global.
Personagens têm shape físico independente do desenho. World layer 1, Player 2, Enemy 3. Atores colidem com World; combate usa distância e HP, não depende de colisão de sprites. Parede bloqueia linha de visão do ataque; IA não contorna obstáculos ainda.

## Desempenho
Física 60 Hz padrão; até cinco inimigos, incluindo o chefe opcional. Seleção de alvo somente no ritmo do ataque (não por frame), sem sort/alocação de lista adicional. Desenho de chão estático e efeitos de poucos retângulos por quadro; sem luzes, shaders, partículas de nós, navegação, threads ou rede. CPU/GPU e FPS devem ser medidos em dispositivo real antes de ampliar populações. Para escala futura, substituir busca em grupo por índice espacial preservando contrato de seleção; não implementar antecipadamente.

## UI
Canvas expand sem proporção fixa; HUD usa cantos e dimensão atual do viewport. Joystick esquerdo com um índice touch, ações à direita com índices independentes. Limpa comandos ao perder foco. Safe area nativa é aplicada quando disponível. Habilidades observam cooldown; Personagem, mochila e Ferreiro emitem comandos validados pelo Main.


## RPG v0.3.0
GameProgress é a fonte única de XP, atributos, equipamentos, carteira e missões.
RPGRules centraliza curvas e receitas. Player aplica bônus sem acumular e
preserva HP atual ao trocar equipamento. Saves v1–4 migram para v5 com validação
completa antes de alterar memória. Missões adicionais têm contadores limitados;
recompensa somente na primeira conclusão. RootGuardian estende EnemyActor com
três ataques avisados. GuardianView desenha pixel art e telegráficos leves;
nenhuma dependência, mapa adicional, navegação ou partícula foi adicionada.

## Torre v0.5.0
GameProgress possui AscensionProgress, serializado no save v6. Save v1–5 migra
derrotas históricas de Mata; validação é atômica antes de trocar estado em memória.
Main conecta derrotas com origem, marca uma vez por vida e mantém recompensas.
TowerEntrance centraliza posição, interação e corpo físico; TowerView desenha
geometria estática. O menu reutiliza station_panel e seu bloqueio de input.
Só Andar 1 existe; requisitos ficam em FLOORS, conclusão é registrada como falsa.
Não há arena, seleção, teletransporte nem ação para concluir a prova nesta etapa.

## Torre v0.5.1
TowerTrial é RefCounted: fases, identificador de tentativa, roster de cada horda,
conjunto de mortes pendentes e relógio de quatro segundos. Não é serializado.
Main mantém o mesmo Player, HUD e GameProgress, destacando Andar1 da árvore e
instanciando a cena tower_arena (720×540) em um espaço físico separado (1600,0).
Retorno reanexa a Mata e repõe limites originais da câmera; reload libera a cena
retida e inicia no acampamento. Nada altera o arquivo do mundo ou TowerEntrance.

Inimigos reutilizam a fábrica existente e ficam como filhos do Main para manter
validação de origem e recompensas. arena_bounds estende perseguição apenas na
prova, sem sleep/despawn e com quatro paredes; comportamentos dos três tipos e
do elite são mantidos. Limite local seis, Mata cinco. Projectiles ficam limitados
à arena e são descartados ao limpar horda/tentativa. Timer da horda não usa
SceneTreeTimer: só avança em _process_trial, fora de menus. Identificador e
conjunto pendente rejeitam eventos antigos, vivos ou duplicados.

Entrada/saída bloqueiam comandos e físicos durante fade de 0,16s por metade.
Menus da prova pausam criaturas, projéteis e relógio. HUD usa station_panel com
botão de ação de 44px fora do scroll. Minimapa muda para o retângulo da arena;
Mata conserva WORLD_SIZE 1200×900. Health.heal não revive e limita ao máximo;
chamado uma vez no fim das duas primeiras hordas, jamais no fim da terceira.
Após a terceira fase AWAITING_GUARDIAN guarda lugar para integração futura,
sem disparar chefe ou gravar conclusão. Retorno automático na morte aplica
uma perda normal, recuperando HP como o reinício existente; abandono não cura.
