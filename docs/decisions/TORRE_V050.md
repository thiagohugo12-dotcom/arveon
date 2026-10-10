# ADR: entrada da Torre de Ascensão

Status: APROVADA
Autor / data: Thiago Ferreira / 10/10/2026
Aprovação explícita: pedido «v0.5.0: O Chamado da Torre» nesta conversa.

A Torre é uma prova de combate e futuro acesso entre andares conquistados.
Nesta etapa só haverá entrada, requisito de 50 derrotas reais do Andar 1,
contador persistente limitado a 50 e apresentação da prova futura (três hordas
e Guardião da Mata; morrer reinicia a primeira horda). Não há arena, hordas,
novo Guardião, seleção de andares, teletransporte ou liberação do Andar 2.
O Guardião opcional existente permanece independente da Torre.

Reutilizar interação e painel dos serviços, bloqueando movimento/ataques como
nos menus existentes. Progresso contextual perto da entrada, sem novo HUD fixo.
Save v6 adiciona estado de ascensão; v1–5 preservam dados e aproveitam `kills`
(todos oriundos do Andar 1 no jogo existente), limitado a 50. Morte não retira
esse progresso. Contagem integrada ao sinal de derrota, com origem e estado
de morte validados e proteção contra repetição por criatura.

Validar migração, persistência, limites, derrotas, morte, UI touch e regressões;
importar/exportar com Godot 4.5.1 e publicar somente no Preview de TESTE.
Rollback: retornar ao checkpoint anterior; v6 requer a versão atual para ler
o novo bloco. A migração não altera XP, ouro, recompensas ou atributos.
