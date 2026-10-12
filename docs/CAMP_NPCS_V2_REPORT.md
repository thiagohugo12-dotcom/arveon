# NPCs da área segura — 11/10/2026

Pedido: simplificar somente os NPCs para combinar com o cenário aprovado e manter escala e função legíveis. Base: 050455d43d86d6af4741c6df6667856ec56953b3.

Os dois habitantes existentes recebem arte nova apenas no Andar 1. Ferreiro: lenço creme, avental marrom, barba curta e martelo cinza. Vendedor: chapéu de palha largo, roupa verde e rosto sem barba. Silhuetas compactas, cores chapadas e paleta compartilhada de até 15 cores. Sem pequenos acessórios decorativos.

Correção de aplicação: o primeiro atlas reduziu excessivamente a arte e alternava dois quadros com braços deslocados. Atlas camp_npcs_v2.png agora usa 80x96, com duas regiões idênticas 40x48 por personagem, e corpos úteis de 34x44 e 36x41. A pose é estável, sem animação lateral. O retângulo cresceu de forma moderada, mantendo os pés nas mesmas âncoras e uma altura próxima ao explorador. Arte original preservada nos Andares 2–5; FloorView propaga visual_v2 na criação e troca de tema. Sem alteração no explorador, cenário, regras, serviços, colisões ou saves.

Geração: ferramenta integrada imagegen, um pedido para cada NPC com dois quadros lado a lado. Prompts pedem pixel art top-down compacta, proporção chibi compatível com explorador, poucas cores, mãos em idle discreto, transparência e ausência de cenário, brilho e detalhes pequenos. Preparação offline no Godot: limpeza de franjas por alpha, recorte da pose principal, redução nearest sem quantização de cores e encaixe na linha dos pés existente. Imagens grandes geradas não entram no jogo.

Verificação local: importação Godot 4.5.1, captura real com 34 verificações sem falhas em quatro resoluções; revisão de gameplay mobile. Conferida propagação do tema tanto antes de _ready quanto ao alternar, exatamente dois NPCs e âncoras (606,423)/(606,475) preservadas. Suíte de gameplay e Web registradas na entrega/CI. Celular físico não testado.
