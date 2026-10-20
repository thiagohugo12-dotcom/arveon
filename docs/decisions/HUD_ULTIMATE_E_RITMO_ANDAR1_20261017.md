# HUD de Ultimate e ritmo do Andar 1

Status: APROVADA

Autor / data: Thiago e Codex · 17/10/2026

Decisão vigente: o HUD mostra três espaços de habilidade permanentes. A Ultimate
ocupava um desses espaços e permanecia visível durante todo o combate. A missão
mostrava missão atual e desafio seguinte na mesma área.

Problema e evidências: a missão ocupa espaço demais na tela mobile; a Ultimate
compete visualmente com técnicas normais mesmo quando ainda não pode ser usada;
os encontros e objetos do acampamento precisam de revisão de leitura e colisão.

Proposta: o HUD exibirá somente o objetivo atual em uma faixa compacta. Skill 1,
Skill 2 e Skill 3 continuam visíveis. A Ultimate terá botão próprio, oculto até
atingir 100% de carga. A configuração de Ultimate deixa de ocupar Skill 2 ou 3;
as técnicas normais mantêm esses dois espaços. O passe do Andar 1 ajusta somente
posições de encontro, obstáculos visíveis e apresentação do Guardião. Não muda
dano, recarga, recompensa, requisitos, economia, saves ou progressão.

Impacto no Game Design, desempenho, compatibilidade e saves: save v11 preserva
loadouts existentes. Uma Ultimate previamente equipada migra para o novo espaço
de Ultimate da mesma arma; o espaço liberado fica vazio. Sem dependências e sem
alterar o Andar 2.

Aprovação explícita do dono (referência/data): pedido de Thiago em 17/10/2026:
“3 slots de skills para skills normais e um invisível para ultimate, onde o da
ultimate só aparece quando tiver 100% pronta para usar”; também autorizou revisar
distribuição dos encontros e hitboxes, citando a fogueira.

Plano de validação e rollback: testes de estado, touch e save cobrem migração,
três skills normais, Ultimate oculta/pronta e colisões do acampamento. Reverter
os arquivos do passe local restaura o HUD e o posicionamento anterior.
