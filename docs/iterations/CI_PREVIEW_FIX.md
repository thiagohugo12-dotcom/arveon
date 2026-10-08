# Correção CI e Preview — 08/10/2026

Branch: `feat/andar1-v020-primeiro-passe`. Base analisada: `cc0a5b8`.

## Diagnóstico

O job `113277322425` da execução `37767002731` passa por 37 verificações e encontra um erro de runtime em `tests/run_tests.gd`: acesso a `ActorData.max_health`, mas o contrato real usa `max_hp`. O erro interrompe a coroutine antes de `quit()`, deixando o SceneTree ativo. O timeout de shell limita a duração, mas não corrige a causa.

## Correção e proteção

- Teste usa `player.stats.max_hp`, preservando o contrato dos dados e todas as funcionalidades.
- Watchdog independente encerra o runner com código 1 após 15 segundos se ele não concluir.
- CI exige também a linha `RESULT: N checks, 0 failures` antes de exportar.
- Somente a branch de desenvolvimento autorizada atualiza o alias fixo `grande-arvore-rpg-teste.vercel.app`, após testes e exportação.
- Publicação Preview usa a credencial já configurada no GitHub, via variável de ambiente e escopo explícito.
- `main` não foi alterada. Nenhum deploy de produção foi solicitado.

## Validação local

- Godot 4.5.1.stable.official.f62fdbde1: importação limpa.
- Runner: 40 verificações, 0 falhas, código 0.
- Erro original injetado em cópia temporária: watchdog reduzido a 1 segundo para testar a proteção; código 1 após 37 verificações, com mensagem diagnóstica.
- Exportação Web release sem threads: HTML, JavaScript, WASM e PCK gerados; código 0.
- YAML do workflow parseável; diff sem erros de espaços.

Execução no navegador, publicação remota e teste humano no celular devem ser registrados separadamente após ocorrerem. Sem medição de FPS em dispositivo real.

## Endereços

- TESTE: `https://grande-arvore-rpg-teste.vercel.app` — alias configurado pelo job Preview após publicação bem-sucedida.
- PRODUÇÃO: `https://grande-arvore-rpg.vercel.app` — existente, não atualizado por este trabalho.

## Atualização concorrente preservada

Durante o trabalho, `16c2195` já corrigiu `max_hp` e adicionou watchdog de 15 segundos. Essas alterações foram preservadas. Nessa execução os testes/exportação passaram, o Preview ficou READY, mas o alias falhou com `User not found`: o comando de alias não informava o escopo da equipe. A correção complementar especifica o mesmo escopo na publicação e no alias.
