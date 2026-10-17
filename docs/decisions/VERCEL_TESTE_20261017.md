# Publicação do refinamento no TESTE Vercel

Thiago autorizou publicar a versão atual na Vercel em 17/10/2026. Destino: projeto `grande-arvore-rpg` (`prj_gYKlx91MiswTmwj2PLiN5liQD0B7`), equipe `team_6XRzZ5HN4AOw2hWyIpf8McMU`, ambiente Preview e alias público existente `grande-arvore-rpg-teste.vercel.app`. Sem merge em main ou promoção para produção.

Pacote Web gerado localmente com Godot 4.5.1 `--export-pack Web`. O runtime Web já publicado no TESTE (index.js/index.wasm de Godot 4.5.1, sem threads/extensões) é reutilizado; todas as fontes, recursos e shaders do jogo vêm do PCK recém-exportado. Tamanho do PCK atualizado na configuração HTML. Arte de carregamento aprovada reinjetada com conferência por hash. Entradas de demonstrações existentes preservadas e `/revisao-combate/` acrescentada para espada e Guardião.

Antes do envio: 25 verificações de carregamento estático e 35 verificações em Chromium, zero falhas, incluindo carregamento real de Godot, quatro dimensões de tela, ausência de erros de script e persistência de save v11 após recarregar. Publicação por CLI autenticada no mesmo projeto, após falha 403 do conector Vercel. Sem criação de artefatos ou execuções no GitHub Actions.

Registros da publicação e verificação pública em `outputs/ARVEON/Registros/vercel-*`, fora do Git. O alias TESTE só será apontado para um Preview READY do projeto correto; conferir hashes do PCK publicado e carregar a página real. Em falha, restaurar o alias anterior `dpl_B44ccim1pQZpRDt4aZxCKpXFmVzd`.
