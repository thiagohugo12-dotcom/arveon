# Skills 1 V1 - demonstracao isolada

APROVADO por Thiago em 14/10/2026, pedido completo das cinco Skills 1.
Base aff0c45; checkpoint checkpoint-antes-skills1-v1-2026-10-14.

A Talho Agil, B Racha-Chao, C Impulso Perfurante, D Flecha Certeira,
E Orbe Arcano. Cada etapa recebe testes especificos/regressoes e um commit.
Reutilizar corpos, pernas e armas aprovadas, com novos atlas de poses para
Skill 1 e efeitos leves. Nao modificar nenhum basico nem regras existentes.
IDs/formatos/recargas vem de AbilityRules/ClassCombat, somente leitura.

A preparacao no preview e uma intencao visual anterior a execucao. Nenhum
cooldown, dano ou projetil e criado nessa fase. Quando a execucao acontece,
PlayerActor.use_skill(0) resolve imediatamente pelo ClassCombat original;
o desenho entra no quadro de soltura nesse mesmo ciclo. Nao atrasar dano
nem projeteis reais para acomodar poses. O preview respeita a recarga real.

Talho: cone frontal dot 0; Racha: disco centrado no jogador; Impulso:
linha com semi-largura 28, alcance 190. Projeteis: 340/290, velocidades
originais, rastreio original do orbe. Efeitos nao tem colisao nem dano.

Um unico preview com cinco categorias, basico versus Skill 1, quatro
direcoes, caminhar, repetir e controles desktop/touch. Perfis em memoria,
sem Main/journal/saves. TESTE fixo aff0c45, main e producao preservados.
Integracao das Skills 1 ao jogo depende de aprovacao visual posterior.

Etapa A concluida: Talho Agil, 123 checks especificos sem falhas; regressoes dos cinco basicos passaram; captura Godot 4.5.1 desktop/mobile conferida.

Etapa B concluida: Racha-Chao, 250 checks acumulados sem falhas; disco/controle 0.25 originais preservados; cinco basicos sem regressao.

Etapa C concluida: Impulso Perfurante, 386 checks acumulados sem falhas; limites 27/29px, alcance190 e ausencia de deslocamento extra confirmados; basicos preservados.

Etapa D concluida: Flecha Certeira, 543 checks acumulados sem falhas; soltura/origem visual e trajetoria fisica, velocidade, alcance e dano originais confirmados; cinco basicos preservados.

Etapa E concluida: Orbe Arcano, 725 checks acumulados sem falhas; rastreio, limites de projeteis e pausa originais preservados. Todas as regressoes locais passaram. Probe nativo de 600 quadros: maximo 1 projetil, crescimento 1 no, pico 66 draw calls, media 8.012ms neste computador (nao e medicao de celular).

Refinamento visual final: Talho Agil de costas corta pelo lado externo da silhueta do cabelo, mantendo corpo/arm spans e todos os 725 checks. Capturas das quatro direcoes renovadas.


## Correcao de inspecao visual - autorizada por Thiago
Base 076e037. Investigacao nativa confirmou atlas especiais carregados e quadros
novos exibidos; o problema nao era falta dos sprites. Skill ativa por 0.36-0.68s,
contra cooldown de 6-10s, com basicos em ambos os paineis no restante do tempo.
O botao de repetir tambem aguardava cooldown. Layout calculava zoom antes de
reduzir o painel, prejudicando enquadramento principalmente nas direcoes verticais.

Preview agora abre em Inspecao Visual, 0.5x, botao Executar Skill 1 destacado,
loop visual independente, pausa de basicos e opcao explicita Combate Real.
Somente views/efeitos avancam em tempo local; nenhum use_skill/ataque/evento real
ou setup/fisica de projetil e chamado na reproducao. Desenhos dos projeteis sao
reutilizados por subclasses sem grupo/fisica. Jogadores e projeteis reais ficam
congelados e sao retomados com cooldown/budget inalterados. Alvo visual proximo
na inspecao; distancia de combate original restaurada ao sair. Sem Engine.time_scale.
Atlas/basicos e todo core mantidos byte a byte. Novo enquadramento usa o tamanho
final do painel. Bridge informa o atlas/quadro do caminho _draw_explorer efetivo.

159 checks de isolamento (inclusive projeteis reais em voo), 725 checks de combate,
regressoes dos cinco basicos aprovadas. 68 capturas nativas da timeline real, sem
pose_override, nas quatro direcoes: preparo, execucao, contato e impacto ranged.
Folhas de contato conferidas visualmente; bracos/armas e efeitos legiveis.
Publicar somente novo preview isolado; TESTE fixo/main/PRODUCAO preservados.


## Corpo inteiro V2 - autorizado pelo usuario
Pedido "quero animacoes de verdade", referencia de cinco acoes corporais.
Base d647b7e; checkpoint checkpoint-antes-skills1-corpo-v2-2026-10-14.
Cada Skill recebe antecipacao, apoio/passo, inclinacao do tronco/cabeca e
recuperacao proprios. Pixels do explorador preservados, sem recolorir identidade.
Atlas full body parado e upper body caminhando; pernas originais seguem a caminhada.
Sem alterar fisica, deslocamento real, alcance, dano, cadencia, progressao ou basicos.
Arco/Cajado nascem visualmente dos landmarks da pose nova, com fisica original.
Nao publicar no TESTE fixo/main/PRODUCAO; somente preview apos validacao.

Etapa A V2: Talho Agil com recuo, passada, giro/inclinacao e corte com faixa
luminosa ligada a lamina; 734 verificacoes sem falhas, margens e identidade conferidas.
