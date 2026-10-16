# Sequências das técnicas da Espada — 16/10/2026

Status: sprites refeitos para seguir os seis quadros das três referências do jogador.

- Estocada Precisa: postura, preparação baixa, avanço curto com rastros azuis, estocada reta, faísca amarela no contato e recuperação.
- Guarda Reativa: postura, elevação da espada, aro azul persistente durante a proteção, faísca ao bloquear, corte azul reativo e recuperação. A reação visual depende de um golpe efetivamente recebido durante a guarda.
- Kamusari (`danca_laminas` no identificador persistente): energia vermelha na preparação, carregamento, crescente, corte amplo, explosão de impacto e recuperação.
- Os três atlas PNG têm transparência e seis quadros em grade 3 × 2. O ator não é desenhado novamente durante a sequência, pois cada quadro já inclui seu corpo. O filtro de textura é nearest.
- `ClassCombat` continua responsável pelo mesmo dano, área, proteção, custo e recarga. Os quadros não alteram colisão, proficiência ou save v11. O contra-ataque da Guarda permanece apenas visual.
- Na direção horizontal esquerda, a apresentação espelha a arte. As poses foram aprovadas como referência voltada para a direita; em ataques verticais, a apresentação preserva a orientação artística lateral. Uma futura arte direcional exigirá atlas próprios.

Fonte visual: as três pranchas de seis quadros aprovadas na conversa, usadas como referência direta para os novos sprites. Não há dependência dos quadros em tempo de execução.

## Ritmo aprovado em 16/10/2026

Thiago avaliou a prévia reproduzível dos seis quadros e autorizou colocá-la no jogo. A apresentação usa os mesmos intervalos da prévia, em segundos:

- Estocada Precisa: 0,55 / 0,35 / 0,26 / 0,33 / 0,42 / 0,62.
- Guarda Reativa: 0,50 / 0,38 / aro durante a janela real de proteção / 0,45 no bloqueio / 0,38 no contra-ataque / 0,65 na recuperação. Sem bloqueio, a guarda passa direto do aro à recuperação.
- Kamusari: 0,50 / 0,55 / 0,26 / 0,39 / 0,42 / 0,72.

Os tempos são somente visuais. Dano, recargas, duração da proteção, colisões e save v11 continuam sob suas regras existentes. Publicação limitada ao TESTE fixo, conforme o contrato anterior do projeto.

## Correção de escala e ritmo — 16/10/2026

O ritmo acima foi rejeitado no jogo por ser grande, lento e mal executado. A revisão usa Estocada em 0,335 s e Kamusari em 0,485 s, com antecipação curta, golpe rápido e recuperação. A Guarda prepara em 0,12 s, mostra o corpo normal durante sua proteção real de 3 s e reage em 0,22 s; depois volta ao aro enquanto houver proteção.

Cada pose tem registro próprio pelos pés e corpo normalizado a 60 px, correspondente ao explorador. O renderer redesenha o corpo ao entrar/sair da sequência, acompanha a profundidade do personagem em movimento e elimina faíscas de células vizinhas da recuperação. O corte vermelho dissipa nas bordas do atlas com alpha de vértices, evitando um recorte retangular; sem shader ou nova arte. O início do treino foi movido para a clareira leste, para não esconder jogador/alvo sob uma copa.

Conferência local: quadros das três técnicas renderizados pelo Godot/OpenGL no cenário real de treino, comparados ao explorador normal. As regras de combate continuam independentes da apresentação.

## Correção do recorte — 16/10/2026

A borda suavizada continuava escondendo a ponta do golpe. O atlas fornecido possui efeitos que atravessam a grade de 512 px. O renderer passa a usar contornos de origem por quadro: inclui a extensão da Estocada e do Kamusari e a explosão completa das três técnicas, excluindo o corpo do quadro vizinho. A ponta do Kamusari termina antes dos pixels da próxima pose. Retirado o fade que mascarava o recorte. Conferência em capturas do cenário real e teste dos contornos além da antiga borda de 512 px.

## Identidade do explorador — 16/10/2026

O teste da transição confirmou que os atlas da referência substituíam o explorador por outro desenho. A revisão mantém sempre os pixels do personagem original: pernas de PEOPLE e poses articuladas do atlas aprovado de ataque básico. Os efeitos usam novos arquivos irmãos `estocada_precisa_fx.png`, `guarda_reativa_fx.png` e `kamusari_fx.png`, editados com ImageGen para remover exclusivamente pessoas e armas das três imagens e reconstruir os rastros atrás delas. Os originais foram preservados.

As camadas de energia ficam atrás do corpo nativo, respeitando sua profundidade; poses mudam ao longo dos mesmos seis quadros. Somente os efeitos giram nos ataques verticais, e o explorador usa sua arte direcional normal. O teste renderizado `sword_identity_capture.gd` compara os pixels opacos do rosto/cabelo às poses originais em 72 combinações (3 técnicas × 6 quadros × 4 direções), sem aceitar o personagem das referências. Esse teste roda no CI junto da renderização GL. Mecânicas, recargas e save v11 preservados.
