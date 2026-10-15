## Interface da Espada — aprovada em 15/10/2026
Conforme INTERFACE_ESPADA_DIARIO.md e pedido “Vamos colocar a nova interface”:
aplicar pergaminho, ícones e conexões da referência 77175.png ao primeiro passe
da Espada já existente, preservando seus marcos até 60 e regras atuais.
Toque mostra requisitos/ações; rolagem e retorno ao nó funcionam no celular.
Somente TESTE; sem novos efeitos, custos, moedas ou migração de save v11.

## Skills 1 V2 - integracao aprovada em 14/10/2026
Thiago aprovou o preview 55617e3 com "pronto, gostei" e "pode integrar".
Escolheu explicitamente "Preparacao completa antes do impacto": startup de
0.24-0.36s conforme arma, seguido de uma unica execucao original. Caminhada
permitida; dano, alcance, cooldown e projeteis mantidos. Publicar somente no
TESTE fixo apos validacao. Basicos, Skills 2/3, Ultimates e save v11 preservados.

## Skills 1 - atuacao corporal V2 autorizada
Pedido do usuario: movimentos reais de corpo, apoio, antecipacao e recuperacao
conforme referencia das cinco armas. Preview isolado, sem alterar combate ou
basicos. Conforme docs/decisions/SKILLS1_V1.md; avaliacao visual pendente.

# Game Design — fundação v0.1
## Skills 1 V1 - autorizadas em 14/10/2026
Conforme SKILLS1_V1.md: cinco etapas independentes com commit/testes,
animacoes exclusivas de Skill 1 e um preview isolado. Preservar os cinco
basicos, ClassCombat/AbilityRules, progressao, Skill 2/3 e Ultimates.
Nao publicar no TESTE fixo antes da aprovacao visual.

## Machado e Lanca V1 - integracao aprovada em 14/10/2026
Thiago aprovou as demonstracoes com "implemente". Integrar os mesmos sprites
no ataque basico do jogo e publicar somente no TESTE apos os testes.
Preservar Espada, Arco, Cajado, caminhada, Skills, regras e save v11.

## Machado e Lanca V1 - desenvolvimento autorizado em 14/10/2026
Thiago autorizou as duas armas restantes. Conforme ANIMACAO_MACHADO_LANCA_V1.md,
criar demonstracoes isoladas com golpe amplo/estocada, preservando regras,
explorador e armas aprovadas. Integracao apos avaliacao visual.

## Cajado V1 - integracao aprovada em 14/10/2026
Thiago aprovou visualmente com "coloque no jogo". Integrar o atlas existente
ao ataque basico do Andar 1 e publicar somente no TESTE apos validacao.
Preservar Espada, Arco, caminhada, Skills, regras e save v11.

## Cajado V1 — demonstração autorizada em 14/10/2026
Conforme ANIMACAO_CAJADO_V1.md: criar apenas apresentação do básico do Místico
em preview isolado, com braços curtos, canalização e orbe verde-azulado.
Preservar espada, arco, caminhada, regras e save v11. TESTE fixo/produção
permanecem na versão aprovada. Integração depende de aprovação visual.

## Arco V1 — integração autorizada em 14/10/2026
Conforme ANIMACAO_ARCO_V1.md: encurtar braços nas quatro direções do atlas
existente e integrar o básico no Andar 1. Publicar somente no TESTE fixo após
validação. Preservar espada, caminhada, regras, atributos, Skills e save v11.
Machado/Lança/Cajado aguardam aprovação; produção fora do escopo.

## Espada V1 — integração aprovada em 13/10/2026
Conforme ANIMACAO_ESPADA_V1.md e “aprovado, pode colocar” de Thiago:
aplicar o ataque de espada aprovado ao explorador do Andar 1 e ao TESTE fixo,
preservando caminhada, regras, feedback, outras armas e saves v11.
Demonstração comparativa mantida; produção e outras animações fora do escopo.

