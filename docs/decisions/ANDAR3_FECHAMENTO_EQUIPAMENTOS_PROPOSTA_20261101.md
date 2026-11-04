# Andar 3 — fechamento de recompensas e equipamentos

Status: PARCIALMENTE IMPLEMENTADO — dados e regras aprovados; artes pendentes
Autor / data: Codex, 01/11/2026
Decisão vigente: O Pântano concede Couro, Seda e Essência por inimigo e pelo Jacaré, com probabilidades e raridades aprovadas em `REVISAO_JOGABILIDADE_20261031.md`. O terceiro conjunto foi integrado com os valores aprovados nesta conversa.

Problema original: `FloorCatalog.LOOT` não possuía troféu, material nomeado nem receitas do Andar 3; `RPGRules.EQUIPMENT` não possuía peças próprias. Esses dados agora estão integrados. O Andar 4 ainda não tem conteúdo próprio.

Decisão implementada:

1. Preservar integralmente os drops genéricos aprovados. Acrescentar os materiais já descritos no plano do Pântano: Fibra Encharcada (Limo), Vesícula Tóxica (Sapo), Limo Espesso (Vulto), Dente do Jacaré Ancião (mini-chefe), Coração do Brejo (Guardiã). Essência dos Sussurros fica reservada ao chefe. As artes não aprovadas aparecem como pendentes, sem ícones de outra categoria.
2. Um conjunto de sete peças próprio do Andar 3 e a Lâmina do Brejo, mantendo os oito slots atuais. Valores base aprovados, todos em raridade Comum na fabricação e sujeitos às seis raridades existentes:

| Peça | Slot | Vida | Ataque | Defesa | Velocidade | Outros atributos |
|---|---|---:|---:|---:|---:|---|
| Elmo do Brejo | Capacete | 27 | 0 | 3 | 0 | — |
| Manto das Raízes Mortas | Armadura | 31 | 0 | 3 | 0 | — |
| Luvas do Brejo | Luvas | 0 | 5 | 0 | 0 | Crítico +1,4% |
| Botas do Brejo | Botas | 0 | 0 | 3 | 10 | — |
| Anel do Brejo | Anel | 0 | 0 | 0 | 0 | Crítico +2,5%; dano crítico +7% |
| Colar do Brejo | Acessório | 21 | 0 | 0 | 0 | Resistência +1,4% |
| Amuleto do Brejo | Amuleto | 0 | 0 | 0 | 0 | Espírito +3; resistência +1,4% |

3. A Lâmina do Brejo foi aprovada como modelo próprio da categoria Espada, com +3 de Ataque base e 360 ouro de custo. Mantém alcance, cadência, habilidades e raridades da categoria; não acrescenta efeito elemental ou skill.
4. Kit visual 2 indicado para peitoral (`chest_02`) e capacete (`helmet_02`); os outros cinco sprites e a espada foram aprovados em 02/11/2026 e integrados conforme o mapeamento abaixo. A raridade altera apenas a borda, nunca recolore o sprite.

Impacto no Game Design, desempenho, compatibilidade e saves: novos IDs e materiais foram acrescentados à validação de save e ao Ferreiro; o Vendedor mantém as regras existentes. Nenhum atributo ou drop dos Andares 1 e 2 mudou. Os atributos e custos acima estão ativos no código local, ainda sem commit ou publicação.

Aprovação explícita do dono (01/11/2026): os sete atributos propostos; custo de 270 ouro por peça e 360 ouro para a Lâmina; 25% de material nomeado por inimigo e troféu garantido no chefe. O Dente do Jacaré e a Essência dos Sussurros também têm 25% de chance; Botas e Amuleto consomem uma unidade do respectivo material especial para limitar o farm. Essa exceção de quantidade ainda precisa de revisão em jogo.

Implementado nesta rodada: sete IDs do conjunto e receitas de raridade Comum, apenas a Lâmina do Brejo entre as armas, materiais nomeados, troféu e drops, coletas e baús nos quatro setores. `elmo_brejo` usa `helmet_02` e `manto_raizes_mortas` usa `chest_02`, conforme o Kit 2 já definido. Não houve mudança de gameplay nos Andares 1 e 2 nem de formato do save. O validador agora admite as 32 receitas possíveis dos três andares. A Lâmina preserva alcance, cadência e habilidades da espada, com o bônus próprio de +3 de Ataque aprovado nesta conversa.

Associação visual aprovada pelo dono em 02/11/2026: `lamina_brejo` → `sword_02`, `luvas_brejo` → `gloves_02`, `botas_brejo` → `boots_02`, `anel_brejo` → `ring_05`, `colar_brejo` → `necklace_04`, `amuleto_brejo` → `necklace_01`. Elmo e peitoral mantêm `helmet_02` e `chest_02`. Os sprites originais não recebem recoloração por raridade; só a borda do slot muda.

Pendente para fechamento visual: artes próprias dos seis novos materiais/troféus. Até lá, a interface indica arte pendente para esses materiais. Revisar em sessão real no celular a duração do farm, a posição das coletas e o feedback de abertura dos baús.

Plano de validação e rollback: testes dirigidos para fabricação, raridade, mochila/Baú, drop/pity, carga de saves antigos e novos; execução real do fluxo Andar 2 → 3 → Torre em 360×800. Reverter apenas os novos IDs e migração se houver falha, preservando os dois primeiros andares.
