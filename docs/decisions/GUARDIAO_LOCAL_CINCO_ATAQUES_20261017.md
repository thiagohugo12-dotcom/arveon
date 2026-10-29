# Guardião da Mata: novo visual e cinco ataques

Status: AUTORIZADO — pedido explícito de Thiago em 17/10/2026 para implementar o Guardião e criar duas habilidades. Somente local.

Integrar o atlas de quatro direções e oito poses já disponível no protótipo, ligado ao estado real do chefe (repouso, preparação, contato, recuperação). Mantém o chefe opcional separado. O visual não modifica colisão, HP, recompensas, progressão ou save.

## Duas habilidades novas — balanceamento provisório

- Onda de Raízes: aviso de 1,10 s; anel de raio 28 até 160 px durante 0,65 s, espessura de contato 12 px para cada lado; 16 dano antes da defesa/escala do andar. Pode ser evitada ficando fora do alcance ou entrando no centro após a passagem. Aviso mostra centro seguro e limite externo.
- Sementes Ancestrais: aviso de 0,90 s em três trajetórias fixadas na preparação (-25°, 0°, +25°); três sementes de contato 12 px, 240 px/s por 0,90 s (216 px). 14 dano antes da defesa/escala do andar. Não perseguem o jogador; respeitam paredes e limites da arena.

Rotação determinística de cinco ações: raízes, espinhos, investida, onda, sementes. Todos compartilham bloqueio de um único dano por execução, pausam em menus e limpam avisos/efeitos ao morrer. Fase 2 conserva avisos/dano e recuperação original 20% menor. Ataques existentes preservados.

## Implementação e validação

O jogo principal instancia TowerGuardianView com atlas do protótipo, repouso/caminhada e seis poses de ataque/recuperação ligados ao relógio real. Barra e feedback locais ficam acima da copa. Preparação de sementes mostra três sementes luminosas; onda e leque têm avisos e efeitos contínuos sem recortes de PNG.

- `guardian_local_skills_tests.gd`: 204 verificações, zero falhas. Inclui chefe instanciado no jogo principal após hordas, quatro direções, passos de 1/120 s, 1/30 s e 0,25 s, avisos sem dano, dano único, pontos seguros, mira fixada, pausa modal, paredes reais, limites, limpeza, fase 2 e inspeção real das habilidades na revisão.
- Regressões: 281 verificações, zero falhas; preserva ataques antigos, recompensas e tentativa da Torre.
- Revisão visual: 237 verificações, zero falhas, incluindo controles e layout móvel.
- Capturas reais de aviso/execução nas quatro direções em `outputs/ARVEON/Revisoes/guardiao-integrado`; capturas de jogo principal e das habilidades na revisão inspecionadas.
- Logs em `outputs/ARVEON/Registros/guardiao-final-*`. Sem export Web, publicação ou teste em aparelho físico.

Total: 722 verificações sem falhas. Os números novos são balanceamento provisório para avaliação humana local. Alteração preexistente de project.godot preservada fora do commit.
