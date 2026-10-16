# ARVÉON — Espada: Guarda Reativa, Estocada Precisa e Kamusari

Status: APROVADO pelo proprietário em 15/10/2026. A aprovação foi dada
às três referências visuais, seguida de "Vamos implementar".

## Escopo e integração

- Godot 4.5.1, Compatibility, Andar 1, controles mobile/desktop.
- Guarda Reativa: pose curta da Espada, anel protetor azul durante a guarda,
  faíscas ao receber ataque protegido. A redução de dano e a duração
  continuam calculadas por ClassCombat/AbilityRules, não pelo efeito.
- Estocada Precisa: poses da Espada e trilha azul avançando em linha reta.
  Permanece técnica de proficiência 25, alcance 155px, semi-largura 22px,
  multiplicador 1,8x e recarga de 10s.
- Kamusari: nome visível da Ultimate na UI, árvore e catálogo. Uma onda
  vermelha frontal atravessa visualmente o cenário, alcance 320px,
  cone com dot >= 0,48, uma resolução de dano de 3,4x (provisório).
  Substitui o disco de quatro golpes da antiga Dança das Lâminas,
  com potência total nominal semelhante antes de armadura/críticos.
- A animação corporal V1 reaproveita o atlas da Espada aprovado, com
  quadros distintos por momento e direção. Efeitos são desenhados por
  um único nó que se reutiliza: não há spritesheet extra, física ou
  colisão adicionais. A arte de referência é direção visual, não
  um spritesheet de execução com fundo transparente.
- O dano real ocorre no momento da ativação por ClassCombat;
  as ondas desenhadas após a ativação não causam novos impactos.
  Qualquer futura sincronização temporal exige escopo separado.

## Compatibilidade e limitações

- **ID da Kamusari permanece `danca_laminas`** para não quebrar saves v11,
  seleção de slots, cobrança de carga ou testes e builds em andamento.
- Proficiência exigida 15, carga 100, intervalo entre categorias 10s,
  Maestria Suprema +20% no 60 e exclusão de autocarregamento permanecem.
- Nenhuma alteração em main, Andar 2, equipagem, HUD, assets das outras
  categorias, autoloads, custos, economia ou versões dos saves.
- VFX não define hitboxes. Aparência requer inspeção em dispositivo real
  antes de qualquer declaração de qualidade final de animação.
- Trabalho isolado em `feat/espada-guarda-estocada-kamusari-20261015`
  baseado em `17c1041`; a branch em paralelo `feat/progressao-etapa2`
  não é alterada antes de revisão/integração.
- QA: Godot headless/import, suites em `tests/run_tests.gd`,
  integração real de combate, export Web e visual mobile antes de
  colocar no TESTE fixo.
