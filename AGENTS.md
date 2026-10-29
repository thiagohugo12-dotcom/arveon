# Contrato do projeto
Leia `docs/design/GAME_DESIGN.md`, `docs/ARCHITECTURE.md` e seu papel em `agents/` antes de alterar código.

## Autoridade
- Thiago é o dono das decisões de Game Design. Nenhum agente altera silenciosamente decisões estruturais.
- Proposta estrutural vira documento em `docs/decisions/` com status PROPOSTA. Não implementá-la até aprovação explícita do usuário. Atualizar o Game Design e registrar a aprovação antes da implementação.
- Melhorias técnicas dentro do contrato existente são permitidas. Balanceamento provisório deve ser identificado e documentado.
- Não deduzir sistemas, classes, narrativa ou progressão a partir do nome do jogo. Os Andares 1 e 2 já existem; preservar sua implementação. Os Andares 3 a 10 estão na fase de planejamento e exigem escopo aprovado antes de implementação.
- Evitar arte final, plugins, backend, autoloads globais e dependências sem necessidade comprovada.

## Fluxo seguro de desenvolvimento (2026-10-22)
- Base: Alpha Web da branch `release/alpha-0.2-web-20261020`; a `main` contém uma versão anterior.
- Trabalhar na branch `dev/arveon-solo-10-andares` ou em branches curtas derivadas dela. Não mesclar, forçar push ou atualizar `main` sem aprovação explícita.
- Não publicar nem promover Vercel PRODUÇÃO. TESTE só quando solicitado, e nunca assumir que publicar GDScript atualiza um export Web sem novo `.pck`.
- Projeto local pode conter alterações além do GitHub: conferir antes de sincronizar. Nunca sobrescrever trabalho local mais recente.
- Primeiro executar verificações direcionadas, com timeout, e reportar resultados e limitações. Suíte completa, capturas extensas e exports apenas quando fizerem sentido ou forem pedidos.
- O workflow legado contém deploy automático em push na `main`: não acionar essa rota para validar branches de desenvolvimento.

## Entrega
Commits pequenos por unidade verificável, sem force push, sem apagar tags ou checkpoints. Validar com Godot headless, testes, export Web e teste humano quando disponíveis. Informar o que não foi testado. Segredos nunca são versionados.

## Papéis separados
`agents/director.md`, `programmer.md`, `visual.md`, `game-designer.md`, `data-backend.md`, `qa.md`.
Estes arquivos são contratos de trabalho, não agentes autônomos em execução.
