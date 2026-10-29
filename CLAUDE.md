# ARVÉON — instruções para Claude Code

Leia `AGENTS.md` e os documentos de design/arquitetura antes de alterar código.

- Repositório Godot 4.5.1 Standard, GDScript, Compatibility, 2D e mobile-first vertical, com export Web.
- A branch de trabalho aprovada para preparação é `dev/arveon-solo-10-andares`, derivada da Alpha Web. A `main` contém uma versão antiga; nunca substitua a Alpha por ela.
- Dois andares existem. O plano solo de 10 andares e farm exigente está em definição; não implementar os Andares 3–10 antes de receber tarefas específicas.
- Nunca enviar alterações à `main`, executar merge ou publicar na Vercel PRODUÇÃO sem aprovação explícita.
- Evitar testes longos, screenshots e exports redundantes. Começar com inspeção pontual, import headless e testes relacionados à alteração, sempre com limites de tempo.
- Não importar cegamente a branch antiga `fix/alpha02-npcs-colisao-torres-20261021`; conferir primeiro se a Alpha mais nova já incluiu correções equivalentes.
- Ao terminar, informar branch, commit, arquivos alterados, comandos executados, resultados verificados e pendências. Não dizer que testou algo que não executou.
