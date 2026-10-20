# Andar 2 — mineração funcional

Status: APROVADO E IMPLEMENTADO LOCALMENTE em 19/10/2026.

Aprovação: pedido explícito de Thiago para implementar o sistema de mineração
nos quatro depósitos já posicionados na Pedreira Dourada, com dois sorteios,
inventário, Ferreiro, baú, persistência e treino. Esta decisão substitui a
restrição anterior que mantinha os depósitos apenas visuais.

## Regras provisórias

| Parâmetro | Valor |
|---|---:|
| Chance-base de minério por tentativa | 75% |
| Comum, condicional ao drop | 90% |
| Raro, condicional ao drop | 10% |
| Sem minério, chance absoluta | 25% |
| Comum, chance absoluta | 67,5% |
| Raro, chance absoluta | 7,5% |
| Tentativas por depósito | 3 |
| Reaparecimento após esgotar | 300 s |
| Duração de uma extração | 0,48 s |
| Alcance de interação | 76 unidades |

Uma tentativa sem drop consome uma carga. A aparência da rocha não indica a
raridade. Os quatro IDs são `vale_ferro_1` a `vale_ferro_4`; posições e artes
coincidem com `Floor2Layout.DEPOSITS` e `Floor2Layout.OBJECTS`.

As duas receitas de teste do Ferreiro produzem uma cópia da espada comum ou
rara. Cada uma consome duas unidades de Minério de Ferro da mesma raridade,
uma Madeira e, respectivamente, 15 ou 45 de ouro. As receitas anteriores não
mudaram. Esta arma usa o modelo já existente de espada; arte e nome próprios
ficam para uma eventual decisão futura.

O estado `floor_states[andar].mining[id]` persiste as cargas restantes e o
instante Unix de reativação. Saves anteriores sem `mining` recebem estado
inicial, sem alterar as demais informações. Treinamento usa `TrainingMode` e
não grava suas alterações no registro normal.

Validação local: `tests/mining_integration.gd` cobre os quatro depósitos,
botão, sorteios, cargas, esgotamento, tempo, independência, viagem, save,
mochila, baú, Ferreiro, toques repetidos, transição e treino. A suíte completa
de regressão passou com 2.594 verificações e zero falhas. Capturas reais em
`outputs/capturas-mineracao-andar2/` fora do projeto Godot. O teste foi feito
no desktop e com viewport vertical; teste em aparelho físico ainda pendente.
