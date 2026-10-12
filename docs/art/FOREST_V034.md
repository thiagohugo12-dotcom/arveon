# Floresta Viva — kit visual v0.3.4

A imagem aprovada nesta tarefa orienta a paleta: trilhas de terra ocre quente,
folhagem do verde amarelado ao azul petróleo, sombras profundas e madeira quente.
Os sprites são criações originais isoladas, com transparência; não são recortes
do cenário de referência. A resolução nativa no jogo é 112×112 (árvore larga),
88×112 (árvore alta), 78×112 (conífera) e 40×32 (arbusto), todos com filtro nearest.

| Recurso | Papel | Ponto de ancoragem |
| --- | --- | --- |
| `forest_oak_v034.png` | copa larga e raízes | centro do pé, base da imagem |
| `forest_linden_v034.png` | copa alta e tronco bifurcado | centro do pé, base da imagem |
| `forest_spruce_v034.png` | conífera | centro do pé, base da imagem |
| `forest_shrub_v034.png` | sub-bosque | centro da base |
| `forest_refuge_v034.png` | construção do refúgio (96×96) | canto superior esquerdo, porta voltada ao Baú |

Não há dependência de shader, luz dinâmica ou quadros de animação. Os ativos
pequenos ficam independentes para permitir proporções diferentes no mapa. O
terreno e as trilhas são desenhados proceduralmente sobre a geometria existente;
nenhum sprite acrescenta colisão nem muda o movimento.
