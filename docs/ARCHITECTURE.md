## Layout aprovado dos menus
GameHUD organiza o Ferreiro em grade, seleção com comparação e confirmação
separada; Vendedor tem abas e transações unitárias originais. Cabeçalhos curtos
e fechamento fixo reutilizam o tema do diário. RPGPanel mostra espaços reais
em cartões e treinamento compacto; manutenção fica em Mais opções. Catálogos,
handlers e validações de GameProgress não mudam. Sem novo asset ou save.

## Menus de serviços e configuração
GameHUD usa cartões compactos de loja/venda e altura maior para os serviços.
Os handlers originais continuam recebendo as mesmas ações e IDs. A detecção
recursiva de botão no scroll adia o toque até o release, cancelando arrastos.
RPGPanel separa o catálogo em técnicas/passivas/estilo e monta ações somente
para a seleção. Cabeçalhos distinguem pontos da arma e de talento; estatísticas
de treino vêm dos mesmos dados. Sem mudança de modelo de dados ou save v11.

## Espada — interface de nós do diário
SwordEvolutionTree mantém os IDs do primeiro passe e apresenta cartões com
PixelItemIcon do atlas existente, faixas de proficiência e estados reais de
AbilityState. PathLink redesenha somente ao redimensionar. As linhas organizam
o percurso; requisitos continuam em AbilityRules. RPGPanel preserva ações e
validações e oferece retorno ao nó após o detalhe. O HUD mantém seu handler de
toque ao soltar e distinção de arrasto. Nenhuma mudança em combate ou save v11.

## Carregamento Web — artes aprovadas em 15/10/2026
A injeção pós-exportação valida as duas fontes por hash e publica arquivos
com identidade de conteúdo. Picture/contain preservam a composição e o progress
original mantém o onProgress do Godot. Dicas substituem somente o texto
estático da arte. Manifesto e verificador público incluem os recursos visuais.
Detalhes e diagnóstico: docs/decisions/LOADING_ARTES_APROVADAS_20261015.md.
Sem dependência nova no jogo, alteração de gameplay ou save v11.

## Skills 1 V2 - integradas no Andar 1
Skill1GameView adapta os atlas aprovados e herda todos os basicos. PlayerActor
agenda uma startup transitoria antes da chamada original ClassCombat.use(0).
Apenas a View de jogo ativa esse caminho: a demonstracao mantem seu controlador
isolado sem dupla preparacao. Sem alteracao em ClassCombat/AbilityRules/saves.
Skill1GameProjectile reutiliza a arte especial da demo sobre PlayerProjectile;
colisao, alvo, velocidade e budget originais. ImpactMarks compartilha os mesmos
pixels com alvos de demo e filhos visuais dos monstros, sem trocar suas Views.
GroundEffect e unico/reutilizado, em coordenadas de mundo e z abaixo dos atores.
Outros andares e Skills 2/3 continuam no caminho original.

## Skill 1 - poses de corpo inteiro V2
Skill1BodyPose compartilha os landmarks em pixels com o baker e a origem visual
de projeteis. Full-body inclui apoio dos pes parado; upper-body combina a acao
com pernas originais durante caminhada. Transformacoes de pose sao rasterizadas
no atlas, nunca aplicadas ao PlayerActor fisico. Core/basicos preservados.

## Inspecao visual das Skills 1
A demonstracao pode congelar PlayerActor e projeteis reais e avancar somente
ActorView/efeitos em delta local (0.5x ou 1x). Execute/repeat nao chama combate,
nao cria eventos nem adiciona PlayerProjectile ao grupo real. Desenhos aprovados
sao reutilizados por wrappers exclusivamente visuais. Modo Combate separado
preserva o caminho original e os testes existentes. Nenhum atlas foi alterado.

