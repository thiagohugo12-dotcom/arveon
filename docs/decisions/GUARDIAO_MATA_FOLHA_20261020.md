# Guardião da Mata — folha fornecida pelo usuário

Status: **implementado localmente** em 20/10/2026, por pedido explícito de Thiago. Esta alteração não foi publicada na Vercel.

## Escopo

O chefe da Torre do Andar 1, Guardião da Mata, lê quadros diretamente de `assets/art/andar1/forest_guardian_sheet.png`, uma cópia intacta da folha enviada. Os recortes de repouso, caminhada, golpe, impacto e morte acompanham os estados reais de `TowerGuardian`. O ataque de raízes, os espinhos, a investida, a onda e as sementes mantêm seus avisos, instantes de contato e regras atuais. O lado esquerdo espelha o quadro frontal; a folha não contém costas nem perfis completos.

O Guardião das Raízes opcional no mapa continua com sua apresentação própria. O Colosso e o guardião da Torre do Andar 2 também não mudaram.

O ponto inicial do chefe na arena foi deslocado para uma posição central que preserva 170 unidades de distância do jogador. Antes, a nova copa ultrapassava a borda superior da tela ao surgir. HP, colisão, danos, recompensas, requisitos da Torre, progressão e save permanecem iguais.

A barra fixa da HUD já informa nome, HP e fase. O rótulo repetido junto ao sprite foi retirado para manter a leitura no celular; números de dano continuam próximos ao chefe.

## Validação

- Godot 4.5.1 importou a folha e carregou os scripts sem erro.
- `tests/forest_guardian_integration.gd`: 23 verificações, 0 falhas; cobre três hordas, surgimento, cinco ações, quadros visíveis, contato, colisão, HP e desbloqueio do Andar 2.
- `tests/floor2_guardian_tower_tests.gd`: 22 verificações, 0 falhas, assegurando a prova do Vale.
- `tests/forest_guardian_capture.gd`: seis capturas reais em `../Registros/andar1-guardiao-floresta/capturas/`, inclusive em tela vertical.
- A suíte antiga `guardian_local_skills_tests.gd` não concluiu sua transição de interface em tempo nesta execução. Ela não forneceu resultado de regressão; os testes dirigidos acima cobrem o fluxo alterado.

Pendente: teste humano do ritmo da animação no celular. A arte de origem mostra somente o personagem visto de frente, portanto os deslocamentos para cima mantêm essa vista.
