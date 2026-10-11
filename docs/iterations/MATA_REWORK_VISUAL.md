# Mata — rework visual simples

Base real verificada: 46bb6b7a3ff4f4e50442eb86c73dde7dc9eda82d,
feat/andar1-v020-primeiro-passe. Referência anexada image(20261011-040235).png
inspecionada antes das alterações. Direção inspirada em Moonlighter, com
menos detalhe e menor densidade; não é reprodução de assets do outro jogo.

## O que mudou
- Solo oliva acolhedor, plano, sem o mosaico/ruído anterior de mais de mil tiles.
- Trilhas existentes em areia quente, borda discreta e poucas marcas de desgaste.
- Atlas 128×48 com três copas (verde oliva, verde frio, ocre) e um arbusto,
  massas largas com poucos planos de luz, sem textura de folhas individuais.
- Copas menores: 64×80 no mundo, com tronco/raízes legíveis e sombra simples.
- Vegetação: 56 candidatos decorativos em vez de 260, sem segunda passada
  de 42 detalhes. Pequenas flores/grama/escombros não bloqueiam movimentação.
- 34 → 28 árvores: seis secundárias removidas sem rerrolar os demais pés.
- Rochas simplificadas em três planos, mantendo os dois footprints físicos.
- Torre conserva posição/corpo/regras, com pedra mais clara, poucos detalhes,
  portal verde/runa após desbloqueio e título com contraste no novo chão.
- Cabana, serviços, NPCs, protagonista, monstros, arena, HUD e menus preservados.

Não há nova região, Andar 2 novo, habilidade, mudança de save ou balanceamento.
Os cinco andares continuam instanciando a mesma Mata e recebem o visual.

## Colisões e navegação
Cena scenes/world/andar_1.tscn e scripts/world/andar_1_obstacles.gd não mudam.
Limites exatamente 1200×900; paredes/rochas/serviços mantidos. Torre em
(1130,455), com corpo e entrada originais. Andar1Obstacles lê tree_positions:
ao retirar os seis pés, retira os mesmos seis círculos, sem obstáculos invisíveis.
Testes físicos conferem cada um dos 28 troncos e os seis pontos desocupados.
Testes anteriores de caminhos, rochas, área segura, Torre, interação, minimapa,
joystick, cinco andares e progressão continuam passando.

## Leveza
Atlas importado de 1.415 bytes; os três PNGs de copa anteriores somam 8.591
bytes, permanecem no Git mas ficam excluídos do export Web. Redução de 83,5%
nessa parcela de arte; atlas também inclui o arbusto. Arena conserva seu BERRY.
Atlas sem mipmaps, filtro nearest e RGBA nominal de 24 KiB. Gerador Godot local:
godot --headless --path . --script res://tools/generate_mata_atlas.gd
É ferramenta de reprodução, não executada na abertura/frame do jogo.
Chão/desenhos estáticos, sem shaders, luzes, partículas, navegação nova ou
dependências. Uma textura compartilhada nos cinco andares.

Probe local, cinco execuções por versão: mediana startup 822,08 → 690,42 ms;
160 → 154 nós, 63 → 57 colisores, memória estática 30.628,2 → 30.230,3 KiB.
Medidas de abertura variam com ambiente/carga e não equivalem a FPS mobile.
A execução final de prova coincidiu parcialmente com QA GL; a CI registra
novamente seu probe. FPS/térmica/consumo em aparelhos físicos não validados.

## Validação
- Importação Godot 4.5.1 sem erros.
- Primeiro passe: 1.275 verificações sem falhas.
- Suíte final: 1.317 verificações sem falhas, incluindo os 42 novos contratos
  de troncos removidos/mantidos, atlas/alpha e limites preservados.
- Nove testes do journal JavaScript, sem falhas; sintaxe do verificador válida.
- Nove cenários de renderização GL real, 213 PNGs, incluindo 13 da Mata em
  360×640, 390×844, 640×360, 960×540 e visão geral QA de 1200×900.
- CI repete suíte/importação/probe/capturas e exporta Web release. Chromium
  valida 21 fluxos reais de persistência, arsenal e campanha antes de publicar.
- TESTE aplica no-store no HTML/loader/PCK. Após publicar, SHA-256 do HTML/PCK
  servido pelo alias fixo deve corresponder exatamente ao export testado.
  Este controle evita declarar uma publicação correta apenas pelo estado READY.

Capturas em docs/screenshots/mata-clean. Não são mockups: são cenas do jogo
renderizadas pelo Godot. Overview altera apenas câmera/viewport da ferramenta
QA; nunca modifica tamanho/limites/câmera do jogo.

## Aprovação visual e limitações
Abra https://grande-arvore-rpg-teste.vercel.app/ no celular, continue o save e
percorra trilha leste, norte e entrada da Torre. Teste em retrato/paisagem,
colisão nos troncos/pedras e interação. A campanha/desbloqueios anteriores
continuam disponíveis; nenhum progresso de teste é inserido no save real.
Elementos antigos do hub, monstros e coleta mantêm a arte anterior, conforme
escopo. Esta é uma base visual simples para aprovação, sem redesenhar esses
elementos ou interfaces. Touch físico/Safari/iOS/FPS exigem teste em aparelhos.
Publicação remota só é declarada após sucesso da CI e comparação do alias.
