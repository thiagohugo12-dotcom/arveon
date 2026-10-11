# Grande Árvore RPG
Fundação Godot 4.5.1 + GDScript, 2D Compatibility. **v0.6.0: cinco andares jogáveis reutilizando a Mata dos Primeiros Passos**, com dificuldade configurável.

## Abrir no Windows
1. Instale/extraia **Godot 4.5.1 Standard** (não .NET): https://godotengine.org/download/archive/4.5.1-stable/.
2. Clone o repositório ou extraia este projeto em `C:\Projetos\grande-arvore-rpg`.
3. No Project Manager: **Importar → project.godot → Importar e editar**.
4. Espere a importação e pressione **F6** para a cena aberta ou **F5** para o projeto.
5. WASD/setas movem; **Shift ou Espaço** fazem Dash. Ataque é automático. **1/2/3** ativam Corte Circular, Investida e Fúria; **C** abre Personagem, **M** abre Mapa e **Esc** fecha os painéis. Joystick e Dash também funcionam com mouse. Para multitouch, teste num celular.
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

## v0.3.0 — O Despertar do Aventureiro
C/toque em Personagem: nível, atributos e pontos. 1/Corte Circular,
2/Investida, 3/Fúria Ancestral. Habilidades são manuais; não funcionam no
acampamento ou em menus. Mochila mostra equipamentos; o Ferreiro fabrica
sete receitas e aprimora até +3 usando ouro e materiais da mochila.

Elite aparece após a fase inicial. O altar no nordeste permite desafiar o
Guardião das Raízes sem exigência de nível; interaja com E/toque. Desvie dos
avisos dourados. É opcional; missões adicionais e vitória persistem sem
repetir recompensas. Save v5 migra v1–4, preservando os atributos existentes.
Poção e proficiência ainda não estão implementadas. Valores são provisórios.

## CI e ambientes
Actions importa, executa testes, renderiza 182 capturas de QA e exporta Web. O PR da branch
`feat/andar1-v020-primeiro-passe` publica o build validado em Preview e atualiza
TESTE: https://grande-arvore-rpg-teste.vercel.app/.
PRODUÇÃO: https://grande-arvore-rpg.vercel.app/ — não alterada por esta versão.
Não fazer merge em main ou publicar em produção sem autorização de Thiago.

## Contratos
`AGENTS.md`, `docs/design/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/QA_CHECKLIST.md` e `docs/VALIDATION.md`.
Corte, Investida e Fúria estão ativos; poção permanece desabilitada. IA simples sem desvio de obstáculos. Os cinco andares usam o mesmo cenário e mantêm progresso próprio.

## v0.3.2 — Renovação Visual
Atlas pixel art autorais para solo, árvores e quatro atores, gerados de forma
reprodutível em `tools/`. Caminhos, área segura, pedras e construções receberam
detalhes visuais sem alterar suas colisões. Personagem, Habilidades, Mochila e
Ferreiro usam cartões e ícones; combate ganhou efeitos curtos de pixels. A câmera,
regras, receitas e saves v5 permanecem compatíveis. Veja
`docs/iterations/V0.3.2_RENOVACAO_VISUAL.md` para evidências e limites.


## v0.6.0 — A Ascensão dos Cinco Andares
Torre no extremo leste, (1130,455): E/Interagir abre a seleção mesmo antes
dos 50 abates. Viaje aos destinos disponíveis; os bloqueados mostram seu estado.
Cada andar exige 50 derrotas próprias antes de Entrar na Prova. Complete as
hordas 4/6/6 e o Guardião existente para desbloquear o seguinte. Morreu,
abandonou ou fechou o jogo: tentativa encerrada, sem checkpoints. A quinta
vitória registra a campanha inicial, sem Andar 6 ou declaração de versão 1.0.

HP/dano: 1,00/1,20/1,40/1,60/1,80; XP/ouro: 1,00/1,10/1,20/1,30/1,40.
Uma única Mata ativa, mesmas dimensões, Torre, arte e serviços. Save v6
preserva personagem global, exploração por andar e migra a vitória antiga
com seu Selo da Mata e Andar 2 liberado. Backup na Mochila → Registro.
Veja `docs/iterations/V0.6.0_CINCO_ANDARES.md` para validação e limitações.
