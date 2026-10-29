# Repositório GitHub do ARVÉON

O repositório existente é `thiagohugo12-dotcom/arveon`:
https://github.com/thiagohugo12-dotcom/arveon. Ele já contém o histórico do
projeto; não crie outro repositório nem envie alterações para `main`.

## Clonar

```powershell
git clone https://github.com/thiagohugo12-dotcom/arveon.git C:\Projetos\arveon
Set-Location C:\Projetos\arveon
git switch --track origin/dev/arveon-solo-10-andares
```

O endereço antigo do repositório redireciona para o novo nome. O checkout local
da versão atual já usa o remote `https://github.com/thiagohugo12-dotcom/arveon.git`.

## Fluxo de trabalho

Use `dev/arveon-solo-10-andares` para o desenvolvimento atual. Atualize a branch
com `git pull --ff-only`, valide as mudanças e envie somente para essa branch.
Não mescle em `main` nem publique na produção sem autorização explícita.

O workflow Web pode gerar builds de Preview para verificações. Endereços atuais:

- TESTE: https://arveon-teste.vercel.app/
- PRODUÇÃO: https://arveon.vercel.app/

Os dois domínios antigos continuam ativos. Como o armazenamento Web é separado
por domínio, saves existentes continuam disponíveis no endereço antigo; para
migrá-los, exporte um backup no jogo e importe-o no novo endereço.