## Primeira arma — aprovada em 13/10/2026
Conforme PRIMEIRA_ARMA.md e pedido completo de Thiago: novos personagens
começam desarmados e seguem O Primeiro Passo até o Ferreiro. Uma das cinco
armas iniciais é escolhida gratuitamente, equipada e salva uma única vez.
Sem XP/ouro adicionais. Outras armas continuam fabricáveis; personagens
existentes ficam isentos. Save v11 preserva v1–10 e seus dados.

## Progressão — Etapa 1, aprovada em 12/10/2026
Conforme PROGRESSAO_ETAPA1.md e pedido completo de Thiago: seis atributos,
classes por categoria equipada, proficiência 1–30 por dano efetivo, domínio
independente e migração dos investimentos antigos. Substitui Agilidade e o
bônus genérico de Espírito. Nível geral continua 1–100 e concede 2 atributos
e 1 ponto compartilhado entre talentos/habilidades. Preservar efeitos/nós
atuais; três skills + Dash, poção separada. Valores são provisórios; futuras
especializações, skills equipáveis e duas passivas aguardam detalhamento.

## Diário e HUD — aprovação em 11/10/2026
Conforme DIARIO_HUD_V1.md, adotar diário creme/madeira/verde, mochila em grade
e menus responsivos. Direção atual: dash + habilidade da arma + duas técnicas
escolhidas (quatro botões), poção separada e ataque básico automático da arma.
Supera a exigência anterior de Ultimate separada. A atualização de 12/10
implementa proficiências e árvores conforme TALENTOS_DIARIO_V2.md; a seleção
livre ainda é futura. As três técnicas atuais e seus graus são preservados.

## Hub V3 — reconstrução aprovada em 11/10/2026
ATORES_VILA_V4.md autoriza substituir as artes de personagens, monstros e
coletas no Andar 1 por sprites simples e animados. A aprovação supera a
preservação anterior das artes dos monstros, mantendo suas regras e física.
Polimento adicional autorizado conforme HUB_V3_POLIMENTO.md. A versão
544ddae fica preservada na tag baseline-hub-v3-aprovado-2026-10-11.
Conforme HUB_RECONSTRUCAO_V3.md e pedido “faça então”: redistribuir a vila do
Andar 1, substituir suas artes e ajustar NPCs/interações às posições visíveis.
Pequenas bases de construções podem bloquear movimento, mantendo vias abertas.
A autorização substitui a composição fixa anterior apenas no Andar 1.
Proteção, respawn, monstros aprovados, combate, saves e Andares 2–5 preservados.

Fonte de verdade das decisões conhecidas, baseada no pedido de 07/10/2026. Nome provisório: grande-arvore-rpg.

## v0.5.0 — entrada da Torre, aprovada em 10/10/2026
Conforme `docs/decisions/TORRE_V050.md`: 50 derrotas reais de criaturas do
Andar 1 liberam a entrada. Progresso persistente e limitado a 50, preservado
na morte. A interface apresenta a prova futura de três hordas e Guardião da
Mata, com reinício na primeira horda após morrer. Nesta etapa não há prova
jogável, arena, novo chefe, Andar 2, seleção de andares ou teletransporte.

## Decisões confirmadas e protegidas
- Godot 4.x, GDScript, 2D, Compatibility, mobile-first, Windows e Web.
- UI responsiva; orientação livre; foco em celulares modestos.
- Primeiro vertical slice: **Andar 1 — Mata dos Primeiros Passos**. Não implementar Andar 2.
- Movimentação normalizada em 8 direções no teclado e joystick touch analógico.
- Ataque básico automático seleciona inimigo vivo, válido e dentro do alcance da arma.
- Dash fica no lado DIREITO da HUD, segue movimento atual ou última direção quando parado.
- HUD reserva Skill 1, Skill 2, Ultimate e poção, sem inventar seus efeitos.
- HP, um inimigo provisório e colisões básicas. Assets provisórios substituíveis sem reescrever gameplay.
- Git é a fonte oficial. Checkpoints funcionais são preservados.

