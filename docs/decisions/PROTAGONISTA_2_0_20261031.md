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
- Dano (lampejo), Derrota (fade) e Dash continuam com o feedback anterior sobre o novo corpo.

## Pendências (arte atual mantida)
- Cima/Baixo de todos os golpes (sem arte): ataque e técnicas antigos, com o explorador anterior.
- Contra-ataque da Guarda: 5 dos 6 quadros fundidos na prancha.
- Corte Crescente e Ruptura Ancestral: a prancha tem 5 + 5 poses (não 6 + 6), com arcos fundidos.
- Kamusari: 8 poses, mas os quadros 4–5 estão fundidos pelo corte vermelho.
- Talho Ágil (Skill 1), demais armas (Machado, Lança, Arco, Cajado) e retratos de menu.
- Espelhamento da Esquerda: `ProtagonistV2Art.MIRROR_LEFT` desliga se Thiago preferir o ataque antigo.

Novas direções ou técnicas: acrescentar a folha em `JOBS` do construtor e a linha em
`ProtagonistV2Art.ATTACK_ROWS`; a apresentação já consulta essa tabela.
