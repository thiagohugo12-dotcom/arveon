# Revisão de jogabilidade, balanceamento e qualidade — 31/10/2026

**Status:** AUDITORIA + PLANO. Itens 1–3 da seção "Implementado" são ajustes locais pequenos e
reversíveis, sem mudança de save. Todos os itens "PROPOSTA" aguardam aprovação de Thiago e
**não** foram implementados.

**Base:** `dev/expansao-andares-3-4` em `f1714a9`. Números calculados a partir de
`FloorCatalog`, `EquipmentEconomy`, `RPGRules`, `ArsenalRules`, `GameProgress` e `Main`.

## 1. Auditoria

### Crítico

1. **Não existe cura fora da morte.** `Health.heal` só é chamado entre hordas da Torre (+15%).
   No campo, no acampamento e ao entrar na Torre o HP nunca sobe. A forma mais eficiente de
   voltar à vida cheia era morrer (custo: 1 material comum da mochila). Morrer de propósito
   virava a "poção" do jogo. → **Corrigido** (Implementado 1).
2. **O Vendedor vende Couro/Seda/Essência em todas as raridades, até Místico, por 5–30 ouro.**
   Junto com a forja direta em qualquer raridade, uma arma Mística custa ~535 ouro
   (145 + 7 Couro Místico + 6 Essência Mística). Drops, raridade dos materiais e pity perdem
   função. Obs.: hoje esse é o **único** caminho para materiais Lendários/Místicos e para
   aprimorar armas Lendárias/Místicas — nenhuma fonte de drop chega acima de Épico. → PROPOSTA A.
3. **O Andar 3 não gera nenhum material.** `DROP_TABLE` cobre só os tipos 0–4 e `LOOT.drops`
   só 0–7. Limo, Sapo, Vulto e Jacaré dão só XP/ouro; não há coletas, baús, troféu nem receitas
   do Pântano. A Mãe dos Sussurros (Guardião de campo) rende 3–5 materiais base. Consequência
   direta: a missão comum "Colete materiais" **travava para sempre** no Pântano.
   → Missão **corrigida** (Implementado 2); drops em PROPOSTA A.

### Alta

4. **Incentivo invertido entre andares (XP e ouro por HP de inimigo):**

   | Andar | Mult. inimigo | Mult. recompensa | XP por HP | Ouro por abate |
   |---|---:|---:|---:|---:|
   | 1 Mata | 1,0 | 1,0 | ~0,26 | 3,5 |
   | 2 Vale | 1,5 | 1,1 | ~0,15 | 3,9 |
   | 3 Pântano | 3,78 (2,1 × 1,8) | 2,6 | ~0,18 | 9,1 |

   O Andar 1 é a melhor fazenda de XP, ouro e materiais (é o único com material base) para
   sempre; o Andar 2 rende ~40% menos XP por dano que o 1, com mais risco. → PROPOSTA B.
5. **Salto de poder Andar 2 → 3 sem ponte de equipamento.** Dano por golpe: Vale 12–20,
   Pântano 34–53 (Jacaré 68). Não há equipamento do Pântano, e os conjuntos do Andar 1/2 dão
   +13 a +25 HP por peça. Só o nível e a forja via Vendedor ajudam. Depende de A. O ×1,8 foi
   decisão de 29/10; recomenda-se medir no save de teste nível 30 antes de mexer.
6. **Armas à distância dominam e o ataque automático as torna seguras demais.** Arco 250 px /
   0,8 s e Cajado 220 px (orbe teleguiado) contra Espada 75 px / 0,72 s, sem prêmio de dano no
   corpo a corpo. O jogador (180 px/s) é mais rápido que todos os inimigos (máx. 128), e o básico
   automático dispara andando: dá para recuar atirando sem levar dano dos comuns corpo a corpo.
   Lança também supera Espada nos números base (115 px, +2 dano, +6 velocidade). → PROPOSTA C.
7. **Evolução de raridade incoerente com o custo e com as peças.**
   - Arma: evoluir zera +N e os bônus de marco; comum→Místico custa ~1.550 ouro (com
     Vendedor), 3× a forja direta em Místico (~535), que também nasce +0. Evoluir nunca compensa.
   - +20 vale muito mais que raridade: +20 dá +20 dano e até +20 nos marcos; Místico dá +10.
   - Peça de conjunto: evoluir **não** zera o aprimoramento, mas a raridade não altera
     atributos (decisão de 26/10). Evoluir custa recursos sem ganho nenhum.
   - Peças vão só até +3 (forja antiga, sem falha nem marcos); armas até +20. → PROPOSTA D.

