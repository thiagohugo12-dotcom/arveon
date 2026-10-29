# ADR: três hordas jogáveis na Torre

Status: APROVADA
Autor / data: Thiago Ferreira / 10/10/2026
Aprovação explícita: pedido «v0.5.1: As Hordas da Torre» nesta conversa.

A entrada leste e o mapa da Mata permanecem intactos. Após 50 derrotas,
Entrar na Prova transfere o protagonista existente a uma arena separada.
Hordas: 4 comuns; 6 comuns; 5 comuns e 1 elite. Intervalo de quatro segundos,
com movimento e uma recuperação de 15% de HP máximo entre as hordas.
Inimigos conservam suas variantes, estatísticas e recompensas existentes.
Só mortes reais registradas uma vez avançam; remoção não vale derrota.
Limite de seis criaturas nesta arena, cinco na Mata. Sem chefe novo.

Tentativa temporária, sem checkpoints ou serialização. Carregar qualquer save
volta à Mata pelo fluxo existente; requisito e recompensas já salvas permanecem.
Morte aplica a perda normal uma vez e retorna ao acampamento com o HP do
reinício normal. Abandono/retorno voluntário preserva HP e não aplica perda.
Saída identificada na arena permite abandonar pela interação, inclusive nos
intervalos. Após a terceira horda, o painel oferece retorno e informa o futuro
Guardião; não cura outra vez, conclui ascensão, concede selo ou desbloqueia piso.

Sem Guardião da Torre, Andar 2, v0.5.2, alteração global de balanceamento,
arte nova obrigatória, dependência, main ou produção.
