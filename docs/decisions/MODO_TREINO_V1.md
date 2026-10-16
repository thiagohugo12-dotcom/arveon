# Modo Treino V1 — implementação aprovada (15/10/2026)

Autorização: "consegue fazer um modo treino com tudo liberado dentro do jogo?"

## Entrada
Diário do Explorador → Personagem → **Modo Treino · tudo liberado**.
A campanha é salva e fechada antes da transição para `training.tscn`.
Não entrar durante uma tentativa de Torre em andamento.

## Contratos

- Cena própria `scenes/training.tscn`, que herda os nós existentes
  de `scenes/main.tscn` (personagem, HUD e cenário), mas usa uma
  implementação de lifecycle separada de `Main` sem load_save().
- Ao entrar, criar `GameProgress` totalmente novo em memória, com
  `save_blocked = true`. Nenhum arquivo, browser journal, autosave,
  export/import, item, XP ou moeda da campanha é acessado no treino.
- Personagem nível 100, proficiências 60 de todas as armas, armas +3,
  talentos, grau máximo das técnicas e Maestrias desbloqueadas.
  A seleção atual equipável continua com duas técnicas (Ultimate
  opcional) e duas passivas; o catálogo inteiro está liberado
  para trocar pelo menu, mais duas especializações por categoria.
- Botão **TREINO** durante o combate abre o seletor para escolher
  qualquer uma das cinco categorias, técnicas, passivas e estilo.
- O sistema de combate é o mesmo do jogo: alcance, dano, IA de
  projéteis, animações, colisões e gatilhos existentes.
- Alvos imóveis, com HP elevado e sem ataques. Os projéteis,
  HUD touch, auto-attack, Skill 1, Skill 2, Skill 3 e dash
  continuam conectados.
- Recarga de habilidades, carga das Ultimates e intervalo global
  de Ultimates são zerados/preenchidos a cada atualização do treino.
  Não alteram `AbilityRules` ou os cooldowns da campanha.
- **Sair do treino** abre novamente `scenes/main.tscn`, que carrega o
  save normal independentemente. Nenhum prêmio/carga/XP é transferido.

## Segurança / QA

- Branch exclusiva `feat/modo-treino-livre-20261015` parte da
  PR de Espada/Kamusari, para que possa testar as animações em
  conjunto sem mudar a branch compartilhada.
- Não publicar em PRODUÇÃO. Validar por Godot 4.5.1 headless,
  testes de regras e save, export Web, controle/touch e captura
  de telas antes de colocar no TESTE fixo.
- A arena reutiliza o cenário da Mata (não cria um novo andar).
- Os três alvos são criaturas estáticas da cena real; futura
  troca por bonecos de treino pode ser feita sem mudar combate.
