# ARVÉON: Ascensão Ancestral — Etapa 2

Implementação na branch `feat/progressao-etapa2`, PR #2. Base remota recuperada: `a04b28d`; main, checkpoint e produção preservados.

## Entregas verificadas

- A, `e0d7010`: estado por categoria, intervalo entre Ultimates de categorias diferentes e rejeição de timers inválidos; 1.836 verificações locais sem falhas.
- B, `b510953`: validação v10 e migração atômica/idempotente; 1.849 verificações e 10 testes do journal sem falhas. Ativação do formato novo acompanhou a integração de interface.
- C, `dfd4a5f`: cinco Skill 1, quinze técnicas e cinco Ultimates, dano mágico/físico, geometria e efeitos; 2.001 verificações sem falhas.
- D, `015eacc`: graus, talentos, passivas, especializações e Maestria automática; 2.131 verificações sem falhas.
- E, `14ebd94`: runtime v10, Diário e HUD; 2.269 verificações sem falhas, incluindo cinco classes em quatro viewports.
- QA final local: **2.375 verificações, zero falhas**, incluindo 25 combinações classe/andar, mortes, elites, cargas, recargas e integridade. **10 testes do journal, zero falhas**. CI validado no commit `09155d4`: exportação Web, **33 checks em Chromium**, 317 capturas renderizadas (40 da Etapa 2) e todos os grupos visuais sem falhas. As capturas das cinco classes foram inspecionadas. [Actions validado](https://github.com/thiagohugo12-dotcom/arveon/actions/runs/38337606343). A publicação no TESTE fica condicionada à mesma suíte completa no commit de entrega.

## Save e integridade

Save v10 mantém atributos, XP, nível derivado, proficiências, frações de dano, Domínio, economia, mochila, baú, equipamentos e estados dos cinco andares. `abilities` guarda loadouts, graus, talentos, cinco cargas/restos, recargas por ID, Skill 1 por categoria e intervalo/categoria da última Ultimate. Não usa relógio de calendário para recargas.

Formatos v1–9 são validados integralmente antes da troca de estado. Os antigos ranks globais e nós substituídos são removidos; os pontos disponíveis são sempre `nível − 1 − investimentos novos`, sem um depósito somado de reembolsos. O teste de orçamento com 35 nós e cinco melhorias globais devolve exatamente 40 investimentos, não 60. Domínio/proficiência permanecem independentes.

A escrita em disco é temporária + rename; o original vira `.vN.original`, separado do `.bak`. O journal do navegador preserva uma chave imutável `.vN.original`, além do espelho rotativo. Importações preservam o arquivo prévio. Corrupção, versão futura, orçamento excedido, loadouts duplicados e habilidade incompatível são rejeitados sem substituir o original.

## Comparação provisória calculada

Mesmo nível geral 20 e proficiência 10. Atributos F4/V4/R6/M5/D5/E4; arma +0; Domínio 3/2/2/2. Sem passivas, especialização, crítico ou Maestria 30. DPS nominal não inclui aproximação, obstáculos ou tempo de voo.

| Classe | Básico | Intervalo | DPS nominal | Skill 1 | Recarga | Alcance básico |
|---|---:|---:|---:|---:|---:|---:|
| Espadachim | 22 | 0,626s | 35,16 | 29 | 6s | 120px |
| Guerreiro de Machado | 26 | 0,866s | 30,01 | 41 | 10s | 105px |
| Lanceiro | 24 | 0,722s | 33,25 | 33 | 8s | 170px |
| Arqueiro | 22 | 0,770s | 28,57 | 31 | 8s | 300px |
| Místico | 26 | 0,914s | 28,43 | 37 | 9s | 260px |

Espada favorece sequências/contra-ataque; Machado impacto e execução; Lança posição/controle; Arco distância/marca/mobilidade; Cajado Espírito, área e barreiras. Poderes, percentuais, geometrias e duração são parâmetros iniciais. A barreira absorve dano e nunca restaura HP; bônus de classe não se acumulam por troca de categoria.

## Correções encontradas no QA

- Crítico garantido da Maestria precisava de uma chance condicional separada do limite comum de 15%; a fórmula comum e Domínio continuam iguais.
- Marcas de técnicas precisam expirar também nos dois scripts de Guardião; controle não interrompe suas sinalizações.
- A amplificação da Fúria do Machado é separada no recibo: básicos e técnicas creditam somente o dano sem o bônus da própria Ultimate, limitado ao HP realmente removido. O mesmo roll de crítico é usado nos dois cálculos; o dano real não é duplicado.
- Pool de quatro projéteis cheio rejeita o disparo sem consumir recarga.
- Diário aberto pela Mochila recebe corretamente a permissão de personalização da área segura.
- A captura antiga esperava 17 de Corte Circular; Talho Ágil inicial produz 16, conforme cálculo por arredondamento. Asserções visuais foram atualizadas.

## Limites reais

QA automatizado usa Godot 4.5.1 e emulação de viewports/touches. Não houve medição de FPS/bateria ou validação física em Android/iPhone. Valores são provisórios, sem alegação de balanceamento definitivo. Existem cinco armas iniciais, uma por categoria; o catálogo de Skill 1 usa identidade individual desses equipamentos. Poção permanece no estado anterior, separada das habilidades. Efeitos temporários de combate não são persistidos; recargas e cargas são. Não há Andar 6, alteração de arte do mundo ou serviço novo.
