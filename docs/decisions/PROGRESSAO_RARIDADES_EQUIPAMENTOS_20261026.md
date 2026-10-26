# Progressão de raridade de equipamentos

**Status:** aprovada por Thiago em 26/10/2026
**Base de implementação:** `dev/sistemas-andares-dados` em `0b1e116`

## Decisão

Todos os equipamentos seguem a ordem `comum → incomum → raro → épico → lendário → místico`.
Equipamentos novos de conjunto e armas comuns fabricadas começam em Comum. A raridade
de uma peça é independente do andar em que o item foi introduzido; ela evolui nas
regiões onde a receita daquele item pode ser fabricada, pagando a receita de evolução
existente.

A raridade é mostrada pela borda do slot. O sprite do equipamento não é recolorido.
A borda Mística é vermelha (`#e53935`).

As armas comuns podem usar os seis níveis. Armas especiais de topo, seus sprites e
skills ficam para uma definição posterior do proprietário; quando criadas, serão
apenas Lendárias ou Místicas. Esta decisão não cria esses modelos nem skills.

## Preservação

- IDs, nomes, atributos, receitas-base, drops, pity, receitas desbloqueadas e bônus existentes permanecem.
- Saves anteriores continuam válidos e preservam a raridade estática que já tinham.
- Saves novos persistem a raridade individual das peças de conjunto.
- A raridade das peças não multiplica atributos nesta etapa; isso evita inventar balanceamento.
- A interface de Equipamento não é conectada nem alterada nesta decisão.

## Implementação

As receitas de raridade reaproveitam `EquipmentEconomy.rarity_recipe`; a evolução de
peças usa os mesmos custos progressivos já usados por armas. Os custos e as fórmulas
não são alterados. A versão do save passa a 13 para persistir as raridades individuais.

Esta decisão complementa e substitui apenas as regras de raridade incompatíveis de
`EQUIPAMENTOS_INSTANCIAS_V12.md`; as demais decisões desse documento permanecem.
