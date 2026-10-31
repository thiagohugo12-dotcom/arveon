# Protagonista 2.0 — integração da Espada e das animações normais (31/10/2026)

Status: APROVADO como design oficial por Thiago; integração local (sem push, sem TESTE/PRODUÇÃO).

Fonte: `ARVEON_Protagonista_2_0_Espada_e_Animacoes_Normais.zip`, copiado byte a byte para
`art_source/protagonista_2_0/` (não importado pelo Godot). Folhas derivadas por
`tools/build_protagonist_v2.gd` em `assets/art/protagonist_v2/` e layout gerado em
`scripts/presentation/protagonist_v2_layout.gd`.

## Inspeção das pranchas
- Todas têm transparência real (o "fundo" da Corrida e da prancha completa é RGB sob alfa 0);
  opacos com alfa ~253. Resíduo quase invisível (alfa ≤ 29/255) afastado das poses é descartado.
- Não são grades regulares: efeitos e lenços passam para a vizinha. Cada quadro sai pelos
  componentes com alfa ≥ 0,25, peças soltas inteiras ao dono e brilho por inundação. Dois ajustes
  explícitos no Básico: a ponta externa do arco do quadro 4 encosta no lenço do quadro 5.
- A arte não tem grade de pixel nativa. Redução única (Lanczos, pré-multiplicada) para 3 texels
  por pixel do mundo: 1:1 num celular 3×, mip 1 exato numa tela 1,5×. Filtro sem bilinear
  (`NEAREST_WITH_MIPMAPS`), mipmaps no import.
- Tamanho: altura de frente em repouso = 64 px no mundo, igual ao explorador anterior (pés em
  y = +12). Escala entre folhas pela altura da cabeça nas posturas neutras: Básico ×0,79,
  Estocada ×0,85; a prancha completa está a 0,48 da folha do Básico, logo a Guarda é ampliada
  ×1,62 (resolução menor que as demais).
- Âncora: Idle/Corrida pelo tronco sem lenço na linha de chão de cada linha; golpes pelo pé de
  trás plantado (o avanço do corpo é preservado).

## Integrado
- Idle 4 quadros × Frente/Costas/Esquerda/Direita, 0,18 s por quadro (GIF), última direção mantida.
- Corrida 6 quadros × 4 direções no lugar da caminhada, avançando 19,8 px por quadro
  (0,11 s do GIF a 180 px/s): sem deslizar em qualquer velocidade. O Dash usa a mesma corrida
  por distância, como antes. Sem sprint, stamina ou botão novo.
- Ataque Básico da Espada, Direita (Esquerda espelhada): quadros 1–3 na preparação (fim do
  cooldown, janela visual de 0,18 s; a busca do alvo é só leitura), quadro 4 (golpe) no mesmo
  tick do dano do AutoAttack, 5–6 na recuperação. Dano, alcance, intervalo e combos inalterados.
- Estocada Precisa, Direita/Esquerda: 6 quadros no relógio de `SwordTechniqueTiming` (contato =
  quadro 4). Golpe linear: o efeito procedural mantém só os rastros retos até o alcance; a
  crescente de preparação e a faísca amarela saem porque a arte já traz rastro e faísca.
- Guarda Reativa, Direita/Esquerda: 4 quadros de guarda (ativação, dois arcos, guarda mantida
  parado; correndo durante os 3 s, corpo normal de corrida). O contra-ataque segue evento separado.
- Kamusari (ultimate), Direita/Esquerda — autorizado por Thiago (“Pode colocar o kamusari
  tbm”): 8 quadros da linha 4 da prancha. O corte vermelho do quadro 4 encosta no arco do
  quadro 5 com alfa cheio; a pose fundida é dividida na coluna 779 (entre a ponta do corte e a
  cauda do arco) e os fragmentos soltos vão inteiros para o quadro dono. Pés registrados à mão
  (régua de 10 px), porque a luz vermelha cobre as botas. Mesmo relógio da técnica (0,485 s):
  0,05/0,06/0,05/0,055 até o contato (0,215 s), em que entra o arco (quadro 5), e
  0,08/0,07/0,06/0,06 depois. O disco do alcance real e o corte que atravessa continuam; só as
  fitas circulares junto ao corpo saem, pois a arte já as desenha. Folha 3288 × 326 (≈ 4,3 MB).
- Contra-ataque da Guarda, Direita/Esquerda — pedido de Thiago (“Faça o resto”): 6 quadros
  da linha 2 da prancha, depois das 4 poses da guarda. Os quadros 2–4 se tocam pelos arcos;
  cortes em degrau (o arco do 2 passa por cima da cabeça do 3) os separam sem partir arco ou
  bota. Pés medidos à mão (no 3 a bota de trás está erguida). É a reação visual ao bloqueio
  (sem dano próprio) e ocupa os mesmos 0,22 s de antes: 0,02/0,04/0,05/0,045/0,035/0,03;
  depois volta a guarda mantida. Recebendo o golpe em movimento, o corpo segue na corrida
  (sem deslizar), como na guarda mantida.
- Corte Crescente, Direita/Esquerda: as 5 poses da linha 3. O dano é imediato no uso (sem
  contato cronometrado nas regras) e a pose 1 já corta com o arco, então os 5 quadros cobrem
  os mesmos 0,30 s visuais: 0,05/0,06/0,07/0,06/0,06. A fita do alcance real (115 px) segue.
- Ruptura Ancestral, Direita/Esquerda: as 5 poses da linha 3 (carga, salto, impacto com
  erupção, rescaldo, recuperação). Como o dano é imediato, a animação começa no impacto
  (quadro 3 da prancha) e cobre os mesmos 0,34 s: 0,12/0,11/0,11. A carga e o salto ficam na
  folha sem uso; mostrá-los antes do impacto exigiria atrasar o dano (mudança de mecânica,
  só com aprovação). Os rastros do alcance real (205 px) seguem.
- Chão medido nas botas da linha 3 (y 700): o brilho do arco e os destroços descem abaixo
  dele. Folhas novas: contra 1530 × 226, Crescente 1180 × 295, Ruptura 1785 × 300
  (≈ 4,9 MB RGBA, ≈ 6,5 MB com mipmaps).
- Dano (lampejo), Derrota (fade) e Dash continuam com o feedback anterior sobre o novo corpo.

## Pendências (arte atual mantida)
- Cima/Baixo de todos os golpes e técnicas: o pacote só traz a vista lateral.
- Talho Ágil (Skill 1) e demais armas (Machado, Lança, Arco, Cajado): sem arte no pacote.
- Retratos de menu: a branch `dev/sistemas-andares-dados` está trocando o retrato da tela de
  equipamento por `DiaryPortrait` (ainda com o explorador anterior). Trocar para o
  Protagonista 2.0 quando as duas frentes se encontrarem, para não gerar conflito.

## Espelhamento da Esquerda — APROVADO
Thiago aprovou em 31/10/2026 manter a Esquerda como a arte da Direita espelhada (“Manter
espelhado”) nos golpes da Espada (Básico, Estocada, Guarda e os seguintes). `ProtagonistV2Art.MIRROR_LEFT`
fica ligado; arte própria da Esquerda, se vier, entra como nova linha em `ATTACK_ROWS`.

Novas direções ou técnicas: acrescentar a folha em `JOBS` do construtor e a linha em
`ProtagonistV2Art.ATTACK_ROWS`; a apresentação já consulta essa tabela.
