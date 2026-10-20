# Andar 2 — integração local dos três monstros

Status: **APROVADA** em 19/10/2026 pelo pedido “implemente no jogo local”,
após aprovação das animações de Goblin Garimpeiro, Tatu Rochoso e Escorpião da
Chapada. As imagens 2, 3 e 4 fornecidas por Thiago são as referências visuais
oficiais respectivas. A imagem 1 mostrava um golem e não foi usada para eles.

## Implementação

- O Vale usa uma cena de inimigo com a mesma lógica e colisão existente, com
  `Floor2MonsterView` para mostrar os spritesheets aprovados.
- Goblin: Pedreira Dourada (tipo 5); Tatu: campos (tipo 6); Escorpião: ruínas,
  perigo e entorno (tipo 7). Os pontos existentes continuam configuráveis em
  `Floor2Layout`.
- O ciclo real mostra repouso, caminhada, ataque, dano, morte e a investida do
  Tatu. Animações não aplicam dano adicional. Até cinco inimigos permanecem
  ativos pela regra existente.
- Combate, vida, XP, ouro, seleção de alvo, minimapa e viagem usam o fluxo
  atual. O Andar 1 e a Torre continuam usando sua própria cena e seus tipos.

## Balanceamento provisório antes do multiplicador do andar

| Monstro | HP | Velocidade | Dano de contato | XP base |
|---|---:|---:|---:|---:|
| Goblin Garimpeiro | 42 | 95 | 6 | 10 |
| Tatu Rochoso | 95 | 54 | 9 | 16 |
| Escorpião da Chapada | 62 | 105 | 11 | 20 |

Os três reutilizam temporariamente aproximação, recuo lateral ou investida do
componente de IA existente. Arremesso do Goblin, veneno do Escorpião e materiais
exclusivos planejados ainda precisam de regras e balanceamento próprios.
Não foram adicionados drops exclusivos sem essa definição. A mineração segue
como fonte de Minério de Ferro.

## Validação local

- Godot 4.5.1 importou e compilou as cenas e scripts.
- `tests/floor2_monster_game_tests.gd`: 0 falhas em viagem, criação real na
  Pedreira, estados visuais, dano, derrota, XP e retorno ao Andar 1.
- `tests/andar2_integration.gd`: 0 falhas em circulação, coleta, baús,
  minimapa, câmera, save e viagem entre andares.
- `tests/mining_integration.gd`: 0 falhas; os quatro depósitos continuam
  mineráveis, inclusive o depósito vizinho ao baú.
- Capturas reais do jogo em `../Registros/andar2-monstros-jogo/`, incluindo
  enquadramento vertical de celular.

Durante a validação, o baú da Pedreira revelou uma sobreposição de raios com
um depósito. A interação agora escolhe o objeto fisicamente mais próximo,
permitindo abrir o baú e minerar a mesma área sem bloqueio mútuo.
