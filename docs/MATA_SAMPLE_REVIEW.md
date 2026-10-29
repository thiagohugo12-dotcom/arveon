# Mata — amostra para aprovação artística

## Escopo e reprodução
Cena: `res://scenes/demos/mata_art_sample.tscn` (abrir no Godot 4.5.1 e F6).
Web: entrada independente `/amostra-mata/index.html`, compartilhando o engine
exportado. WASD/setas ou joystick; Espaço ou Dash. Não acessa o save.
Recorte existente (704,256)–(1088,640); pés das árvores (811,364)/(931,406)
e pedra na região (760,520,90,110), conferidos contra FloorView atual.
Nenhum arquivo de mapa, combate, personagem, progressão ou persistência mudou.
O retângulo demonstrativo é limitado, sem inimigos, coleta, serviços ou Torre.

## Comparação artística — ainda depende da direção
- Referência local `01-1000485522.png`: floresta verde, caminho quente,
  sombras profundas, copas naturais. A amostra reduz vegetação e objetos,
  mantendo recorte orgânico e contraste. Não copia recursos da referência.
- Conceito `image(20261011-040235).png`: chão amarelado, areia clara, poucas
  massas de folhagem e troncos curtos. A amostra usa a mesma intenção de
  cor/legibilidade; as folhas estão mais recortadas que no conceito.
- Publicado 810c3137, capturas `screenshots/mata-clean/`: piso mais apagado
  e copas geométricas. A amostra troca isso por verde vivo, areia dourada,
  contorno irregular, luz superior esquerda e sombra inferior direita.
- Explorador: atlas 48px e animações existentes, sem redesenho. Árvores
  96x108/84x108, pedra 44x34; o filtro é nearest e o alpha das props é binário.
  As massas das copas e os pés são ordenados por Y para o personagem passar
  à frente/atrás. Sem suavização, luzes, shaders ou partículas.

As capturas são do framebuffer do Godot GL Compatibility, não mockups:
360x640, 390x844, 640x360 e 960x540. Mostram a escala real de jogo.
A cena fixa a câmera no recorte para comparação; não representa a navegação
final nem a densidade do mapa inteiro. A pedra mantém o corpo físico antigo,
mais conservador que sua nova silhueta; adequar arte/corpo exige avaliação
posterior, sem modificar a colisão da Mata nesta entrega.

## Assets e prompt
`assets/art/mata_sample/props.png`: atlas 256x144, 19.918 bytes;
`floor.png`: piso estático 384x384, 5.198 bytes. Total 25.116 bytes de PNG.
Recorte, redução nearest-neighbor, 16 cores por prop e alpha 0/255 na integração.
A folha de origem foi gerada como arte nova; os sprites finais estão no Git.
Nenhuma dependência nova do jogo. Não há geração de arte por quadro.

Prompt de criação (síntese fiel): original transparent woodland RPG sprite
sheet, cheerful commercial simplified top-down pixel art; two asymmetrical
organic green trees, sculpted scalloped leaf masses, four warm greens, upper
left light, expressive small forked brown trunks; gray stepped rock, small
leaf bush and two isolated grass tufts. Crisp grid, few details, strong
silhouette; no circles assembled together, generic polygon trees, vector
art, gradients, smoothing, blur, labels, character or background. Moonlighter
readability as influence, never copied assets. Integration keeps the actual
Explorer unchanged. Ground authored with sparse two-pixel marks, sand matching
the original path center lines and widths.

## Validação local
- Godot 4.5.1: importação sem erros.
- Suíte: 1317 verificações, zero falhas.
- Journal do navegador: 9 testes, zero falhas.
- Cena real: 19 verificações, zero falhas (âncoras existentes, limites,
  isolamento, movimento, colisão de tronco, Dash, quatro resoluções e capturas).
- CI: executa também export Web e Chromium, incluindo entrada independente,
  orientação mobile e preservação do journal. Resultado final informado na entrega.

Não medimos FPS em celular físico. Capturas mobile são em viewports reais
renderizados por software GL; aparência e desempenho no aparelho devem ser
aprovados pela direção. A migração do mapa NÃO foi realizada. PARAR aqui.

## Referência oficial V2 recebida durante a validação
`image(20261011-044056).png` foi inspecionada integralmente: copas arredondadas
com massas largas de luz/sombra, troncos curtos, chão amarelo-verde, areia
quente, vegetação orgânica e protagonista compacto. Registrada em
`design/ART_DIRECTION_V2.md`. A amostra converge na paleta quente, contraste,
profundidade e pixel nítido; suas folhas são mais recortadas/angulosas e seus
troncos mais altos que a V2. Isso deve ser avaliado artisticamente antes de
qualquer aplicação. A nova direção não significa aprovação desta amostra.