## Refinamento local de combate — 17/10/2026
ClassCombat mantém uma técnica transitória com relógio físico, direção capturada
e marcador de contato único. SwordTechniqueTiming é compartilhado com a view;
nenhum estado novo é serializado. Estocada e Kamusari executam o mesmo _execute
no contato, incluindo quatro acertos do Kamusari e validação de alvo/LOS.
Morte/equipamento/área segura cancelam; menus pausam sem apagar a pose.
A cena local_combat_review usa World2D separados para comparação e reconstrução
determinística de inspeção. Só seus wrappers usam os novos atlas; Main e saves
não participam. EnemyProjectile usa segmento percorrido; Mandacaru usa windup
físico de 0,34 s. Sem novas dependências ou serviços.

# Arquitetura
## Skills 1 V1 - preview isolado
Skill1ActorView estende MeleeActorView sem alterar os cinco basicos.
Apenas play_skill(0) usa os novos atlas; outros indices delegam ao original.
Skill1ReviewDemo reutiliza os mundos/controles/alvos e executa PlayerActor.
use_skill(0) sem reimplementar ClassCombat. A intencao de preparacao no
preview antecede a chamada real, que resolve dano/projeteis imediatamente.
Efeitos de area leem AbilityRules; nao possuem colisoes ou dano. Uma instancia
por painel e reutilizada. Sem Main, journal ou saves. Politica skill1-review
bloqueia TESTE fixo; nenhum basico/core de combate e modificado.

## Machado/Lanca V1 - integracao aprovada
MeleeActorView estende StaffActorView e compartilha os atlas/timing aprovados
com as demonstracoes. Estado melee separado; trocar Machado/Lanca limpa a
pose anterior e seleciona o atlas correto. PlayerActor antecipa o golpe
apenas durante cooldown com alvo valido, e inicia a pose no sinal original.
AutoAttack continua aplicando o dano imediato uma unica vez. Skills, saves,
atributos e apresentacoes de Espada/Arco/Cajado permanecem intactos.
A politica melee-review aprovada autoriza publicar somente no TESTE fixo.

## Machado/Lanca V1 - demonstracoes
MeleeReviewDemo estende a UI/mundos/alvos da demonstracao do Arco. Duas cenas
selecionam a arma e seu perfil real; MeleeReviewView compartilha estado e
pernas, mas cada atlas usa landmarks e movimentos diferentes. O rig herda
a composicao aprovada do Cajado, com bracos compactos e cabeca sobre a arma.
AutoAttack aplica dano imediato pelo caminho original. As demos nao
inicializam Main nem o journal. A politica aprovada permite atualizar o TESTE.

## Cajado V1 - integracao aprovada
StaffActorView estende BowActorView, com estado separado para o cajado.
StaffProjectile reaproveita a fisica e muda somente o desenho/origem visual.
O atlas aprovado e compartilhado pelo jogo e demo, que usa adaptadores leves.
PlayerActor antecipa durante cooldown e dispara pelo sinal original. Main
seleciona StaffProjectile somente para basicos cajado/orbe no Andar 1.
Skills, Ultimates, cenarios legados e todas as regras permanecem intactos.
A aprovacao de Thiago permite atualizar exclusivamente o alias TESTE.

## Cajado V1 - demonstracao isolada
StaffAttackDemo herda a UI, controles, mundos e alvos de BowAttackDemo.
StaffDemoView usa o atlas de oito poses/quatro direcoes, pernas originais
e landmarks compartilhados com o rig. StaffDemoProjectile herda a fisica
original e altera apenas desenho/offset visual; canalizacao antecipa somente
a pose. Skills e Ultimates continuam com PlayerProjectile. Nenhum Main,
save ou sistema de progressao e instanciado/modificado pelo demo.
A politica staff-review passou a aprovada para integrar no TESTE.

