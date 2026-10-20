# Andar 2 — prévia dos três monstros

Esta etapa apresenta a arte para aprovação. Não há surgimento de inimigos no mapa, IA, dano, drops, missões ou alteração de saves.

## Abrir

Execute `Revisar monstros Andar 2.bat` ou abra `scenes/demos/floor2_monsters_preview.tscn` na Godot 4.5.1 e pressione F6. Toque nos nomes para trocar o monstro e nos botões inferiores para ver as animações. O botão **Isolar / comparar** alterna entre o trio e o monstro selecionado ao lado do protagonista. Em janela vertical, a cena mostra automaticamente o monstro selecionado e o protagonista.

## Arte e animações

O visual oficial dos três monstros segue as imagens fornecidas em 19/10: goblin na imagem 2, escorpião na imagem 3 e tatu na imagem 4. A imagem 1 mostra outro personagem, um golem. Os sprites foram editados com ImageGen a partir dessas referências e montados por `tools/build_floor2_reference_sheets.py`, sem redesenhar características. As fontes transparentes da edição ficam fora do jogo em `../Registros/andar2-monstros-fonte/`.

Cada folha RGBA tem 432 × 320 pixels: células de 72 × 64, seis colunas e cinco linhas. Os totais por linha são 4/6/6/3/6. Células não utilizadas ficam transparentes. O filtro nearest e a escala na prévia mantêm a aparência de pixel art; o protagonista atual usa quadros de 32 × 40 pixels.

| Monstro | Estados |
|---|---|
| Goblin Garimpeiro | repouso, caminhada, picareta, dano, morte |
| Tatu Rochoso | repouso, caminhada, investida, dano, morte |
| Escorpião da Chapada | repouso, caminhada, ataque com pinças, dano, morte |

`scripts/demos/floor2_monster_actor.gd` cria AnimatedSprite2D e configura SpriteFrames, tempo e repetição dos estados. `scripts/demos/floor2_monsters_preview.gd` é apenas a interface de demonstração. Os monstros não são instanciados pelas cenas da campanha.

## Validação local

`tests/floor2_monsters_capture.gd` verificou os três atores, as cinco animações de cada um, as contagens 4/6/6/3/6 e a troca de estados: 0 falhas. Produziu oito capturas reais na Godot, incluindo enquadramento vertical em 390 × 844. A importação do projeto terminou sem erros. O empacotador exige fundo transparente, células preenchidas sem cortes e base vertical alinhada.

Capturas: `../Registros/andar2-monstros-previa/` (em relação à pasta do projeto pai).

## Próxima etapa, após aprovação

Integrar colisão, IA, ataques com aviso, atributos, distribuição por região e os futuros materiais ao sistema de drops existente. Ajustar timing e silhuetas conforme o feedback visual antes dessa integração.
