# ADR — Registro local do Aventureiro

Status: APROVADA
Data: 10/10/2026. Aprovação: pedido explícito v0.5.1.1 de Thiago.

Preservar schema v6 e regras de jogo. Caminho Web estável, migração validada
das pastas de versões anteriores sem remover originais; gravação temporária
verificada antes de substituir, com cópia anterior válida e proteção contra
sobrescrever saves inválidos/futuros. Eventos importantes continuam salvando;
verificação a cada 30s e ao ocultar página só escreve mudanças.

IndexedDB do Godot permanece. Journal síncrono localStorage cobre fechamento
antes do sync assíncrono e detecta conflitos entre abas por compare-and-swap.
Backup exportado com SHA-256 e validação de schema; importação somente após
confirmação explícita, preservando a versão substituída. Estado da Torre não
é serializado. Importar recarrega na Mata, sem recompensas/checkpoints novos.

Menu discreto Registro na Mochila, ações de 44px e bloqueio modal existente.
Não há conta, servidor, sincronização remota, novo balanceamento ou dependência.
