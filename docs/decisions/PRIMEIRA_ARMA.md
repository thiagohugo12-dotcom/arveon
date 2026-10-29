# O Primeiro Passo — aprovado em 13/10/2026

Status: APROVADO pelo pedido explícito de Thiago neste dia.

Somente personagens sem save iniciam desarmados no acampamento. A missão
introduz o Ferreiro e permite comparar espada, machado, lança, arco e cajado.
Confirmar concede uma arma +0, equipa sua categoria e conclui a missão, sem
XP, ouro ou itens extras. A escolha gratuita é única e não restringe classes.
Missões comuns e desafios ficam pausados durante a introdução.

Os mesmos cinco IDs e atributos são reutilizados; os nomes exibidos passam
a Espada/Machado/Lança/Arco/Cajado Inicial. Receitas e upgrades existentes
permanecem. Como a espada antes só era concedida no início, sua fabricação
posterior custa provisoriamente 30 ouro, 3 Madeira e 2 Pedras, na faixa das
receitas atuais. Nenhuma arma adicional é entregue gratuitamente.

Save v11 acrescenta estado obrigatório de introdução (active/complete/legacy),
visita ao Ferreiro e ID escolhido. v1–10 são integralmente validados e isentos;
nenhuma análise de nível ou equipamento força um antigo jogador à introdução.
O original v10 é preservado pelo backup existente. O bump protege contra
clientes anteriores, que poderiam ignorar e descartar o resgate único.

A confirmação grava recompensa e conclusão juntas no journal/disco atual.
Falha de gravação reverte a concessão em memória. A UI não concede itens;
a regra valida estado, visita, categoria e presença física no Ferreiro.
Seleção não confirmada não é recompensa e pode ser refeita ao abrir/carregar.

Sem mudança de main, produção, cinco andares, arte, progressão ou balanceamento
de combate. Testes físicos Android/iPhone continuam a depender de aparelho.
