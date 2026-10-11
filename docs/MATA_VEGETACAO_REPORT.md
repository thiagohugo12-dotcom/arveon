# Mata — somente árvores e arbustos
Pedido de 11/10/2026: simplificar árvores/arbustos do Andar 1, sem modificar terreno aprovado ou posições. HEAD inicial 018f0b17b490eba4fca8d749d201b6fc4345df63.

Duas árvores (verde e alaranjada), mesma distribuição existente, e um arbusto. Copas arredondadas com massas largas de luz/sombra, três tons de folha e três de madeira, sem textura de folhas/bark. Sprites preparados em 44×48 / 18×12 e ampliados nearest a 88×96 / 36×24 para encaixar nas regiões anteriores. Alpha binário. Sombras existentes discretas preservadas.

Atlas final: assets/art/mata_v2/nature_simple.png, 256×112, 5.130 bytes; contém pedras, flores e tufos anteriores copiados pixel a pixel sem mudanças. Original nature.png preservado. FloorV2View muda somente o preload desse atlas. ExplorationView já reutiliza a região do arbusto para ervas; recebe o mesmo visual sem mudar coleta. Zero nós/processos/colisores adicionais.

Terreno/cabana/camp.png, caminhos/paths.png, árvore de colisões, 28 âncoras, 57 colisores, recursos, Torre, NPCs, personagens, HUD, regras, dimensões e saves intactos. Andares 2–5 permanecem no tema anterior. Não criou floresta mais densa.

Geração: imagegen integrado, usando image(20261011-053519).png somente como referência. Prompt inicial: três sprites separados em transparência, árvores verde/laranja arredondadas, cinco a sete massas amplas, três cores de folha, troncos curtos e arbusto pequeno; pixel art top-down compacta mobile, sem folhas individuais, texturas, gradientes, realismo, ornamentos ou cenário.
Prompt da correção: manter os três objetos, posições, proporções e silhuetas; fundir massas pequenas; três tons de folhagem, cinco massas internas amplas, troncos simples com três marrons; remover glow/bloom/haze/fringe/background e gradientes, transparência real fora dos sprites; sem novos objetos/texto. Preparação técnica: isolamento por alpha, encaixe nas regiões existentes, nearest, paleta compacta e alpha binário. Fonte gerada não utilizada como fundo.

Local: Godot 4.5.1 importação sem erros, suíte 1317 verificações sem falhas; renderer real 34 verificações sem falhas em quatro resoluções. Capturas em docs/screenshots/mata-v2/vegetacao_390x844.png e vegetacao_640x360.png. Verificada igualdade dos pixels fora das três regiões substituídas e hashes de paths/camp preservados. CI executa export Web e Chromium antes de TESTE; resultado confirmado na entrega.

Limitações: não medidos FPS/toque em celular físico; uma árvore verde e uma laranja, sem variação adicional de formas. Esta etapa não declara a revisão visual inteira concluída. Aguardar avaliação para a próxima parte.