## Arco V1 — integração aprovada
BowActorView estende SwordActorView sem alterar seus frames ou comportamento.
As poses do arco usam estado independente; PlayerActor antecipa apenas durante
cooldown e dispara a pose pelo mesmo sinal de AutoAttack. BowProjectile muda
somente o desenho do básico no Andar 1; Skills e pisos legados usam a classe
original. Troca de arma, morte, modais e área segura limpam as poses.
O atlas existente foi ajustado apenas nas ancoragens/extensão dos braços e
do arco. Personagem, dimensões, oito poses, pernas e cadência preservados.
Publicação no TESTE autorizada em 14/10; política aprovada é validada antes
de chamar o publicador do alias. Dados de save/progressão não mudam.

## Demonstração do arco preservada
BowAttackDemo cria dois mundos e perfis somente em memória. Antes usa
PlayerActor/ActorView/PlayerProjectile; Agora usa subclasses exclusivas da
demonstração para antecipar poses e deslocar somente o desenho da flecha.
AutoAttack e PlayerProjectile continuam intactos, inclusive colisões e dano.
Alvos de treino derivam de EnemyActor para exercitar impactos reais; nenhum
recibo/recompensa é conectado à progressão. Sem Main ou journal de save.
Atlas de oito quadros e quatro direções com pés em (40,52), escala inteira 2x,
pernas originais independentes. Rig/baker não entram na exportação Web.
A demonstração reutiliza as classes de apresentação integradas. A espada
não é modificada; o modo Antes continua usando ActorView/PlayerProjectile.

## Espada V1 — apresentação aprovada
PlayerActor antecipa apenas poses durante o cooldown; o sinal original de
AutoAttack inicia o corte, sem alterar dano ou cadência. SwordActorView substitui
somente o corpo pelo atlas aprovado, mantendo pernas, sombras e feedback de
ActorView. Ativo apenas com espada equipada na apresentação do Andar 1;
demais armas e pisos preservam a apresentação anterior. Saves não mudam.

## Introdução — save v11
Main chama begin_new_character somente quando não existe save recuperável e
a persistência não está bloqueada. GameProgress mantém dados legados como
defaults de migração/fixtures; o runtime novo zera apenas o equipamento inicial.
CommonMission.enabled pausa a missão comum; Main pausa os desafios e a Torre.
AutoAttack.armed impede busca, dano, projéteis e animação sem categoria equipada.
ClassCombat e HUD já aceitam categoria vazia e mantêm skills desativadas.

GameProgress.claim_first_weapon valida visita e serviço, concede +0 e equipa,
grava o snapshot completo e reverte a recompensa se a persistência falhar.
Save v11 valida introdução antes de substituir qualquer campo. Formatos v1–10
recebem legacy, incluindo personagens que tenham desequipado sua arma.
Seleção/confirmador vivem no painel rolável do Ferreiro; nunca no save.
ArsenalRules.effective compara itens não possuídos com upgrade zero, sem mutação.

## Progressão — Etapa 1 (save v9)
RPGRules centraliza seis atributos e redução recebida física/mágica. GameProgress
mantém dois pontos de atributos e um ponto compartilhado de talento por nível;
classes são derivadas da categoria equipada. v1–7 validam quatro atributos antes
de remover Agilidade; o saldo derivado devolve o investimento exatamente uma vez.
v8 tem seis atributos e curva antiga; v9 possui curva nova, domínio e resto de XP.
TalentProgress converte XP antigo por 0,4, preservando nível/fração e nós válidos.
O journal Web mantém sua chave v6 intencionalmente. Importação, checksum, backup,
arquivo original e validação atômica permanecem no mesmo caminho.

EnemyActor aceita IDs de evento por vida, limita crédito à vida real removida e
ao orçamento original de HP (não reposto por cura). Recibo de uso único emitido
antes do callback letal garante autosave do último impacto. Main valida origem,
época do andar e tentativa antes de consumir o recibo. TalentProgress converte
dez HP em um XP, mantendo o resto 0–9 salvo por categoria. Talentos e domínio
possuem orçamentos separados. Projéteis capturam dano resolvido, crítico, tipo,
categoria e ID; impactos não consultam a arma atualmente equipada.