### Média

8. Javali, Javali Elite e Tatu causam dano de contato a cada 1 s **sem aviso** quando colados
   (só a investida tem preparo). Os demais inimigos avisam antes. O comportamento está aprovado e
   coberto por `local_enemy_feedback_tests`. → PROPOSTA E.
9. Elite só existe no Andar 1. As hordas 3 do Vale e do Pântano não têm elite, ao contrário da
   regra da Torre v0.5.1 (5 comuns + 1 elite). Elite = Javali com mais HP, sem padrão próprio.
10. Jacaré Ancião (mini-chefe repetível a cada 120 s) tem 1.436 HP, quase o mesmo da Guardiã do
    andar (1.512), e não deixa nenhum item.
11. Missão comum paga 40/30 XP fixos em qualquer andar; no Pântano vale menos que um abate (~57).
12. Proficiência: Espada tem desbloqueios até 55; as outras quatro armas param em 25 com teto 60
    (35 níveis sem novidade).
13. Penalidade de morte: −1 unidade do primeiro material comum (quase sempre Couro). Percentuais
    de XP/ouro seguem pendentes desde v0.2.1.

### Polimento futuro

14. HUD: o botão "Poção" fica sempre visível, desativado ("Poções ainda não disponíveis"), num
    lugar nobre para o polegar. Layout aprovado; só esconder com aprovação.
15. HUD: avisos longos ("Mãe dos Sussurros · evite as manchas e as raízes!") encostam na
    borda direita em 360 px.
16. Arte faltando (não improvisar): **Sapo Venenoso** repouso e morte; **Limo do Brejo**
    movimento, dano e morte.

### O que está bom e deve ser preservado

Ataques do Pântano e dos chefes saem no quadro de contato da arte (testes `andar3_*`); preparo
visível em Aranha, Mandacaru, Vulto, Limo e Sapo; Dash sem invulnerabilidade é coerente com
avisos curtos; pity raro/épico; selo de proteção só consumido quando faria diferença; mochila
que transborda para o Baú sem perder item; gemas só por mérito (primeiro Guardião de campo),
sem monetização agressiva; estrutura da Torre (50 abates + 3 hordas + Guardião).

## 2. Plano priorizado

| # | Item | Impacto | Risco | Esforço | Dependência | Situação |
|---|---|---|---|---|---|---|
| 1 | Cura na área segura | Crítico | Baixo | P | — | Implementado |
| 2 | Missão de coleta no andar sem materiais | Crítico | Baixo | P | — | Implementado |
| 3 | Barra de HP dos chefes de campo na HUD | Alto | Baixo | P | — | Implementado |
| A | Materiais do Pântano + Vendedor limitado | Crítico | Médio | M | saves sem mudança | PROPOSTA |
| B | Recompensas do Andar 2 e missões por andar | Alto | Baixo | P | — | PROPOSTA |
| C | Prêmio do corpo a corpo / custo de atirar andando | Alto | Médio | M | testes de combate | PROPOSTA |
| D | Evolução coerente (armas e peças) | Alto | Médio | M | A | PROPOSTA |
| E | Aviso no contato de Javali/Elite/Tatu | Médio | Médio | P | teste aprovado | PROPOSTA |
| F | Elites no Vale/Pântano, Jacaré com loot | Médio | Médio | M | A | PROPOSTA |

## 3. Implementado (local, sem mudança de save)

1. **Recuperação na área segura** (`scripts/main.gd`): dentro da área protegida do acampamento,
   onde inimigos e projéteis não chegam, o explorador recupera 12% do HP máximo por segundo
   (cheio em ~8 s). Para com menu aberto, durante a Torre e em transições. Fora do acampamento
   continua sem cura, então o combate e o risco do campo não mudam. Valor provisório:
   `Main.CAMP_REGEN_PER_SECOND`.
2. **Missão comum no Pântano** (`common_mission.gd`, `main.gd`): em andar sem pontos de coleta,
   "Colete materiais" passa a contar derrotas, com o mesmo alvo (5) e a mesma recompensa (30 XP,
   10 ouro), e a HUD mostra "Derrote criaturas". Quando o Pântano ganhar materiais, a regra se
   desliga sozinha, porque depende de `Exploration.resources_for_floor`.
