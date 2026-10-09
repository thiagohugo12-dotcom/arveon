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
