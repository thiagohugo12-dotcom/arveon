# Publicação do refinamento no TESTE Vercel

Thiago autorizou publicar a versão atual na Vercel em 17/10/2026. Destino: projeto `grande-arvore-rpg` (`prj_gYKlx91MiswTmwj2PLiN5liQD0B7`), equipe `team_6XRzZ5HN4AOw2hWyIpf8McMU`, ambiente Preview e alias público existente `grande-arvore-rpg-teste.vercel.app`. Sem merge em main ou promoção para produção.

Pacote Web gerado localmente com Godot 4.5.1 `--export-pack Web`. O runtime Web já publicado no TESTE (index.js/index.wasm de Godot 4.5.1, sem threads/extensões) é reutilizado; todas as fontes, recursos e shaders do jogo vêm do PCK recém-exportado. Tamanho do PCK atualizado na configuração HTML. Arte de carregamento aprovada reinjetada com conferência por hash. Entradas de demonstrações existentes preservadas e `/revisao-combate/` acrescentada para espada e Guardião.

Antes do envio: 25 verificações de carregamento estático e 35 verificações em Chromium, zero falhas, incluindo carregamento real de Godot, quatro dimensões de tela, ausência de erros de script e persistência de save v11 após recarregar. Publicação por CLI autenticada no mesmo projeto, após falha 403 do conector Vercel. Sem criação de artefatos ou execuções no GitHub Actions.

Registros da publicação e verificação pública em `outputs/ARVEON/Registros/vercel-*`, fora do Git. O alias TESTE só será apontado para um Preview READY do projeto correto; conferir hashes do PCK publicado e carregar a página real. Em falha, restaurar o alias anterior `dpl_B44ccim1pQZpRDt4aZxCKpXFmVzd`.

## Resultado confirmado

- Preview final READY: `dpl_2KqzcG4uRvkeYNCtpohLuufomtk3`, `https://grande-arvore-7bzwou6i4-thiago-74bf.vercel.app`.
- Código publicado: commit `3778d6706c91f1f6c4e18cdabb192261854636a9`. Este registro posterior não modifica o jogo.
- TESTE: https://grande-arvore-rpg-teste.vercel.app/ ; revisão: https://grande-arvore-rpg-teste.vercel.app/revisao-combate/ .
- Primeiro pacote apresentou dois worklets de áudio ausentes; alias anterior restaurado durante a correção. O pacote final acrescenta `index.audio.worklet.js` e `index.audio.position.worklet.js` das fontes oficiais da mesma versão Godot 4.5.1 (`platform/web/js/libs`), com licença original preservada. Splash padrão também incluído.
- Hashes públicos de PCK e dos dois worklets conferidos contra os arquivos locais. Manifesto público `arveon-release.json` identifica versão, tamanho e hashes.
- Carregamento público real: 35 verificações, zero falhas, incluindo save v11 e recarga. Revisão pública inicializada em Chromium, capturas desktop e móvel, sem erros de script nem exceções dos worklets. Versão 4.5.1 confirmada no console do motor.
- Produção e main preservados. Nenhum workflow do GitHub Actions acionado para esta publicação.