CombatRules concentra sorteio injetável para QA e cálculo final com um único
arredondamento. Bônus de domínio/proficiência são aditivos no mesmo fator;
crítico é o último multiplicador. Corte/Investida conservam dano físico e Fúria
seu efeito/duração; cajado possui básico mágico. Feedback crítico reutiliza os
dois números existentes, sem nós/partículas adicionais. Mobilidade não muda Dash;
Destreza só muda intervalo básico. Armadura física plana precede Resistência;
Resistência afeta também dano mágico, seguida da redução atual de Fúria.

RPGPanel oferece seis atributos e páginas Domínio/Talentos por categoria, com
grade de duas colunas quando há largura e rolagem em telas menores. Main valida
compras com valor esperado para evitar toque duplicado e autoriza redistribuição
dos nós apenas na área segura, fora de provas. Trocar arma não apaga investimentos
e apply_progression continua sem curar. Configuração livre de skills/passivas e
especializações definitivas ficam reservadas à próxima etapa.

## Diário e HUD
V3: peças 96×96 preparadas offline, com nove fatias para madeira, papel,
botões e slots; fonte Cormorant Garamond incorporada sob OFL. A mochila
preserva a grade ao selecionar e apresenta detalhes/comparação abaixo,
com rolagem até a ação e retorno visível no topo. Colunas em paisagem,
perfil acima em retrato. HUD usa barras e texto sobre o mundo com contorno,
missões em papel e ações/menu em madeira. Nenhuma mudança de regra/save.
DiaryTheme centraliza papel, madeira, contraste e estados de botões.
DiaryPortrait reutiliza o sprite atual. EquipmentBag apresenta grade e resumo
responsivos, preservando sinais de seleção/comparação/equipamento. GameHUD
troca páginas do diário pelos mesmos sinais modais do Main; menus continuam
bloqueando movimento/combate e restaurando comandos ao fechar. RPGPanel
mostra skills reais e árvores funcionais de proficiência/talentos (V2 abaixo).
Poção é reserva desativada: nenhuma mecânica ou campo de save foi criado.

## Atores da vila V4 — Andar 1
VillageActorArt compartilha três atlas pequenos nearest 2x, preparados offline
com alpha original e crop comum entre quadros. ActorView escolhe quatro poses
e direções do explorador e passos dos três monstros. Deslocamento real dirige
a passada; não anima caminhada ao bater numa parede. NPCs fazem ações curtas
sem mudar transform, âncora ou corpo físico. VillageChestView observa a
abertura do menu Baú. ExplorationView observa os dados existentes para
transições de 0.22/0.24 s ao coletar/abrir; animações não escrevem progresso.
As onze peças de exploração são criadas uma vez, com z pelos pés para
respeitar a profundidade das árvores; sem criação de nós por quadro, luzes,
partículas, shaders ou geração runtime. Sprites só redesenham quando a pose
ou alpha muda. Atlas antigos e temas dos Andares 2–5 permanecem disponíveis.

## Hub V3 (Andar 1)
Polimento: ground.png mantém as rotas e recebe franjas preparadas offline.
Arbustos têm posições autorais sem colisões novas. Flores e tufos usam poucos
retângulos estáticos na mesma grade de 2 px. Explorador desenha 60x60 apenas
no tema V3, sem escalar ActorView/Player ou seu corpo físico. NPCs piscam sem
alterar transform; fogueira usa um overlay de poucos retângulos a 8 Hz. Sem
partículas, luzes ou shaders. HUD horizontal distribui os painéis no topo.
FloorV2View usa ground.png estático e atlas hub_v3, nearest 2x proporcional.
Sprites estáticos são criados uma vez com z derivado dos pés. ActorView usa
o mesmo z: copas e telhados encobrem personagens atrás, sem redesenhar artes.
SafeCamp.nearest_station recebe o tema para escolher âncoras visíveis sem
interações fantasmas. NPCs alinham os pés às mesmas âncoras. Andar1Obstacles
mantém shapes de ambos os temas, alternando disabled sem recriar paredes.
Somente bases bloqueiam; área segura/clearance, rochas e mundo iguais. Pés de
árvores fora das construções preservados; árvores encobertas e seus shapes
ficam desativados apenas no tema do Andar 1.