## Regras provisórias deste protótipo
Valores ajustáveis em `data/`: jogador 100 HP, velocidade 180 px/s; arma 120 px, 12 dano, intervalo 0,65 s; inimigo 48 HP, velocidade 70 px/s, contato 8 dano/1 s.
Dash: 0,14 s a 620 px/s, cooldown 1,2 s; mantém colisões, não concede invulnerabilidade. Ataque escolhe o alvo mais próximo com linha de visão desobstruída por World. Empates mantêm o primeiro do grupo. Inimigo persegue até 480 px, para a 28 px e ataca até 36 px. Sem pathfinding nesta etapa.
Morte do jogador para movimento/ataques e exibe reiniciar. Morte do inimigo remove o provisório; não há drops ou respawn automático. Reiniciar recarrega o slice. São escolhas técnicas de teste, não definição da economia ou progressão final.

## Não implementado no protótipo técnico (ainda que alguns itens já estejam decididos no produto)
Conteúdo completo, skills, economia, inventário, progressão permanente, multiplayer/backend, chefes, arte final, tamanho e orientação definitiva. Decisões aprovadas estão registradas abaixo; implementação não deve inferir que tudo já existe.

## Alterações estruturais
Agentes sugerem via ADR em `docs/decisions/`. O dono aprova; Director registra e atualiza este documento. Sem aprovação, contrato vigente permanece.


## Decisões de produto aprovadas em conversa (não confundir com sistemas implementados)
Estas regras são a direção do jogo completo. O protótipo técnico atual não as implementa integralmente.

- Mundo: a Grande Árvore conecta domínios/andares compactos inspirados em paisagens, culturas e folclore do Brasil; folclore não implica vilania. O topo permanece misterioso. Guardiões podem retornar ou ajudar após serem superados.
- Lore: apenas resumos curtos durante gameplay; histórias completas e fragmentos opcionais no Códice/Lendas. Sem cutscene de desbloqueio: mostrar mensagem simples.
- Andar 1: Mata dos Primeiros Passos, com área segura pequena (vendedor, ferreiro, baú), trilha, mata e Guardião original de raízes; desafio direto, sem pré-requisito de nível. O segundo andar somente após o primeiro estar polido.
- Andares especiais são raros e espaçados, por exemplo primeiro no 5, depois próximo no 12, sem padrão matemático obrigatório. Exigem eventualmente item, ritual, puzzle, exploração ou caçada; outros mistérios são opcionais.
- Sem classes fixas: personagem usa Espada, Lança, Arco, Machado ou Cajado; cada categoria tem proficiência própria persistente. Teto inicial proposto 30, marcos 3/5/8/10/12/15/18/20/25/30 conforme planejamento.
- Combate: básico automático, alvo próximo válido, toque para fixar alvo futuramente; Dash direito com direção atual ou última direção, breve invulnerabilidade é desejo para versão futura e ainda não existe no protótipo. Dois slots de skills de proficiência, uma Ultimate, até uma skill da própria arma, duas passivas. Ultimate acumula lutando.
- Evolução: nível geral mais proficiência de categoria, ambos podem restringir equipamento. HP, ataque, defesa e crítico são principais, valores crescem automaticamente por nível; build via arma, itens, proficiência e passivas. Sem stamina para correr.
- Raridades: comum, incomum, raro, épico, lendário e mítico. Drops/ferreiro são fontes de equipamento; itens de chance ~1% podem ser especiais, não obrigatórios para avançar.
- Missão comum gratuita sempre ativa, recompensa automática e substituição imediata; contrato de caçada opcional comprado com ouro do jogo, com possível compra recorrente.
- Morte em qualquer lugar, inclusive Guardiões: retorno à área segura, perda de 1 item não equipado da mochila mais algum XP e ouro; equipado e itens guardados no baú protegidos. Percentuais e compartilhamento de baús pendentes.
- HUD mobile: joystick à esquerda, Dash/2 skills/Ultimate/poção à direita; ataque básico não precisa de botão. Orientação e viewport responsivos.
- A próxima v0.2 é uma iteração experimental com sprites procedurais, animações leves, vários inimigos e feedback XP/ouro sem inventário ou persistência. Não afirmar que representa o visual definitivo.

