# ADR: livro ilustrado e árvores de talentos
Status: APROVADA
Autor / data: Thiago e Codex, 12/10/2026

Thiago pediu aplicar imagens ao inventário e implementar a árvore no visual
aprovado. Confirmou explicitamente: “Sim, proficiência abre caminhos e nível
dá pontos”. Cinco categorias independentes; trocar arma preserva a árvore.

O livro usa fundo e atlas de ícones gerados, com controles reais sobre a arte.
Em paisagem, mochila à esquerda e personagem/equipamento à direita. Em retrato,
o conteúdo se reorganiza e rola, preservando alvos de toque de 44 px.

Primeiro recorte funcional: proficiência avança por acertos que causam dano,
incluindo projéteis (categoria capturada no disparo); nunca por apertar botão
sem acertar. Nível geral concede o ponto já existente por nível. A árvore
compartilha esse orçamento com melhorias antigas, sem duplicar pontos.
Técnicas e graus já comprados permanecem. Os três efeitos atuais são
aperfeiçoados pela árvore; novas técnicas e escolha dos dois slots continuam
pendentes de definição dos seus efeitos, sem inventar habilidades extras.

Balanceamento PROVISÓRIO e substituível: 1 XP por acerto, teto 30, piso de XP
da proficiência (n−1)×n×10. Cada nó custa 1 ponto. Marcos 3/8/15 aprimoram
Corte/Investida/Fúria em 1 grau apenas com a categoria correspondente,
até grau 4. Passivas: prof. 5 +8 HP, prof. 12 +1 defesa, prof. 18 +2 dano;
maestria 30 +8 HP e +2 dano. Dependências formam dois ramos, técnica e passiva.
Todos os efeitos de categoria exigem sua arma equipada; nenhum bônus cura.
O marco de nova técnica 25 e Ultimate não são apresentados como funcionais.

Save v7 valida árvores, XP, requisitos, dependências e orçamento antes de
trocar qualquer estado; migra v1–6 sem perder atributos, equipamento ou skills.
Checkpoint antes da implementação preserva a versão do diário anterior.
Validação: testes de progressão, saves corrompidos, dano real e categorias,
toque/rolagem, screenshots paisagem/retrato e export Web no TESTE.
