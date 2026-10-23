# Padronização do nome ARVÉON

Status: aplicada na branch `dev/arveon-solo-10-andares`; identidade externa alinhada sem novo build.

## Identidade

- Nome oficial: **ARVÉON: Ascensão Ancestral**.
- Nome curto: **ARVÉON**.
- Identificador técnico novo: `arveon`.

README, títulos de direção artística e QA, referência de produto no Game Design,
nome da exportação de backup e API JavaScript de save usam a marca nova. O
identificador de teste `ARVEON_SAVE_PATH` é preferido; o antigo
`GRANDE_ARVORE_SAVE_PATH` continua como fallback para ferramentas existentes.
`ArveonSave` é a API preferida e `GrandeArvoreSave` continua como alias legado.

## Compatibilidade que preserva progresso

Não renomear ainda:

- `config/custom_user_dir_name.web="grande-arvore-rpg"`: mantém o mesmo
  diretório IDBFS/IndexedDB usado pelo save Web existente.
- A chave localStorage `grande-arvore-rpg.save.v6` e seu journal `.previous`.
- O formato de backup `grande-arvore-rpg-save`: novas exportações usam
  `arveon-save`, e a importação aceita ambos.
- A busca por diretórios antigos `Grande Árvore RPG...` no IDBFS.

Esses valores são identificadores persistidos, não a marca apresentada ao
jogador. Mudá-los exige uma migração de dados separada e validada.

## Nomes externos alinhados

- Repositório GitHub: `thiagohugo12-dotcom/arveon`.
- Projeto Vercel: `arveon`, mantendo o ID `prj_gYKlx91MiswTmwj2PLiN5liQD0B7`.
- Novos endereços: TESTE `https://arveon-teste.vercel.app/` e PROD
  `https://arveon.vercel.app/`.
- Os aliases antigos continuam ativos e apontam para os mesmos deployments;
  esta mudança de nome não gerou nem promoveu um build.
- Saves Web antigos continuam no endereço antigo: o armazenamento do navegador
  é separado por domínio. Para levar um save ao novo endereço, exporte o backup
  no antigo e importe no novo; nenhuma migração automática entre domínios foi
  publicada.
- README, workflow, verificadores e instruções atuais usam os novos nomes.
- O endereço local `origin` usa `https://github.com/thiagohugo12-dotcom/arveon.git`.

IDs Vercel, segredos de CI e integração Git permanecem estáveis. O nome Grande
Árvore que aparece na narrativa continua sendo parte do mundo do jogo.