- `scenes/`: composição Godot. Main injeta HUD/InputDriver no Player; mapa isolado em world.
- `scripts/actors/`: Player e Enemy, movimentação e coordenação de componentes.
- `scripts/components/`: Health, AutoAttack e DashMotor. Sem dependência da arte/HUD.
- `scripts/input/`: converte teclado/touch em direção e pedido de dash; não move atores.
- `scripts/presentation/`: FloorView usa chão/trilhas estáticos e um atlas compacto da Mata; a cabana existente é preservada. ActorView usa atlas de quadros por ator. GuardianView desenha o chefe. Hitboxes são independentes do desenho.
- `ui/`: joystick e ações touch, HP e morte. Só emite comandos e observa estado.
- `data/`: Resources tipados `.tres` para atores/arma. Balanceamento desacoplado.
- `assets/art/`: sprites pequenos em paleta limitada e atlas dos atores; `audio/` reservado.
- `tests/`: runner sem plugins; testes executáveis em SceneTree headless.
- `docs/`, `agents/`: contrato, decisões, responsabilidades.

## Fluxo
InputDriver → Player → CharacterBody2D/DashMotor. AutoAttack → seleção de alvo do grupo damageable_enemies → Health. Health → ActorView/HUD. Main compõe referências; não existe singleton global.
Personagens têm shape físico independente do desenho. World layer 1, Player 2, Enemy 3. Atores colidem com World; combate usa distância e HP, não depende de colisão de sprites. Parede bloqueia linha de visão do ataque; IA não contorna obstáculos ainda.

## Desempenho
Física 60 Hz padrão; até cinco inimigos, incluindo o chefe opcional. Seleção de alvo somente no ritmo do ataque (não por frame), sem sort/alocação de lista adicional. Desenho de chão estático e efeitos de poucos retângulos por quadro; sem luzes, shaders, partículas de nós, navegação, threads ou rede. CPU/GPU e FPS devem ser medidos em dispositivo real antes de ampliar populações. Para escala futura, substituir busca em grupo por índice espacial preservando contrato de seleção; não implementar antecipadamente.

## UI
Canvas expand sem proporção fixa; HUD usa cantos e dimensão atual do viewport. Joystick esquerdo com um índice touch, ações à direita com índices independentes. Limpa comandos ao perder foco. Safe area nativa é aplicada quando disponível. Habilidades observam cooldown; Personagem, mochila e Ferreiro emitem comandos validados pelo Main.


## RPG v0.3.0
GameProgress é a fonte única de XP, atributos, equipamentos, carteira e missões.
RPGRules centraliza curvas e receitas. Player aplica bônus sem acumular e
preserva HP atual ao trocar equipamento. Saves v1–4 migram para v5 com validação
completa antes de alterar memória. Missões adicionais têm contadores limitados;
recompensa somente na primeira conclusão. RootGuardian estende EnemyActor com
três ataques avisados. GuardianView desenha pixel art e telegráficos leves;
nenhuma dependência, mapa adicional, navegação ou partícula foi adicionada.

## Torre v0.5.0
GameProgress possui AscensionProgress, serializado no save v6. Save v1–5 migra
derrotas históricas de Mata; validação é atômica antes de trocar estado em memória.
Main conecta derrotas com origem, marca uma vez por vida e mantém recompensas.
TowerEntrance centraliza posição, interação e corpo físico; TowerView desenha
geometria estática. O menu reutiliza station_panel e seu bloqueio de input.
Só Andar 1 existe; requisitos ficam em FLOORS, conclusão é registrada como falsa.
Não há arena, seleção, teletransporte nem ação para concluir a prova nesta etapa.

