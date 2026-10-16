# Clareza dos menus mobile — 15/10/2026

Status: APROVADO pelo pedido de Thiago para ajustar as telas das capturas
77203.jpg, 77201.jpg, 77205.jpg e 77199.jpg.

Problemas observados: serviços limitados a 320 px de altura, ações abaixo do
primeiro cartão, números de proficiência/pontos sem legenda, cabeçalhos
repetidos e catálogo completo de técnicas/passivas/estilos em uma única lista.

Ferreiro e Vendedor passam a aproveitar até 620 px de altura disponível, com
Fechar fixo. Loja apresenta nome/classe, estado de posse e preço em cartões
compactos; detalhes de combate ficam antes da confirmação. Venda mostra
quantidade na mochila, uma unidade por ação e o valor em ouro no botão.
Recursos que não podem ser comprados não exibem Comprar desativado.
Receitas, preços, fabricação, upgrades e compra única não mudam.

Habilidades mantém as configurações existentes, dividindo a consulta em
Técnicas, Passivas e Estilo. A lista mostra estado/requisito e o detalhe da
seleção contém as ações originais, custos e espaços configuráveis. Os catálogos
completos e a redistribuição permanecem acessíveis. Selecionar não equipa,
compra ou gasta pontos. Trocar, limpar e melhorar mantêm as mesmas transações.

Treinamento identifica pontos da arma, investimento, percentual atual e próximo
valor. Seletores de categoria usam ícones sem o número ambíguo “12 · +6”.
Pontos de talento continuam separados e identificados na Árvore e no detalhe
de melhoria. Nenhuma moeda é unificada; caps e efeitos permanecem iguais.

Botões no conteúdo rolável dos serviços e do diário ativam ao soltar, após
descartar arrasto acima de 8 px. Esse comportamento evita comprar, vender ou
selecionar acidentalmente ao rolar a lista. Cabeçalho/Fechar ficam acessíveis.

QA focado: quatro viewports (360×640, 390×700, 844×390 e 1366×768), toque nos
handlers reais, compra sob confirmação, venda com preço explícito, arrasto sem
transação, consulta sem mutação do snapshot v11, slots, especialização e
investimento esperado. Capturas reais em Godot/Compatibility e inspeção visual
precedem a entrega. As regressões existentes de progressão, loja e saves são
mantidas e adaptadas para percorrer as novas seleções.

Somente apresentação/interação; sem alteração de regras, economia, combate,
progressão, save v11, main ou PRODUÇÃO. Checkpoint em b6001df:
checkpoint-antes-ux-servicos-diario-2026-10-15.
