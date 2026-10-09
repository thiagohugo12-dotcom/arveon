# Validação — 07/10/2026
Engine real: **Godot 4.5.1.stable.official.f62fdbde1**, Linux x86_64, headless.

## Executado e aprovado
- Importação limpa via `--headless --editor --import`: classes, Resources, cenas e scripts sem SCRIPT ERROR/ERROR.
- Cena principal via `--headless --quit-after 120`: sem erros de runtime. 120 frames é smoke test, não medição de tempo ou FPS.
- Runner `tests/run_tests.gd`: **30 verificações, 0 falhas**. HP/morte única; direção e cooldown do dash; teclado diagonal e oito vetores; alcance exato; alvo vivo mais próximo; dano/cooldown automático; exclusão imediata de morto; linha de visão bloqueada por parede; colisão durante dash; HUD retrato/paisagem; touch simultâneo simulado; soltura e perda de foco; UI de morte.
- Layout lógico exercitado em 360×640 e 640×360. São testes de geometria, não inspeção visual.
- Referências `res://` de scripts/cenas/Resources presentes e YAML do workflow parseável.
- Exportação release **Web sem threads**, com templates oficiais correspondentes: index.html, index.js, index.wasm, index.pck e auxiliares gerados sem erros.
- Pacote exportado carregado pelo Godot Linux headless por 120 frames, sem erros. Isso verifica o conteúdo do pack; não equivale a executar o WASM num navegador.
- Arquivos de fonte e `.gd.uid` versionados; `.godot/`, builds e credenciais excluídos.

## Limites e pendências
- Não foi possível instalar o navegador neste ambiente (download bloqueado); sem teste de WebGL/WASM no navegador e sem inspeção gráfica.
- Sem aparelho Android/iPhone real: multitouch, orientação, safe area, foco e legibilidade devem ser confirmados no dispositivo.
- Sem execução do editor gráfico Windows ou exportação Windows/Android/iOS. Projeto configurado para Compatibility; SDKs/certificados nativos não foram adicionados.
- Sem medição de FPS, consumo, bateria, tempo de carregamento ou performance em celular modesto.
- Workflow GitHub preparado e passos principais exercitados localmente; **não executado no GitHub**.
- Conta GitHub confirmada; integração não oferece criação de repositório. **Nenhum repositório privado remoto foi criado e nenhum push foi feito.** Instruções em `GITHUB_SETUP.md`.

## Checkpoint
Commits pequenos de fundação, gameplay e testes/CI preservados. Tag `checkpoint-andar1-v0.1.0` identifica a entrega. Bundle transporta todo o histórico e permite restaurar o Git sem depender da pasta de cache. Nenhum Andar 2 implementado.

## Conferência humana
Siga `QA_CHECKLIST.md` e README. Só marcar aprovação de navegador/celular após executar no dispositivo e registrar modelo, plataforma, versão e resultado.