## Torre v0.5.1
TowerTrial é RefCounted: fases, identificador de tentativa, roster de cada horda,
conjunto de mortes pendentes e relógio de quatro segundos. Não é serializado.
Main mantém o mesmo Player, HUD e GameProgress, destacando Andar1 da árvore e
instanciando a cena tower_arena (720×540) em um espaço físico separado (1600,0).
Retorno reanexa a Mata e repõe limites originais da câmera; reload libera a cena
retida e inicia no acampamento. Nada altera o arquivo do mundo ou TowerEntrance.

Inimigos reutilizam a fábrica existente e ficam como filhos do Main para manter
validação de origem e recompensas. arena_bounds estende perseguição apenas na
prova, sem sleep/despawn e com quatro paredes; comportamentos dos três tipos e
do elite são mantidos. Limite local seis, Mata cinco. Projectiles ficam limitados
à arena e são descartados ao limpar horda/tentativa. Timer da horda não usa
SceneTreeTimer: só avança em _process_trial, fora de menus. Identificador e
conjunto pendente rejeitam eventos antigos, vivos ou duplicados.

Entrada/saída bloqueiam comandos e físicos durante fade de 0,16s por metade.
Menus da prova pausam criaturas, projéteis e relógio. HUD usa station_panel com
botão de ação de 44px fora do scroll. Minimapa muda para o retângulo da arena;
Mata conserva WORLD_SIZE 1200×900. Health.heal não revive e limita ao máximo;
chamado uma vez no fim das duas primeiras hordas, jamais no fim da terceira.
Após a terceira fase AWAITING_GUARDIAN guarda lugar para integração futura,
sem disparar chefe ou gravar conclusão. Retorno automático na morte aplica
uma perda normal, recuperando HP como o reinício existente; abandono não cura.

## Registro v0.5.1.1
Schema GameProgress v6 mantido, separando to_json/load_text de IO. Save valida
snapshot, compara último conteúdo, guarda .bak, verifica .tmp e renomeia.
Migrações arquivam .vN.original; importações confirmadas retêm original.
Dados inválidos/futuros bloqueiam autosave; truncamento permite recuperação
somente de leitura. BrowserSave/JS usa journal localStorage síncrono SHA-256
com compare-and-swap entre abas, sem retirar IndexedDB IDBFS do Godot.
Custom user dir Web fixo; busca pastas antigas sem apagar arquivos.
Main mantém eventos, verifica mudanças a cada 30s e ao ocultar/perder foco.
SavePanel reutiliza o bloqueio modal e abre pela Mochila. Importar substitui
estado e recarrega no acampamento; nenhum estado TowerTrial entra no payload.
CI valida exportação real com Chromium/CDP e Node integrado, sem biblioteca
adicionada ao jogo. As limitações de origem/quota/privacidade seguem documentadas.

## Guardião da Torre v0.5.2
TowerGuardian estende EnemyActor separadamente de RootGuardian (chefe opcional
inalterado). State APPROACH/WINDUP/ACTIVE/RECOVERY não usa timers de dano.
Três centros de espinhos e um flag attack_hit por execução substituem nós extras;
menus pausam o relógio físico. Golpe frontal usa cone de 90 px e LOS; investida
usa direção capturada, segmento varrido e move_and_collide, limitada à arena.
Fase 2 observa Health, preservando avisos e dano. TowerGuardianView reutiliza
corpo procedural de GuardianView e mantém desenhos separados das hitboxes.

TowerTrial adiciona apresentação/GUARDIAN/VICTORY somente em memória. Main
guarda ator/token/fase e registra morte uma vez; vitória não passa pelo loot do
chefe opcional. AscensionProgress.complete_forest_trial marca conclusão, selo e
[1,2]; Main aplica XP/ouro no mesmo snapshot v6. Loader exige consistência,
aceita saves antigos sem forest_seal quando incompletos. Nenhuma recompensa
ocorre em load/import. Selo é permanente e aparece na Mochila, sem comércio ou
perda na morte. Andar atual permanece 1 e não há ação de viagem.
HUD usa espaço da missão durante o chefe, sem painel permanente adicional.

