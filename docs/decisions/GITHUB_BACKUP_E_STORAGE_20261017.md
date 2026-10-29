# Backup no GitHub e armazenamento de Actions

Autorização: Thiago pediu enviar o projeto e limpar o GitHub após alerta de 100% do armazenamento de Actions, em 17/10/2026.

## Diagnóstico e escopo

O repositório Git local ocupa aproximadamente 29 MiB em objetos. Actions tinha 369 artefatos: 3.968,35 MiB, principalmente exportações Web e capturas de QA repetidas. Nenhum cache de Actions foi encontrado.

A limpeza preserva os sete artefatos das últimas execuções bem-sucedidas de produção (37803860044) e teste (38947447542). Remove somente 362 artefatos gerados anteriores, dos seis nomes conhecidos do workflow. Mantém código-fonte, commits, tags, branches, releases, sites e execuções. O plano, inventários antes/depois e cada exclusão são registrados fora do Git em `outputs/ARVEON/Registros/github-limpeza-20261017`.

## Prevenção e backup

- Retenção central do repositório reduzida de 90 para 1 dia para novos artefatos/logs. A biblioteca oficial de upload limita a retenção solicitada ao limite configurado no repositório; isso também cobre workflows antigos que solicitavam 14 dias.
- Workflow desta branch solicita explicitamente 1 dia para os seis uploads.
- Versão atual enviada à branch `refine/combat-local-20261017`, sem merge em main. O workflow dispara em push somente em main; não é preciso criar uma execução para salvar fontes no GitHub.
- Atalhos portáveis `Jogar.bat` e `Revisar animacoes.bat` adicionados à raiz. Primeira abertura importa recursos localmente; `ARVEON_GODOT` permite apontar para outro executável.
- Incluídos os metadados de recursos (.uid/.import), análise histórica e configuração normalizada pelo editor. Cache `.godot`, logs, exports e imagens de evidência externos continuam fora do Git. Lockfile npm vazio sem package.json movido para o registro local.

Arquivos já armazenados conservam seu prazo anterior; a limpeza explícita libera o espaço atual. Uso faturado é acumulado ao longo do ciclo: excluir arquivos não apaga consumo já contabilizado. O painel pode continuar mostrando consumo do ciclo mesmo após reduzir o armazenamento atual.

Fontes: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts ; https://docs.github.com/en/billing/concepts/product-billing/github-actions ; https://docs.github.com/en/rest/actions/permissions ; https://github.com/actions/toolkit/blob/main/packages/artifact/src/internal/upload/retention.ts