## Área Segura v0.2.1 — regra aprovada em 2026-10-08
Conforme `docs/decisions/AREA_SEGURA_V021.md`, o acampamento central contém baú,
ferreiro e vendedor. Mochila e baú guardam os materiais já existentes sem limite
experimental. Ouro, XP, missão e materiais são salvos localmente no navegador.
Vendedor compra/vende Couro, Seda e Essência por 5/2 ouro, valores provisórios;
Broto Ancestral não é comercializado. O ferreiro apresenta o equipamento inicial,
sem melhoria funcional ou receita inventada. Morte retorna à área segura após
reinício e remove uma unidade de material da mochila, se houver; baú é protegido.
XP e ouro não são penalizados até aprovação de percentuais. Inimigos e espinhos
não atravessam o limite seguro. Este recorte não define capacidade final,
progressão de equipamento, sincronização de saves nem economia definitiva.

## Pendências reais de design
Percentuais de morte, capacidade de inventário e baú, valores de balanceamento, espécies/receitas definitivas, identidade de arte final e escolha de orientação. Número total de andares e nome definitivo não estão fixados.

## Exploração e interface v0.2.4 — aprovada em 2026-10-08
O Andar 1 mantém o acampamento, oito pontos de coleta e três baús escondidos.
Mochila acessível por toque mostra ouro e materiais e pausa movimento/ataque.
O piso provisório recebe trilhas ramificadas, clareiras e vegetação sem colisões
novas. Minimapa leve acompanha o jogador, revela pontos de coleta por visita
e só mostra baús escondidos depois de abertos. Descobertas integram o save
local existente, sem sincronização de contas ou mapa de outros andares.


## v0.3.0 — pedido aprovado em 08/10/2026
Thiago autorizou atributos distribuíveis, equipamentos e Ferreiro até +3,
Corte Circular, Investida, Fúria Ancestral, elite, chefe opcional e missões do
Andar 1. A curva dos commits b14b641/8de85fc é preservada: nível 1–100,
XP acumulado (n−1)×n×25, dois pontos de atributos por nível.
Força +2 dano; Vitalidade +8 HP; Espírito +1 dano e +2 HP; Agilidade
+2 movimento, +3 dash e até 25% de redução do intervalo básico.
Receitas e valores novos são provisórios. Save v5 migra v1–4 e preserva
os atributos de v4. Sem Andar 2 ou mudanças em produção.

## v0.5.1 — hordas da Torre, aprovada em 10/10/2026
Conforme `docs/decisions/TORRE_V051.md`, após o requisito existente, Entrar na
Prova leva a uma arena separada com três hordas (4 comuns; 6 comuns; 5 comuns
+ 1 elite). Só derrotas reais avançam. Entre hordas: recuperação única de 15%
do HP máximo e quatro segundos de preparação com movimento. Morte perde o
material normal uma vez e volta ao acampamento; abandono não penaliza. Sem
checkpoints: carregar retorna à Mata; tentativa reinicia na primeira horda.
Terceira horda superada é provisória, sem cura adicional, selo, conclusão ou
Andar 2. Guardião da Torre permanece para v0.5.2. Entrada e mapa preservados.

## v0.5.1.1 — Registro do Aventureiro, aprovada em 10/10/2026
Conforme SAVE_V0511.md e pedido de Thiago: autosave local protegido, caminho
Web estável, migração preservando originais e backup exportável/importável
com confirmação. Save continua v6, sem tentativa/checkpoint da Torre.
Importar ou recarregar retorna ao acampamento; nenhuma recompensa de carregamento.

