# NPCs da área segura — 11/10/2026

Pedido: simplificar somente os NPCs para combinar com o cenário aprovado e manter escala e função legíveis. Base: 050455d43d86d6af4741c6df6667856ec56953b3.

Os dois habitantes existentes recebem arte nova apenas no Andar 1. Ferreiro: lenço creme, avental marrom, barba curta e martelo cinza. Vendedor: chapéu de palha largo, roupa verde e rosto sem barba. Silhuetas compactas, cores chapadas e paleta compartilhada de até 15 cores. Sem pequenos acessórios decorativos.

Atlas camp_npcs_v2.png: 64x80, dois quadros 32x40 por personagem, corpos úteis de 28x33 e 28x32. Mesmo retângulo de desenho, âncora, posição, duração e alternância do idle anterior. Arte original preservada nos Andares 2–5; FloorView propaga visual_v2 na criação e troca de tema. Sem alteração no explorador, cenário, regras, serviços, colisões ou saves.

Geração: ferramenta integrada imagegen, um pedido para cada NPC com dois quadros lado a lado. Prompts pedem pixel art top-down compacta, proporção chibi compatível com explorador, poucas cores, mãos em idle discreto, transparência e ausência de cenário, brilho e detalhes pequenos. Preparação offline no Godot: limpeza de franjas por alpha, limites comuns entre quadros, redução nearest, paleta de 15 cores e encaixe na linha dos pés existente. Imagens grandes geradas não entram no jogo.

Verificação local: importação Godot 4.5.1, captura real com 34 verificações sem falhas em quatro resoluções; revisão de gameplay mobile. Conferida propagação do tema tanto antes de _ready quanto ao alternar, exatamente dois NPCs e âncoras (606,423)/(606,475) preservadas. Suíte de gameplay e Web registradas na entrega/CI. Celular físico não testado.
