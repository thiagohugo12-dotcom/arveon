# ARVÉON — publicação Web Alpha 0.2

`alpha-0.2-web/` é a exportação estática gerada da pasta local deste projeto em 20/10/2026. Esta é a pasta publicada no projeto Vercel `arveon`, sem depender de um build remoto do código Godot.

Para gerar a próxima versão, execute a exportação Web Godot 4.5.1 para um novo diretório em `releases/`. Copie `vercel.json` e confira o comportamento do service worker antes de publicar. O `export_presets.cfg` exclui `releases/*` do pacote para evitar incluir exportações anteriores no jogo.

Validação local desta revisão: inicialização Web em 390 × 844, Novo jogo, salvamento, recarga, abas Mochila/Habilidades/Proficiências, interações da área segura, viagem entre Andares 1 e 2, e prova da Torre do Andar 2. Os testes de toque foram executados na Godot e as abas principais foram abertas também no navegador.

O serviço de PWA atualiza a página inicial pela rede quando conectado e mantém o cache para uso sem rede. Em dispositivos que já visitaram a versão anterior, a primeira atualização pode exigir abrir o endereço com `?v=20261020` ou atualizar a página uma vez para abandonar o cache antigo.

Endereços atuais: TESTE `https://arveon-teste.vercel.app/`; PROD `https://arveon.vercel.app/`. Os aliases antigos continuam ativos para preservar favoritos e links compartilhados.

O navegador mantém saves separados por domínio. Saves criados no endereço antigo permanecem lá; para migrar, exporte o backup no jogo e importe-o ao abrir o novo endereço.