3. **Barra de chefe de campo** (`hud.gd`, `mission_banner.gd`, `main.gd`): Guardião da Mata,
   Colosso, Mãe dos Sussurros e Jacaré Ancião usam a mesma barra da HUD do Guardião da Torre
   (nome, fase quando existir, HP) quando o jogador está a até 380 px fora do acampamento. Em
   360×800 o nome desenhado sobre a Mãe ficava sob o painel da missão. A bússola do painel agora
   some com a barra, porque cobria o texto "HP", inclusive na Torre.

Testes: `tests/revisao_jogabilidade_tests.gd` (unidade + integração real com `main.tscn`,
capturas 360×800 opcionais com `QA_RENDER_DIR`).

## 4. Propostas (aguardam aprovação)

**A — Materiais do Pântano e Vendedor.** APROVADA por Thiago em 31/10/2026; ver seção 5.
(a) `DROP_TABLE` para os tipos 8–11 reutilizando
Couro/Seda/Essência; Jacaré como "pool alto" do pity. (b) Material nomeado e troféu do Pântano.
(c) Vendedor só com Comum e Incomum; Raro+ por drop, chefe e pity. (d) Uma fonte rara de
Lendário (Guardião do andar, ~5%), para que armas altas continuem aprimoráveis. Saves: nenhuma
mudança de formato, e materiais já comprados continuam válidos. Fazer (c) sem (a)/(d) deixaria o
Pântano sem caminho de equipamento.

**B — Curva de recompensa.** Andar 2 `rewards` 1,1 → ~1,8, para o XP/HP do Vale passar o da Mata.
Missão comum multiplicada por `FloorCatalog.reward` do andar atual.

**C — Armas.** Opção 1: prêmio de dano no básico corpo a corpo (Espada ×1,15, Machado ×1,25,
Lança ×1,05). Opção 2: Arco/Cajado atiram com intervalo +30% enquanto o jogador se move. Validar
com o save nível 30 nos três monstros do Pântano.

**D — Evolução.** Opção 1: evoluir mantém +N e os marcos (igual às peças), custo atual. Opção 2:
manter o reset, mas a forja direta em raridade alta exige um item que só cai em drop. Peças:
raridade dá +10% dos atributos base por nível de raridade, ou a evolução fica bloqueada até isso
existir; aprimoramento das peças até +20 com as regras das armas.

**E — Aviso no contato** do Javali, Elite e Tatu (0,25 s de preparo, como a Aranha). Altera o
teste aprovado "boar contact respects damage and cooldown".

**F — Desafios.** Elite própria do Vale e do Pântano na horda 3 da Torre; Jacaré com ~900 HP
efetivo e drop garantido de material Raro.

## 5. Proposta A implementada (31/10/2026)

| Fonte | Ocorrência | Raridades |
|---|---:|---|
| Limo do Brejo → Essência | 40% | Comum 70% · Incomum 24% · Raro 6% |
| Sapo Venenoso → Seda | 40% | Comum 70% · Incomum 24% · Raro 6% |
| Vulto do Brejo → Couro | 40% | Comum 70% · Incomum 24% · Raro 6% |
| Jacaré Ancião → Couro **e** Essência | 100% cada | Incomum 52% · Raro 33% · Épico 10% · Lendário 4% · Místico 1% |
| Mãe dos Sussurros (3–5 materiais) | — | Incomum 60% · Raro 30% · Épico 5% · Lendário 5% |

- O Jacaré entra no "pool alto" do pity (garantia de Épico aos 60), como elites e chefes.
- Guardiões dos Andares 1 e 2 continuam exatamente como antes.
- Vendedor: compra só Comum e Incomum, mais o Selo de Proteção. A regra está no modelo
  (`GameProgress.buy`) e na lista da HUD. Vender continua aceitando qualquer raridade, e o
  material alto já guardado continua válido no save.
- A missão "Colete materiais" volta a valer no Pântano, porque agora há drops; a substituição
  por derrotas fica como proteção para andares sem fonte nenhuma.

**Desvios em relação ao texto da proposta, com motivo:**
1. A fonte recorrente de Lendário é o **Jacaré**, não só a Guardiã. A Mãe dos Sussurros só pode
   ser vencida uma vez por personagem; sozinha, daria Lendário a cerca de 20% dos jogadores, uma
   única vez. A Guardiã também ganhou os 5%, como a proposta pedia.
2. **Material nomeado e troféu do Pântano ficaram de fora.** Sem receitas do Pântano, eles só
   ocupariam espaço na mochila, e cada item nomeado precisa de ícone próprio (arte não improvisada).
   Entram junto com as receitas e peças do Pântano.

