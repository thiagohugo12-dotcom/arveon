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
