# Contrato do projeto
Leia `docs/design/GAME_DESIGN.md`, `docs/ARCHITECTURE.md` e seu papel em `agents/` antes de alterar código.

## Autoridade
- Thiago é o dono das decisões de Game Design. Nenhum agente altera silenciosamente decisões estruturais.
- Proposta estrutural vira documento em `docs/decisions/` com status PROPOSTA. Não implementá-la até aprovação explícita do usuário. Atualizar o Game Design e registrar a aprovação antes da implementação.
- Melhorias técnicas dentro do contrato existente são permitidas. Balanceamento provisório deve ser identificado e documentado.
- Não deduzir sistemas, classes, narrativa ou progressão a partir do nome do jogo. Não avançar ao Andar 2.
- Evitar arte final, plugins, backend, autoloads globais e dependências sem necessidade comprovada.

## Entrega
Commits pequenos por unidade verificável, sem force push, sem apagar tags ou checkpoints. Validar com Godot headless, testes, export Web e teste humano quando disponíveis. Informar o que não foi testado. Segredos nunca são versionados.

## Papéis separados
`agents/director.md`, `programmer.md`, `visual.md`, `game-designer.md`, `data-backend.md`, `qa.md`.
Estes arquivos são contratos de trabalho, não agentes autônomos em execução.
