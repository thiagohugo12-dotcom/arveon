# Arquitetura
## Hub V3 (Andar 1)
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
