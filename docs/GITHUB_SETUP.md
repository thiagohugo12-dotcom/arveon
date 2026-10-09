# Criar o repositório privado e preservar o histórico
A conta GitHub conectada foi confirmada como `thiagohugo12-dotcom`. A integração desta sessão não possui operação de criação de repositórios; portanto nenhum repositório remoto foi criado, e nenhum workflow rodou no GitHub.

## Caminho recomendado no Windows (Git + GitHub CLI)
1. Instale Git e GitHub CLI oficial (`gh`): https://git-scm.com/download/win e https://cli.github.com/.
2. Extraia o ZIP entregue. Abra PowerShell na pasta que contém `grande-arvore-rpg-history.bundle`.
3. Restaure o projeto com todos os commits e tags para uma pasta nova (o destino não pode existir):
```powershell
git clone .\grande-arvore-rpg-history.bundle C:\Projetos\grande-arvore-rpg
Set-Location C:\Projetos\grande-arvore-rpg
git remote remove origin
```
O `origin` inicial é o bundle local, não um servidor. Abrir `project.godot` desta pasta no Godot.
4. Autentique sua própria conta e crie o repositório privado. Não cole token no chat:
```powershell
gh auth login --web --git-protocol https --scopes workflow
gh auth setup-git
gh repo create thiagohugo12-dotcom/grande-arvore-rpg --private --source . --remote origin --push
git push origin --tags
gh repo view --json nameWithOwner,isPrivate,url
git status
```
5. Confirme `isPrivate: true`; visite Actions → Web build. Se Actions estiver desativado na conta, habilite. A CI guarda build como artifact; não publica site.

## Se preferir criar pelo site
Crie **grande-arvore-rpg**, selecione **Private**, e não marque README/.gitignore/licença para manter o remoto vazio. Após restaurar o bundle:
```powershell
git remote add origin https://github.com/thiagohugo12-dotcom/grande-arvore-rpg.git
git push -u origin main
git push origin --tags
```
Use Git Credential Manager para autenticar. Se o envio do workflow for negado por escopo de autorização, autorize acesso a workflows no seu método de autenticação; não remova o arquivo para esconder o problema. Se o repositório já existir, confira a privacidade e o conteúdo antes de vincular; não sobrescreva histórico nem use force push.

## Trabalho posterior
`git pull --ff-only` antes das alterações; testar, `git add` apenas arquivos do escopo, commit pequeno e push. `.godot/` e `build/` permanecem fora do Git. Os `.gd.uid` são versionados. Tags de checkpoint não devem ser movidas.
