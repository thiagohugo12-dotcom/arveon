# ARVÉON — Árvore da Espada (primeiro passe jogável)

Implementação na branch \`feat/progressao-etapa2\`, sem modificar \`main\`.

## Direção de interface aprovada

- Diário do Explorador existente: pergaminho, moldura de madeira, tinta escura, verde-floresta e pixel art.
- A aba **Proficiências → Árvore** abre a árvore da Espada em duas colunas, com rolagem responsiva.
- Qualquer marco é clicável para ler requisitos; apenas ações válidas podem ser confirmadas.
- Técnicas e passivas são equipadas nos **mesmos dois slots configuráveis** e nos **dois slots de passiva** já existentes; não há botões novos no HUD.
- Compras, melhoria de grau, especializações e respec continuam restritos à área segura.

## Regras deste passe

- Proficiência de categoria: **1 a 60**; o nível geral do personagem permanece **1 a 100**.
- Taxa atual de XP: 1 ponto de proficiência por 10 HP efetivos de dano, acumulando frações.
- Até o nível 30: habilidades, especializações, quatro talentos originais e Maestria Lâmina Perfeita preservados.
- Proficiência **35**: passiva equipável Instinto Veterano (+6 p.p. crítico).
- Proficiência **40**: técnica equipável Ruptura Ancestral (golpe em linha de 205px, 40px de largura, 2,25x dano base e recarga 14s).
- Proficiência **45**: talento Ritmo Afiado (+8% dano básico após três ataques básicos; exige Sequência Precisa).
- Proficiência **50**: passiva equipável Vontade Ancestral (-10% dano recebido abaixo de 50% HP).
- Proficiência **55**: talento Bastião Ancestral (-8% dano recebido com guarda ativa; exige Postura Equilibrada).
- Proficiência **60**: Maestria Suprema Ascensão da Lâmina (+20% dano da Ultimate da Espada, automático).
- Todos os níveis continuam fornecendo bônus automático de eficiência (+0,5% por nível acima do 1).

## Compatibilidade / limites conhecidos

- O save permanece na versão **11**, pois os mesmos campos aceitam a nova faixa de XP; saves nível 30 não perdem seus investimentos.
- As cinco categorias reconhecem limite 60; o catálogo de desbloqueios **após 30 foi expandido somente para Espada**, conforme o escopo aprovado.
- **Pontos gerais** ainda financiam talentos e graus, e **Treinamento da Arma** ainda financia os quatro atributos do antigo Domínio. A unificação de moedas deve ser tratada em migração posterior, não alterada silenciosamente neste passe.
- Os quatro atributos de Treinamento mantêm seus limites anteriores; acima da proficiência 45 podem restar pontos não alocáveis. Corrigir durante redesenho final dos pontos exclusivos de arma.
- O ataque especial visual estilo Kamusari ainda não foi produzido; a Maestria Suprema usa a Ultimate jogável atual, sem fingir ter uma nova animação.
- O mapa, os controles mobile, slots existentes e a localização do armazenamento Web não mudaram.

## Aceitação

Rodar \`godot --headless --path . --editor --import\`, \`godot --headless --path . --script res://tests/run_tests.gd\`, cenas de captura mobile e pipeline Web existente. Publicar **apenas TESTE** após CI verde.
