# Arquitetura
- `scenes/`: composição Godot. Main injeta HUD/InputDriver no Player; mapa isolado em world.
- `scripts/actors/`: Player e Enemy, movimentação e coordenação de componentes.
- `scripts/components/`: Health, AutoAttack e DashMotor. Sem dependência da arte/HUD.
- `scripts/input/`: converte teclado/touch em direção e pedido de dash; não move atores.
- `scripts/presentation/`: ActorView e FloorView desenham placeholders; substituíveis por Sprite2D/AnimatedSprite2D mantendo os atores/componentes.
- `ui/`: joystick e ações touch, HP e morte. Só emite comandos e observa estado.
- `data/`: Resources tipados `.tres` para atores/arma. Balanceamento desacoplado.
- `assets/`, `audio/`: fontes futuras. Sem arte final ou áudio artificial nesta fase.
- `tests/`: runner sem plugins; testes executáveis em SceneTree headless.
- `docs/`, `agents/`: contrato, decisões, responsabilidades.

## Fluxo
InputDriver → Player → CharacterBody2D/DashMotor. AutoAttack → seleção de alvo do grupo damageable_enemies → Health. Health → ActorView/HUD. Main compõe referências; não existe singleton global.
Personagens têm shape físico independente do desenho. World layer 1, Player 2, Enemy 3. Atores colidem com World; combate usa distância e HP, não depende de colisão de sprites. Parede bloqueia linha de visão do ataque; IA não contorna obstáculos ainda.

## Desempenho
Física 60 Hz padrão; apenas um inimigo. Seleção de alvo somente no ritmo do ataque (não por frame), sem sort/alocação de lista adicional. Desenho de chão estático; sem luzes, shaders, partículas, navegação, threads ou rede. CPU/GPU e FPS devem ser medidos em dispositivo real antes de ampliar populações. Para escala futura, substituir busca em grupo por índice espacial preservando contrato de seleção; não implementar antecipadamente.

## UI
Canvas expand sem proporção fixa; HUD usa cantos e dimensão atual do viewport. Joystick esquerdo com um índice touch, ações à direita com índices independentes. Limpa comandos ao perder foco. Safe area nativa é aplicada quando disponível. Reservas de habilidades ficam desabilitadas e sinalizadas.