## v0.5.2 — Guardião da Mata, aprovada em 10/10/2026
Conforme GUARDIAO_V052.md e pedido explícito de Thiago: chefe após terceira
horda na mesma arena, três ataques avisados e segunda fase a 50% HP. Morte,
abandono e fechamento continuam sem checkpoints. Vitória única registra
ascensão, Selo da Mata e Andar 2 nos dados, sem mapa ou viagem. Arte existente
reutilizada; valores provisórios documentados no ADR. Sem v0.5.3.

## v0.6.0 — Cinco Andares, aprovada em 10/10/2026
O pedido explícito registrado em CINCO_ANDARES_V060.md autoriza os Andares 1–5
com a mesma Mata, NPCs, Torre, hordas e Guardião existente. Essa autorização
substitui a restrição anterior de não iniciar Andar 2 para este recorte.
Progressão sequencial, 50 abates próprios, exploração independente e viagens
seguras pela Torre. Quinta vitória conclui campanha inicial, sem declarar 1.0.
Personagem e serviços globais preservados. Sem Andar 6, nova arte ou polimento.

## v0.7.0 — Arsenal, Etapa 1, aprovada em 11/10/2026
Conforme ARSENAL_V070.md: cinco categorias funcionais (espada, machado,
lança, arco, cajado), raridades independentes de melhoria, Mochila compacta
com ícones e detalhes/comparação sob seleção. IDs antigos preservados;
arco/cajado entram no Ferreiro existente. Projéteis físicos/mágicos têm
comportamentos distintos e respeitam World, menus e limites. Sem novas
habilidades, talentos, maestrias, mapas, chefes ou balanceamento global.

## Mata — rework visual, aprovado em 11/10/2026
Conforme MATA_VISUAL_LIMPA.md: formas/paleta simples inspiradas na referência,
piso limpo, trilhas legíveis, menos detalhes e árvores secundárias. Apenas
apresentação da Mata reutilizada nos cinco andares; dimensões, caminhos,
serviços, Torre, progressão, combate, menus e saves permanecem protegidos.

## Mata — correção artística, amostra autorizada em 11/10/2026
O visual do rework anterior foi rejeitado. MATA_AMOSTRA_ARTISTICA.md autoriza
somente demonstração separada com pixel art orgânica, grama viva e areia
contrastante. A aplicação aos cinco andares depende de nova aprovação.
Não modificar a Mata publicada nesta etapa. Parar após apresentar capturas.

## Direção Artística Oficial V2 — vigente em 11/10/2026
ART_DIRECTION_V2.md registra a nova referência oficial enviada pela direção:
pixel art orgânica, vibrante e acolhedora, acabamento profissional com recursos
reutilizáveis. Substitui a direção visual anterior; não aprova automaticamente
a amostra nem autoriza a migração integral. Aguardar avaliação da demonstração.
Preservar funcionalidades e os cinco andares existentes; sem mapas novos.

## Mata V2 — aplicação ao Andar 1 autorizada em 11/10/2026
MATA_V2_ANDAR1.md registra o pedido explícito para modificar apenas aparência
no Andar 1, mantendo posições e todo o restante. A autorização supera a pausa
na demonstração para esse andar. Andares 2–5 continuam com seu tema anterior.
Não alterar main/PRODUÇÃO, mecânicas, mapas, personagens ou persistência.

## Árvores e livro ilustrado — 12/10/2026
Aprovados conforme TALENTOS_DIARIO_V2.md: proficiência abre caminhos, nível geral dá pontos. O orçamento de habilidades existente é compartilhado com talentos. Técnicas adquiridas são preservadas. Primeiro recorte aperfeiçoa os três efeitos existentes e adiciona passivas por categoria; valores provisórios no ADR. Novas técnicas e seleção dos dois slots ainda pendentes. Save v7 migra v1–6.


## Etapa 2 aprovada em 12/10/2026
O contrato em `docs/decisions/PROGRESSAO_ETAPA2.md` substitui as habilidades e árvores antigas. Ultimate ocupa opcionalmente Skill 2 ou 3, Maestria 30 é automática e Domínio permanece separado.

