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
