# Layout dos quatro menus — 15/10/2026

Status: APROVADO. Thiago aprovou a prancha de Ferreiro, Vendedor,
Habilidades e Treinamento com o pedido “pronto, aplique isso”.

Aplicar a composição aprovada com os recursos existentes do diário:
papel claro, moldura de madeira, seleção verde, cabeçalho curto e saída fixa.
Não usar a prancha como imagem de fundo: os elementos são controles reais.

Ferreiro: cinco armas em grade de duas colunas; selecionar abre resumo de
classe/estilo/dano/alcance/cadência, depois Comprar abre confirmação.
Selecionar/voltar não altera inventário nem carteira. Forja continua acessível.
Preços são os da economia vigente, não valores ilustrativos da prancha.

Vendedor: abas Vender/Comprar; venda lista materiais possuídos e compra lista
somente materiais comercializados. Ícone, quantidade e transação de uma unidade
em cada linha. Rolagem preserva acesso ao catálogo completo, sem venda em lote.

Habilidades: título direto, cinco categorias, três cartões dos espaços atuais,
catálogo Técnicas/Passivas/Estilo e detalhe da seleção. As duas ações de equipar
continuam explícitas; o espaço vazio vem primeiro. Limpar/redistribuir ficam em
Mais opções. Retorno ao diário mantém Personagem, Mochila e Árvores acessíveis.

Treinamento: saldo da arma destacado, quatro cartões com ícone, valor atual,
próximo valor e investimento, ação +1 à direita. Redistribuição e acesso à Árvore
permanecem disponíveis. Não confundir pontos da arma com pontos de talento.

Telas curtas usam rolagem; cabeçalhos e saídas ficam fora dela. Botões mantêm
44 px mínimos. Preservar toque ao soltar e cancelamento de arrastos existentes.
Os ícones são os atlas já aprovados, sem novas artes ou dependências.

Sem alteração de mecânicas, classes, preços, efeitos, limites, missões ou save
v11. main e PRODUÇÃO protegidos. Checkpoint em 80f4c5d:
checkpoint-antes-layout-aprovado-2026-10-15.

QA: seleção/comparação/confirmar compra, compra e venda em abas separadas,
arrastar sem transação, espaços reais de habilidades, limites de treinamento,
consulta sem mutar snapshot v11; viewports 360×640, 390×844, 844×390 e 1366×768.
Capturas do Godot/Compatibility e regressões completas na CI antes da entrega.
