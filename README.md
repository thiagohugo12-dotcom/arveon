# Grande Árvore RPG
Fundação Godot 4.5.1 + GDScript, 2D Compatibility. Apenas **Andar 1 — Mata dos Primeiros Passos**.

## Abrir no Windows
1. Instale/extraia **Godot 4.5.1 Standard** (não .NET): https://godotengine.org/download/archive/4.5.1-stable/.
2. Clone o repositório ou extraia este projeto em `C:\Projetos\grande-arvore-rpg`.
3. No Project Manager: **Importar → project.godot → Importar e editar**.
4. Espere a importação e pressione **F6** para a cena aberta ou **F5** para o projeto.
5. WASD/setas movem; **Shift ou Espaço** fazem Dash. Ataque é automático. Joystick e Dash também funcionam com mouse. Para multitouch, teste num celular.
6. Redimensione a janela para retrato e paisagem; Dash permanece à direita. Ao morrer, use Reiniciar.

## Verificação sem interface
Substitua `godot` pelo caminho do executável (no Windows use o executável `_console.exe`).
```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --quit-after 120
```

## Export Web
Editor: **Editor → Gerenciar modelos de exportação → Baixar e instalar** para a mesma versão.
**Projeto → Exportar → Web → Exportar projeto** para `build/web/index.html` (crie a pasta). Não abra por `file://`: sirva por HTTP.
```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python -m http.server 8000 --directory build/web
```
Abra http://localhost:8000. Celular: mesma rede, `http://IP_DO_PC:8000`, permitindo acesso local no firewall. WebGL 2.0 é necessário. Export sem threads não exige isolamento COOP/COEP. Windows pode executar no editor; export nativo/Android/iOS serão configurados depois, sem certificados inventados.

## CI
`.github/workflows/web.yml` importa, testa e exporta Web com Godot 4.5.1 e templates correspondentes; guarda artifact `andar-1-web` por 14 dias. Não publica site ou Pages. Após push, veja Actions → Web build. Publicação requer escolha de hospedagem/visibilidade; não há segredos no projeto.

## GitHub e histórico
O ZIP contém `grande-arvore-rpg-history.bundle` com commits e checkpoint. Para recuperar o Git e criar o repositório privado, siga `docs/GITHUB_SETUP.md`. Nenhum remoto foi criado nesta sessão.

## Contratos
`AGENTS.md`, `docs/design/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/QA_CHECKLIST.md` e `docs/VALIDATION.md`.
Slots Skill 1/2, Ultimate e poção são reservas desabilitadas. Assets geométricos provisórios. IA simples sem desvio de obstáculos. Nenhum Andar 2.
