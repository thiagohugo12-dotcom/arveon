# Mata — somente chão e trilha
Pedido de 11/10/2026: trabalhar por partes usando a referência image(20261011-053519).png; neste passe, somente terreno do Andar 1. HEAD inicial 347cc0c476eb4726fdef3ba1bc8e4641b5caefc2.

Gramado claro verde-amarelado, pequenas variações com clusters discretos; trilha bege quente, borda interna mais quente, leves manchas de areia e poucas pedrinhas. O atlas da trilha continua 600×450, filtro nearest e preparado offline. Alpha comparado pixel a pixel com o anterior: idêntico. Centro, largura, ramificações e área ocupada não mudaram.

Árvores, arbustos, flores já existentes, construções, personagens, Torre, HUD, colisões, mundo 1200×900, mecânicas e saves intactos. Andares 2–5 mantêm desenho anterior. Nenhum nó/processo ou dependência em runtime acrescentado. PNG passou de 5.071 a 7.671 bytes. Desenho do gramado reduziu de 250 marcas a 190 clusters; sem geração por quadro.

Arquivos: scripts/presentation/floor_v2_view.gd; tools/generate_mata_v2_paths.py; assets/art/mata_v2/paths.png; este relatório; duas capturas reais do terreno em docs/screenshots/mata-v2/terreno_*.png.

Validação local: importação Godot 4.5.1 sem erros; suíte 1317 verificações sem falhas; QA de renderer/viagem 34 verificações sem falhas em 360×640, 390×844, 640×360 e 960×540. A mesma CI executa importação, contratos, capturas, exportação Web e Chromium antes de publicar TESTE. Resultado remoto confirmado na entrega, não inferido deste relatório.

Capturas são framebuffers reais Compatibility/Mesa, com protagonista e HUD atuais. Nenhuma imagem conceitual ou mockup usado como fundo. Limitação: não medimos FPS ou toque em celular físico. Este passe não altera artes dos demais elementos e não declara a direção inteira concluída.
