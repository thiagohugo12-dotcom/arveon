# Refinamento local de combate e animações

Status: APROVADA para correções funcionais e produção de protótipos locais. APROVAÇÃO VISUAL PENDENTE para integração das novas artes.

Autor / data: Thiago (direção e autorização); implementação local em 17/10/2026.

## Autorização

Pedido “ARVÉON: ASCENSÃO ANCESTRAL — REFINAMENTO LOCAL DE COMBATE E ANIMAÇÕES”, recebido em arquivo de texto nesta conversa. Autoriza sincronização de Estocada/Kamusari, atuação corporal, protótipo do Guardião e revisão dos inimigos/feedback. Determina trabalho exclusivamente local, sem push, PR, Actions ou deployment; aprovação visual antes de substituir artes originais.

## Decisão e implementação

- `SwordTechniqueTiming` contém os tempos já aprovados. Estocada: duração 0,335 s, contato 0,135 s. Kamusari: duração 0,485 s, contato 0,215 s. Não houve mudança dos valores de dano, cooldown, alcance, largura ou quantidade de acertos.
- `ClassCombat` reserva a habilidade pelos mecanismos existentes e aplica o dano uma vez quando o relógio físico cruza o contato. Kamusari mantém os quatro acertos configurados no mesmo contato; não são quatro ativações adicionais. Direção é capturada na ativação; origem/linha de visão/alvos válidos são avaliados no contato.
- A apresentação da técnica lê esse mesmo relógio. Morte, troca de categoria/arma, troca do objeto de progresso e entrada na área segura cancelam a técnica pendente. Menus pausam o relógio e preservam a pose. Não há reembolso novo. Uma técnica não substitui outra antes do contato; após o contato uma nova técnica aceita pode substituir a recuperação, sem acrescentar cooldown global.
- `clear_skill1` limpa somente Skill 1, para não apagar a técnica independente ao abrir um menu. Mudança de categoria e morte continuam limpando os estados apropriados.
- Os alvos de ClassCombat são limitados ao mesmo World2D do jogador, necessário para isolar os dois painéis da revisão.
- Javali não causa contato durante a preparação da investida. Mandacaru usa o relógio físico para os 0,34 s de preparação, substituindo o SceneTreeTimer. Ao retornar para casa cancela o disparo pendente. IA pausa imediatamente ao detectar input modal bloqueado.
- O espinho verifica o segmento percorrido, com raio de contato vigente de 19 px e interrupção por World. Uma instância gasta não causa novo dano. Dano e velocidade permanecem iguais.
- O golpe frontal do Guardião aplica o dano na entrada em ACTIVE, depois dos mesmos 0,75 s de aviso; ACTIVE dura 0,12 s e mantém o bloqueio de um único acerto. Demais ataques e balanceamento preservados.
- A procura de posição para números de dano testa candidatos próximos, sem deslocamentos cumulativos até a parte inferior da HUD.

## Artes e revisão

`scenes/demos/local_combat_review.tscn` funciona offline, sem Main, save journal ou gravação de personagem. Reutiliza PlayerActor, EnemyActor, ClassCombat, TowerGuardian, EnemyProjectile e as regras atuais. O painel ANTES é comparação visual, não uma segunda execução de dano. O painel PROPOSTA executa o caminho real; o avanço manual recompõe um teste isolado desde o início.

- Jogador: três folhas novas, seis quadros e quatro direções, geradas localmente a partir dos pixels originais de PEOPLE e da espada aprovada. Nenhum asset original sobrescrito.
- Kamusari proposto: gesto da lâmina e energia circular com o mesmo alcance, incluindo alcance_treinado quando equipado; 64 segmentos e poucos arcos, sem partículas extras.
- Guardião: conceito V1 fornecido como referência, adaptado em sprite próprio de 80 × 80 por célula, quatro direções e oito poses. Repouso, preparação, contato e recuperação de um golpe frontal. Não usa a prancha conceitual inteira como sprite.
- Inimigos comuns: ataques propostos em folhas separadas, com recortes articulados das artes existentes. Conservam o desenho frontal estilizado; orientação do gesto é direcional, não um novo conjunto final de vistas anatômicas laterais/traseiras. Essas vistas podem ser refinadas depois da avaliação.
- Sons: não adicionados; não havia assets adequados com origem/licença definida no projeto.

Controles: personagem, ataque, quatro direções, loop, pausa/reprodução, reinício, quadro anterior/próximo, velocidade, área real, comparação e pernas andando. Mostra instante de contato/disparo e dano efetivo. Em retrato começa com um painel; a comparação pode ser ativada e a interface tem rolagem. Opções e botões têm alvo de toque de pelo menos 44 px.

## Validação

- `tests/local_combat_refinement_tests.gd`: 516 verificações, zero falhas. Inclui projéteis, cancelamentos, quatro direções, dt de 1/120 s, 1/30 s e 0,25 s, geometria, bordas dos sprites e 24 inimigos adicionais.
- `tests/local_combat_regressions.gd`: 281 verificações relevantes existentes, zero falhas (técnicas, progressão em combate, Guardião e treino). Fixtures antigas que pressupunham dano imediato agora avançam até o contato.
- `tests/local_combat_review_capture.gd`: 169 verificações renderizadas, zero falhas, incluindo controles, quatro direções, repouso e retrato 390 × 844.
- `tests/sword_identity_capture.gd`: 72 verificações renderizadas, zero falhas; arte aprovada continua preservada no jogo normal.
- Importação local Godot 4.5.1 sem erros de script; `git diff --check` sem erros.

Stress do contato com 24 inimigos adicionais: aproximadamente 1,8 ms de CPU neste desktop em execução headless. Isso não é medição de FPS nem validação em Android/iPhone físico. A aprovação visual humana permanece pendente. Não foi executada repetidamente a suíte completa nem realizado export/deployment.

## Rollback e preservação

Branch local `refine/combat-local-20261017`, baseada em `e08d532`. Branch anterior e checkpoints preservados. As importações locais preexistentes e a análise de 16/10 não foram apagadas ou incluídas no trabalho novo. Arquivos de arte novos vivem em `assets/art/local_combat_review/`; cenas e scripts de produção continuam apontando para as artes aprovadas.

Para reverter funcionalmente, revisar o diff local dos scripts listados acima contra `e08d532`; não restaurar tudo nem apagar arquivos não relacionados. Nenhuma versão remota foi modificada nesta etapa.
