# Guardião e Torre do Andar 2 — implementado localmente em 20/10/2026

Status: **implementado na versão local**, por pedido explícito de Thiago. Sem publicação nesta etapa.

## Escopo

- O Colosso de Arenito ocupa a arena já existente no sudeste do Vale. A interação por proximidade inicia a luta opcional, sem criar uma segunda arena nem novos estados de save. A derrota usa o estado `guardian_defeated` do Andar 2.
- A Torre da área segura usa entrada própria de arenito. A prova mantém as três hordas e a progressão existentes, mas usa Goblin Garimpeiro, Tatu Rochoso e Escorpião da Chapada.
- O guardião final da Torre usa a folha do golem fornecida pelo usuário, organizada em cinco linhas: repouso, caminhada, ataque, dano e morte. Ataques e avisos compartilham a lógica da Torre; o tema de pedra troca a apresentação. A vitória registra a prova do Andar 2 e libera a viagem para o Andar 3 pelo sistema atual.
- O Andar 1 conserva sua Torre e seu Guardião da Mata.

## Valores provisórios

- Colosso opcional: 540 HP base, velocidade 38, raio de colisão 34. Pancada circular com raio 110; fissura frontal com alcance 210; três fragmentos disparados em leque. O multiplicador existente do andar continua aplicado.
- Guardião da Torre: 520 HP base, velocidade 52, raio de colisão 34. O multiplicador existente do andar continua aplicado. As cinco ações avisadas e a fase 2 seguem a lógica compartilhada da Torre.
- As recompensas e requisitos de entrada não foram redesenhados. Ajustar HP, dano, intervalos e recompensas após teste humano de combate em celular.

## Arquivos centrais

- `assets/art/andar2/refined/sandstone-guardian-atlas.png` e `sandstone-ascension-tower.png`: arte usada em jogo.
- `tools/build_sandstone_guardian.py`: reconstrução reproduzível do atlas a partir da folha aprovada.
- `scripts/actors/sandstone_colossus.gd`, `scripts/presentation/sandstone_colossus_view.gd`, `scripts/presentation/sandstone_tower_guardian_view.gd`, `scripts/presentation/floor2_tower_view.gd`: ator e apresentação.
- `scripts/components/tower_trial.gd`, `scripts/presentation/tower_arena_view.gd`, `scripts/main.gd`, `ui/hud.gd`, `data/floor2_layout.gd`, `data/floor_config.gd`: integração com prova, mundo, interface e progressão.

## Validação

`tests/floor2_guardian_tower_tests.gd`: 22 verificações, 0 falhas, incluindo entrada, quatro pontos de integração do Colosso, três hordas, guardião final, aviso do ataque, salvamento, desbloqueio e retorno. `tests/andar2_integration.gd` e `tests/mining_integration.gd` passaram sem falhas. Godot 4.5.1 Compatibility carregou o jogo e gerou nove capturas reais em `../Registros/andar2-guardiao-torre/capturas/`, inclusive em tela vertical.

Pendente de observação humana: dificuldade real no touch, ritmo dos ataques e aparência em aparelhos modestos. A liberação do Andar 3 é progresso de campanha; este trabalho não cria cenário próprio para ele.
