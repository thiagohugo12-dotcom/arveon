# ARVÉON — exportação Web

As exportações Web são geradas localmente com Godot 4.5.1 e publicadas diretamente no projeto Vercel `arveon`. O diretório `build/` é ignorado pelo Git e contém as exportações temporárias. O `export_presets.cfg` exclui `build/*` e `releases/*` do pacote do jogo.

A exportação Alpha 0.2 de 20/10/2026 foi retirada desta branch após a publicação de uma versão mais recente. Ela continua recuperável no histórico do Git e nos deployments anteriores da Vercel.

Endereços: TESTE `https://arveon-teste.vercel.app/`; PROD `https://arveon.vercel.app/`. Saves são separados por domínio; para migrá-los, exporte um backup dentro do jogo e importe-o no outro endereço.
