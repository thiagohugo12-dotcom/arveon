# Animação de espada V1 — demonstração

Status: APROVADA para integração ao jogo e atualização do TESTE fixo,
conforme “aprovado, pode colocar” de Thiago em 13/10/2026.
Outras quatro armas e publicação em produção continuam fora do escopo.

- Ponto de retorno aprovado: `checkpoint-espada-v1-aprovada-2026-10-14`, commit `8a07d93`.
- Aplicar os mesmos frames ao ataque básico de espada no Andar 1, preservando
  caminhada, habilidades, feedback de dano, cadência e saves v11.
- Cancelar poses pendentes ao trocar arma, bloquear controles, morrer ou sair
  da apresentação do Andar 1. Demais armas e apresentação legada permanecem iguais.
- Manter a demonstração comparativa disponível como referência.

- Checkpoint: `checkpoint-antes-animacao-espada-v1-2026-10-13`, commit `72cc349`.
- Reutilizar explorador `actors_v4/people.png` e espada `diary_v2/items_skin.png`.
- Animar braço, postura e arma em camadas, nas quatro direções. Caminhada original.
- Usar PlayerActor/AutoAttack reais; preservar dano, alcance, intervalo, colisões e progressão.
- Cena separada, perfil somente em memória, sem carregar/gravar saves.
- Aprovação visual recebida: o alias TESTE fixo pode receber esta integração.
- Não modificar cenário, monstros, NPCs ou as outras quatro armas.

A preparação pode antecipar o término do cooldown quando já existe um alvo válido.
O sinal de ataque inicia o corte; o dano continua imediato no sistema original.
No primeiro ataque, sem cooldown anterior, o corte começa imediatamente: não se
adiciona atraso de gameplay para exibir uma preparação artificial.
