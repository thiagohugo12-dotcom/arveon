# Revisão local das habilidades da espada

Autorização: Thiago pediu o Kamusari novamente atravessando a frente, conforme comparação anexada, e revisão de todas as habilidades da espada. Trabalho exclusivamente local.

## Resultado

- Talho Ágil: apresentação aprovada preservada; preparação, execução e retorno validados pela suíte Skill1Game.
- Corte Crescente: substitui flash genérico por arco verde/branco com cauda afilada e pose do explorador original. Execução de dano imediata preservada.
- Guarda Reativa: defesa azul, reação dourada e corte de resposta completos da correção anterior preservados; revisados nas quatro direções.
- Estocada Precisa: a frente do efeito agora alcança o impacto na marca de contato de 0,135 s; antes a animação da frente chegava depois da faísca.
- Ruptura Ancestral: substitui flash genérico por rastros dourados/brancos na direção do golpe, com pose do explorador. Execução de dano imediata preservada.
- Kamusari: corte amplo vermelho/branco com caudas completas inicia 0,045 s antes do contato, atravessa a frente e se dissipa. Corrige a proposta que parecia apenas um círculo no contato. Círculo, quatro acertos, alcance, recarga e duração originais preservados.

As duas habilidades adicionais recebem somente apresentação: não entram na tabela de atraso de dano SwordTechniqueTiming. O explorador principal e as artes existentes permanecem. A revisão offline expõe as cinco técnicas além do Talho Ágil, que conserva seu fluxo próprio de Skill 1. O enquadramento da Ruptura acomoda seu alcance completo.

## Verificação

- Renderização/combate Kamusari e efeitos inteiros: 570 verificações, zero falhas. A passagem é medida isoladamente, sem confundir o perímetro circular com o avanço da lâmina. Avanço visual medido de aproximadamente 35 px entre as amostras nas quatro direções.
- Revisão offline: 237 verificações, zero falhas; contato e passagem capturados nas quatro direções das cinco técnicas.
- Refinamento de combate: 516 verificações, zero falhas.
- Regressões de combate: 281 verificações, zero falhas.
- Identidade do explorador: 72 verificações, zero falhas.
- Skill 1 no jogo: 284 verificações, zero falhas.
- 24 quadros de Kamusari capturados no jogo principal; captura direita de execução inspecionada.

Total: 1.960 verificações sem falhas. Logs finais em `outputs/ARVEON/Registros/espada-final-*` e `espada-revisao-*`, capturas em `Revisoes/refinamento-local/espada-*` e `Revisoes/kamusari-local/passagem-restaurada` fora do repositório. Sem export Web, publicação ou teste em telefone físico. Alteração preexistente em project.godot preservada e excluída do commit.