## Campanha v0.6.0
FloorConfig centraliza os cinco identificadores/configurações, requisito 50,
HP/dano e XP/ouro, e referências às mesmas cenas da Mata/arena/Torre.
AscensionProgress guarda andar atual, contadores próprios, cadeia de
conquistas/desbloqueios, selo e campanha inicial. Valida exclusivamente
prefixos conquistados consistentes, sem aceitar saltos ou Andar 6.

GameProgress.floor_states possui coletas, caches, descobertas e altar opcional
por andar. Os campos de exploração anteriores representam o andar atual e
são sincronizados ao salvar/trocar, mantendo as views existentes. Personagem,
missões, inventário, equipamentos, baú de serviço e economia são globais.
Save v6 anterior sem floor_states migra sua exploração para o Andar 1;
conquista anterior conserva selo/desbloqueio do 2. Importação é validada
completamente antes da substituição. Journal, backups e autosave mantidos.

Main._travel_floor descarta atores/projéteis e a Mata atual, instancia a mesma
cena e chega em SafeCamp.RESPAWN com HP/dados globais preservados. Somente
um cenário explorável está carregado. floor_epoch rejeita eventos atrasados;
estatísticas privadas são escaladas uma vez por ator. Velocidade, IA, arte,
limites e ataques são os originais. Ranged/raízes/investida usam a mesma escala
de dano, sem alterar janelas, alcance, fases ou feedback.

TowerTrial captura floor_id somente em RAM. Vitória registra a conquista e
a recompensa única juntas; load/import nunca concede recompensas. Os cinco
andares compartilham as hordas e o Guardião, com recuperação entre hordas
e morte/abandono sem checkpoints. Viagem é proibida durante tentativas.
Inimigos vivos não são snapshots persistentes: retornos repovoam a Mata;
a exploração e os marcos permanentes permanecem independentes e salvos.

## Arsenal v0.7.0 — Etapa 1
ArsenalRules centraliza categorias, alcance, intervalo, tipo/velocidade de
projétil, raridades e metadados estáveis. RPGRules conserva os sete IDs/receitas
e upgrades anteriores; acrescenta apenas arco/cajado. O Ferreiro existente
continua produzindo e melhorando itens. Raridade não depende da melhoria.
PlayerActor aplica o perfil ao WeaponData privado, preservando o cálculo de
dano e as três habilidades. AutoAttack conserva seleção e World/LOS; melee
atinge uma vez, ranged solicita PlayerProjectile com dano/alvo capturados.
Flecha usa direção fixa, orbe tem correção limitada sem trocar alvo. Raycast
varrido por passo impede atravessar obstáculos; o primeiro alvo válido recebe
um único impacto. Limite global de quatro projéteis, removidos em transições,
sem colisores/partículas adicionais, pausados pelos menus existentes.
EquipmentBag apresenta cartões ou um detalhe com ações/comparação efetiva
somente de leitura. GameHUD mantém cabeçalho/abas/fechamento fora do scroll;
toque em cartão só seleciona ao soltar, distinguindo arrasto de toque.
PixelItemIcon desenha os cinco ícones localmente de forma determinística.
Save v6 mantém equipment (ID → melhoria) e equipped (slot → ID), acrescentando
equipment_meta validado pelo catálogo. Ausência de metadados em saves antigos
é aceita sem apagar/adicionar itens; próximo save incorpora metadados. Dados
forjados são rejeitados antes da substituição, inclusive em backups. Journal,
autosave, inventário, campanhas e tentativas sem checkpoint permanecem iguais.