**Místico (aprovado por Thiago em 31/10/2026: "drop raro do Jacaré"):** cada material do
Jacaré tem 1% de chance de ser Místico (a fatia sai do Incomum, 53% → 52%). É a única fonte de
Místico no jogo.

Custo estimado, em vitórias sobre o Jacaré (valores provisórios para medir no save de teste):

| Meta | Materiais | Vitórias (média) |
|---|---|---:|
| Épico → Lendário | 5 Essência + 4 Couro Lendários | ~125 (limitado pela Essência, 4%) |
| Lendário → Místico | 6 Essência + 5 Couro Místicos | ~600 (1% por material) |
| Forjar arma Místico direto | 6 Essência + 7 Couro (corpo a corpo) | ~700 |
| Aprimorar uma arma Mística de +0 a +20 | 100 Essências Épicas, sem contar falhas | ~1.000 (ver abaixo) |

**Aprimoramento de Lendário e Místico (aprovado por Thiago em 31/10/2026: "Essência Épica"):**
armas Lendárias e Místicas são aprimoradas com Essência **Épica**, em maior quantidade: ×1,5
(arredondado para cima) no Lendário e ×2 no Místico. O ouro não muda. Até Épico, a receita
continua a original.

| Raridade da arma | Essência gasta de +0 a +20 (sem falhas) |
|---|---|
| Épico | 50 Épicas |
| Lendário | 80 Épicas (antes: 50 Lendárias) |
| Místico | 100 Épicas (antes: 50 Místicas, ~5.000 vitórias) |

O Jacaré dá Essência Épica em 10% das vitórias, então 100 Épicas são ~1.000 vitórias só com ele.
Elites, Guardiões e a garantia de Épico do pity também contam. O topo continua exigente, e é o
ponto para medir no save de teste.

## 6. Proposta B implementada (31/10/2026)

Aprovada por Thiago. A recompensa do Andar 2 passou de 1,1 para **2,0**, e não ~1,8: com a
mistura real de spawns do Vale (3 Tatus, 4 Escorpiões, 1 Goblin), 1,8 ainda ficaria abaixo da
Mata. Medido em `tests/revisao_jogabilidade_tests.gd`, em XP por ponto de vida dos inimigos
gerados:

| Andar | Antes | Agora |
|---|---:|---:|
| 1 Mata (com 1 elite a cada 8) | 0,268 | 0,268 |
| 2 Vale | ~0,15 | 0,277 |
| 3 Pântano | 0,164 | 0,164 |

- Valem 2,0 o ouro por abate (2–5 → 4–10) e o Guardião da Torre do Vale (360 XP e 80 ouro, antes 198 e 44).
- A missão comum multiplica XP e ouro pela recompensa do andar: Mata 40/12 e 30/10 (igual a
  antes), Vale 80/24 e 60/20, Pântano 104/31 e 78/26.
- A dificuldade do Vale continua 1,5. Testes de referência atualizados:
  `floor_catalog_tests` (GOLDEN_SCALE) e `boss_phase_tests`.

**Pântano (aprovado por Thiago em 31/10/2026):** o reforço ×1,8 de 29/10 subiu a vida dos
monstros sem subir a recompensa, e o Pântano rendia só 0,164 XP por HP. Aprovada a subida para
"cerca de 4,5". Implementação: o Pântano ganhou `reward_power: 1.8`, o mesmo reforço já aplicado
à vida e ao dano (`monster_power`), e a recompensa efetiva fica **2,6 × 1,8 = 4,68**. Mudar
`SCALE["3"]` direto para 4,5 deixaria o Andar 3 acima do Andar 4 planejado (3,5) e quebraria a
regra de escala sempre crescente (`boss_phase_tests`). Vida e dano dos monstros não mudaram.

| Andar | XP por HP agora (medido no teste) |
|---|---:|
| 1 Mata | 0,268 |
| 2 Vale | 0,277 |
| 3 Pântano | 0,297 |

- Ouro por abate no Pântano: 9–23 (antes 5–13). Jacaré: 562 XP (antes 312). Guardiã da Torre do
  Pântano: 842 XP e 187 ouro (antes 468 e 104).
- Missão comum no Pântano: 187/56 e 140/47.
- `FloorCatalog.reward_multiplier(id)` = escala × reforço próprio; `FloorConfig.configuration`
  passa a informar esse valor.
- A escala planejada dos Andares 4–10 continua como estava e crescente. Quando esses andares
  forem criados, decidir se recebem reforço próprio, como o Pântano.
