# Game Design — fundação v0.1
Fonte de verdade das decisões conhecidas, baseada no pedido de 07/10/2026. Nome provisório: grande-arvore-rpg.

## Decisões confirmadas e protegidas
- Godot 4.x, GDScript, 2D, Compatibility, mobile-first, Windows e Web.
- UI responsiva; orientação livre; foco em celulares modestos.
- Primeiro vertical slice: **Andar 1 — Mata dos Primeiros Passos**. Não implementar Andar 2.
- Movimentação normalizada em 8 direções no teclado e joystick touch analógico.
- Ataque básico automático seleciona inimigo vivo, válido e dentro do alcance da arma.
- Dash fica no lado DIREITO da HUD, segue movimento atual ou última direção quando parado.
- HUD reserva Skill 1, Skill 2, Ultimate e poção, sem inventar seus efeitos.
- HP, um inimigo provisório e colisões básicas. Assets provisórios substituíveis sem reescrever gameplay.
- Git é a fonte oficial. Checkpoints funcionais são preservados.

## Regras provisórias deste protótipo
Valores ajustáveis em `data/`: jogador 100 HP, velocidade 180 px/s; arma 120 px, 12 dano, intervalo 0,65 s; inimigo 48 HP, velocidade 70 px/s, contato 8 dano/1 s.
Dash: 0,14 s a 620 px/s, cooldown 1,2 s; mantém colisões, não concede invulnerabilidade. Ataque escolhe o alvo mais próximo com linha de visão desobstruída por World. Empates mantêm o primeiro do grupo. Inimigo persegue até 480 px, para a 28 px e ataca até 36 px. Sem pathfinding nesta etapa.
Morte do jogador para movimento/ataques e exibe reiniciar. Morte do inimigo remove o provisório; não há drops ou respawn automático. Reiniciar recarrega o slice. São escolhas técnicas de teste, não definição da economia ou progressão final.

## Fora do escopo / pendente
História, classes, skills, economia, inventário, progressão permanente, multiplayer/backend, chefes, arte final, tamanho e orientação definitiva. Nenhuma decisão do projeto anterior foi presumida como aprovada aqui.

## Alterações estruturais
Agentes sugerem via ADR em `docs/decisions/`. O dono aprova; Director registra e atualiza este documento. Sem aprovação, contrato vigente permanece.
