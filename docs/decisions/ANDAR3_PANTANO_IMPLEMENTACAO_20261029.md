# Andar 3 — Pântano das Vozes · implementação local jogável

**Status:** implementado localmente (sem commit, push, merge ou deploy) a pedido de Thiago em 29/10/2026.
**Base:** pacote `ARVEON_Andar3_Pacote_Completo_Mapa_Monstros_Animacoes.zip` (manifesto 1.0, hashes conferidos).
**Balanceamento:** PROVISÓRIO — valores abaixo servem para jogar e calibrar; não são finais.

## Artes

- Originais aprovados preservados, sem alteração, em `art_source/andar3/` (pasta ignorada pela Godot e fora do export).
  O histórico (`05_HISTORICO_NAO_IMPLEMENTAR`) não foi copiado nem usado.
- Derivados gerados por ferramenta reprodutível:
  - `tools/build_andar3_terrain.gd` → `assets/art/andar3/derived/pantano_mask.png` (+ versão suavizada): regiões de água,
    terra e trilha lidas do mapa aprovado. A madeira das pontes do mapa conta como água (a ponte é peça própria).
  - `tools/build_andar3_assets.gd` → `assets/art/andar3/{props,monsters,terrain}`: 112 peças de cenário, 6 monstros,
    5 amostras de textura e as duas folhas do Limo. Cada peça é recortada pelos próprios pixels (sem grade fixa),
    perde o halo verde de geração, mantém transparência real e é reduzida com Lanczos para a escala do mundo,
    com alfa nítido para filtro "nearest".
  - Limo do Brejo: os 4 quadros de respiração e os 6 de ataque mantêm a ordem original; cada quadro é alinhado pela
    base do corpo e pelo centro do domo (a parte que não se move), com escala única por folha.
  - `tools/andar3_components.gd`: inspeção das peças de cada folha (imagem numerada).

## Mapa

- Escala: 1 px do mapa aprovado = 1,5 px do mundo → mundo de 2172 × 1626.
- O mapa NÃO é imagem de fundo: o chão é composto em tempo real (`assets/shaders/pantano_ground.gdshader`) com a máscara
  e as amostras do tileset aprovado (grama, terra, água e barranco). Pontes, ruínas, acampamento, santuários, árvores,
  arbustos, juncos e lírios são Sprite2D separados, ordenados pela base; as copas ficam translúcidas quando o jogador
  passa atrás.
- 13 pontes medidas sobre a água real (tabuleiro de 66 px); 5 anotações de ponte do mapa caíram em terra firme ou em
  água sem margem oposta e foram descartadas automaticamente.
- Colisão: água funda (retângulos da máscara, pontes abertas), troncos de árvore, ruínas e peças do acampamento.

## Inimigos (valores base; o andar aplica dificuldade 2,1 e recompensa 2,6)

| Tipo | Kind | Vida base → efetiva | Velocidade | Dano base → efetivo | XP base |
|---|---|---|---|---|---|
| Limo do Brejo (tanque) | 8 | 125 → 263 | 42 | 13 → 27 (+ mancha 7/0,8 s) | 22 |
| Sapo Venenoso (alcance) | 9 | 66 → 139 | 74 | projétil 9 → 19 | 20 |
| Vulto do Brejo (rápido) | 10 | 78 → 164 | 128 | 14 → 29 | 24 |
| Jacaré Ancião (mini-chefe) | 11 | 380 → 798 | 58 | 18 → 38 (mordida ×1,0, investida ×1,25, cauda ×0,9) | 120 |
| Mãe dos Sussurros (Guardiã) | 4 | 400 → 840 | 34 | rajada 31, manchas 13/0,8 s, onda 42, raízes 38 | — |
| Mãe dos Sussurros (Torre) | 4 | 381 → 800 | 50 | golpes da Torre existente | — |

Referência do Andar 2 (efetivo): Goblin 78/12, Tatu 162/17, Escorpião 108/20, Colosso 810.

## Comportamentos

- Limo: anda devagar, ataca a até 74 px; o golpe é decidido pelo ator, a animação de 6 quadros toca e o dano sai uma
  única vez no 4º quadro (impacto), num alcance de 50 px à frente; deixa uma mancha de lodo de 2,6 s que fere só depois
  do primeiro intervalo. Não reinicia o golpe durante a animação; volta para a respiração ao fim.
- Sapo: mantém 130–210 px, cospe veneno (aviso de 0,45 s), salta para trás quando o jogador encosta e se reposiciona.
- Vulto: aproxima rápido, aviso de 0,3 s, golpe, recuo e volta circulando.
- Jacaré: arena própria no Bosque Afundado; avisos no chão (cone, faixa, círculo); abaixo de 40% os avisos ficam 30%
  mais curtos e ele acelera; reaparece 120 s depois de derrotado, só com o jogador longe.
- Mãe dos Sussurros: Guardiã de campo no santuário lunar (mesma arquitetura RootGuardian + BossPhases, com limiar de
  fase próprio em 50%). Fase 1 (Névoa Viva): Rajada de Lodo, Manchas do Brejo e onda. Fase 2 (Vozes do Fundo): troca
  para a arte da fase 2 com aviso simples, Raízes emergentes em fileira, rajada mais larga, mais manchas e menos pausa.
- Torre do Andar 3: ondas com Limo, Sapo e Vulto; a Guardiã da Torre usa a mecânica existente com a arte da Mãe.

## Fora desta etapa

Animações novas (Sapo, Vulto, Jacaré, Mãe), versão Desperta, drops/receitas/coletas próprios do Pântano, sistema
elemental, Andar 4. A Torre do Andar 3 concede a ascensão pela regra existente, mas o Andar 4 ainda não existe.