## Rework visual da Mata
MataArt gera um atlas pixel art 128×48 com três copas simples e um arbusto.
tools/generate_mata_atlas.gd reproduz o PNG com o próprio Godot; em runtime
somente a textura importada é usada e compartilhada. Sem geração de imagens
por quadro ou na abertura, novos nós, shaders, luzes ou partículas. Os três
PNGs antigos de copa ficam no Git para histórico, excluídos do pacote Web.
BERRY é conservado para a arena, que não faz parte do rework.
FloorView mantém trilhas/clareiras/rochas e NPCs; piso sem textura repetitiva,
decoração reduzida e seis árvores secundárias removidas após a geração antiga.
Os 28 pés restantes não mudam. Andar1Obstacles consome a mesma lista, portanto
os seis círculos físicos também desaparecem sem colisores órfãos. Nenhuma
alteração ao mundo 1200×900, paredes/rochas/serviços ou corpo/posição da Torre.
TowerView apenas simplifica pedra e runa, observando os mesmos sinais.
Preview usa no-store no HTML/loader/PCK; após publicar, CI compara SHA-256 do
HTML/PCK servido pelo alias TESTE com o export testado, sem alterar produção.

## Mata V2 — apenas Andar 1
FloorV2View registra apresentação substituível dentro do _draw do FloorView,
sem novos nós/processos/colisões. Main escolhe o flag pelo current_floor == 1;
TowerView/ExplorationView acompanham o tema. PNGs autorais pequenos, atlas e
caminhos preparados offline, filtro nearest. Todos os andares mantêm a mesma
geometria; 2–5 usam integralmente o renderer anterior. Tema não entra no save.

## Livro e talentos V2
DiaryArt usa book_skin.png e items_skin.png gerados e preparados offline com nearest, cerca de 176 KB juntos. Masters preservados e excluídos do Web. Controles continuam separados da imagem. DiaryPaper garante papel opaco sem vazamento do cenário; a lombada é discreta. EquipmentBag usa 4 colunas em paisagem, 3 em retrato, com perfil compacto acima no celular.
TalentRules separa dados e requisitos, TalentProgress controla XP por categoria e nós aprendidos. GameProgress v7 valida tudo antes de aplicar, compartilha pontos entre skills antigas e árvore e migra v1–6. A chave do journal Web permanece v6 intencionalmente para preservar armazenamento existente. EnemyActor emite weapon_hit somente após validar dano/alvo e antes do callback letal; Main registra proficiência. PlayerProjectile captura categoria na criação. Bônus passivos exigem arma equipada e apply_progression nunca cura. Técnicas somam um grau ao legado, máximo efetivo 4; base antiga continua 1–3.

## Progressão Etapa 2 / save v10
AbilityRules define as identidades individuais das cinco armas, técnicas, passivas, talentos e efeitos provisórios. AbilityState conserva builds, graus e relógios por categoria/ID, cargas e intervalo entre Ultimates. ClassCombat coordena geometria, barreiras, guarda, marca, sequências, especialização e Maestria; seus efeitos transitórios não curam ou se somam ao trocar categoria.

PlayerActor delega Skill 1/2/3 a ClassCombat e espelha os timers para apresentação. AutoAttack e PlayerProjectile conservam tipo, categoria e origem no hit. EnemyActor limita o crédito ao HP disponível e ao orçamento vital, emite recibo descartável e deduplica eventos. Main consome o recibo uma vez, encaminha proficiência e carga elegível e rejeita epoch/andar/tentativa inválidos. Os Guardiões compartilham somente o relógio dos novos status; os avisos e ataques existentes ficam intactos.

GameProgress valida completamente os formatos antigos antes de migrar, mantém Domínio/proficiência e calcula pontos gerais por orçamento. O payload v10 possui campos legados vazios e AbilityState validado; originais são backups imutáveis no filesystem e journal. Diary/HUD emitem comandos com identificador/slot e os handlers verificam camp/trial e versão esperada do grau. Critérios e comparação reproduzível: docs/qa/PROGRESSAO_ETAPA2.md.



