# Interface da Espada no Diário — 15/10/2026

Status: APROVADO. Thiago solicitou “Vamos colocar a nova interface”, após
selecionar a referência 77175.png: pergaminho claro, moldura de madeira,
ícones pixel art em quadros, faixas de proficiência e conexões simples.

Esta entrega substitui os botões textuais de SwordEvolutionTree por nós
com ícones já existentes no atlas do diário. Mantém os 20 marcos reais,
IDs, níveis, custos, requisitos, efeitos, slots e transações do primeiro passe
2bfb6b4. As colunas apresentam ofensiva e defesa; nós inicial e final ficam
centralizados. Linhas indicam percurso de leitura, não novos pré-requisitos.
Os pré-requisitos reais continuam em AbilityRules e nos detalhes do talento.

Disponibilidade, aquisição e equipamento são estados distintos. Talentos sem
pai aprendido ou pontos continuam bloqueados; bloqueados podem ser inspecionados.
Toque abre o detalhe existente; um botão retorna ao nó selecionado. O handler
existente de toque/arrasto do HUD é mantido. Ícones têm alvo de 60 px; o diário
rola verticalmente e mantém fechar fora do conteúdo rolável. Um botão de
redistribuição longo foi dividido em duas linhas para caber em retrato.

Nenhum PNG novo, imagem gerada, dependência, processo por quadro, regra de
combate, formato de save ou dado de personagem foi introduzido. Save v11,
outras armas, mapas, main e PRODUÇÃO permanecem preservados. O checkpoint
checkpoint-antes-interface-espada-diario-2026-10-15 aponta para 2bfb6b4.

QA focado usa os handlers reais de toque do HUD em 360×800, 390×844,
844×390 e 1366×768: seleção bloqueada sem mutação do snapshot, arrasto sem
seleção, retorno ao marco, largura dos cartões, alvos de toque e fechar.
O mesmo teste produz capturas reais com Godot/Compatibility em software GL
no CI. Publicar exclusivamente no TESTE após a suíte e exportação Web.

Balanceamento, moeda de Treinamento, novos efeitos e expansão das árvores das
outras armas continuam fora desta alteração visual.
