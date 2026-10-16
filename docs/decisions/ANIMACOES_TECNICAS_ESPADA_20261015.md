# Sequências das técnicas da Espada — 16/10/2026

Status: sprites refeitos para seguir os seis quadros das três referências do jogador.

- Estocada Precisa: postura, preparação baixa, avanço curto com rastros azuis, estocada reta, faísca amarela no contato e recuperação.
- Guarda Reativa: postura, elevação da espada, aro azul persistente durante a proteção, faísca ao bloquear, corte azul reativo e recuperação. A reação visual depende de um golpe efetivamente recebido durante a guarda.
- Kamusari (`danca_laminas` no identificador persistente): energia vermelha na preparação, carregamento, crescente, corte amplo, explosão de impacto e recuperação.
- Os três atlas PNG têm transparência e seis quadros em grade 3 × 2. O ator não é desenhado novamente durante a sequência, pois cada quadro já inclui seu corpo. O filtro de textura é nearest.
- `ClassCombat` continua responsável pelo mesmo dano, área, proteção, custo e recarga. Os quadros não alteram colisão, proficiência ou save v11. O contra-ataque da Guarda permanece apenas visual.
- Na direção horizontal esquerda, a apresentação espelha a arte. As poses foram aprovadas como referência voltada para a direita; em ataques verticais, a apresentação preserva a orientação artística lateral. Uma futura arte direcional exigirá atlas próprios.

Fonte visual: as três pranchas de seis quadros aprovadas na conversa, usadas como referência direta para os novos sprites. Não há dependência dos quadros em tempo de execução.
