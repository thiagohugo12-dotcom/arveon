# Animação de espada V1 — demonstração

Status: APROVADA para demonstração isolada, conforme pedido de Thiago de 13/10/2026.
Aplicação no jogo principal e expansão para outras armas: aguardam avaliação visual.

- Checkpoint: `checkpoint-antes-animacao-espada-v1-2026-10-13`, commit `72cc349`.
- Reutilizar explorador `actors_v4/people.png` e espada `diary_v2/items_skin.png`.
- Animar braço, postura e arma em camadas, nas quatro direções. Caminhada original.
- Usar PlayerActor/AutoAttack reais; preservar dano, alcance, intervalo, colisões e progressão.
- Cena separada, perfil somente em memória, sem carregar/gravar saves.
- Preview exclusivo; nunca atualizar o alias TESTE fixo antes da aprovação visual.
- Não modificar cenário, monstros, NPCs ou as outras quatro armas.

A preparação pode antecipar o término do cooldown quando já existe um alvo válido.
O sinal de ataque inicia o corte; o dano continua imediato no sistema original.
No primeiro ataque, sem cooldown anterior, o corte começa imediatamente: não se
adiciona atraso de gameplay para exibir uma preparação artificial.
