# Correção da localização da Torre

Base verificada: `523391216266c89639c892c6fbc29e81dc564384`, branch
`feat/andar1-v020-primeiro-passe`. Os três commits recentes já continham a
entrada, persistência e interface da Torre; nenhum desses sistemas foi recriado.

## Localização e preservação

A extremidade leste foi escolhida porque a trilha principal já chega até
(1160, 455). Entrada movida de (600, 280) para (1130, 455). A distância direta
até o ponto de retorno da vila (540, 450) passa de 180,28 para 590,02 unidades:
3,27 vezes maior. O percurso validado acompanha (540,450), (720,445), (880,485)
e (1130,455), cerca de 596,8 unidades, sem dash ou teletransporte.

Mapa permanece exatamente 1200 × 900. A cena do mundo, seus quatro limites,
as duas rochas, a câmera, as trilhas, recursos, construções, NPCs, área segura
e posições de surgimento dos inimigos não foram modificados. Colisor e desenho
da Torre usam a mesma constante de posição. Nenhuma expansão de mapa.

Removida somente a árvore cujo pé estava em (1139, 387), dentro do novo corpo
da Torre. O filtro é aplicado depois da geração determinística: não altera a
sequência do gerador nem reposiciona árvores de outras regiões. A entrada fica
fora da área segura e da margem de segurança; o spawn mais próximo, em
(930,440), está a 200,56 unidades. Inimigos continuam podendo perseguir o
jogador fora da área segura, conforme a regra existente.

Contador de 50, eventos de morte, save v6, migrações, painel, interações, XP,
ouro, combate, equipamento e missões usam os mesmos arquivos de gameplay.

## Validação

- Godot 4.5.1: importação sem erros, 479 verificações de contratos com zero falhas.
- Percurso em passos de 3 unidades usando o colisor real do Player; movimento
  pelo InputDriver touch na entrada, parede sólida e frente acessível.
- Limites físicos, dimensões da câmera/minimapa, distância da vila, separação
  de spawns e recursos; minimapa acompanha jogador na extremidade leste.
- Suíte de save novo/antigo, contagem sem duplicação, morte, interação bloqueada
  e liberada, inventário, NPCs, progressão e combate preservada.
- Abertura e fechamento por eventos de toque em quatro viewports: 360 × 640,
  390 × 844, 640 × 360 e 960 × 540; controles bloqueiam/retornam pelo menu.
- 22 capturas nativas GL da Torre, incluindo minimapa expandido e mapa inteiro,
  com zero falhas. CI exige 93 capturas totais e exportação Web antes do Preview.
- Sonda local: 143 nós, 63 colisores, 29.014,6 KiB estáticos, abertura 192,48 ms.
  Um colisor a menos que na base; nenhum novo nó de gameplay ou dependência.
- Exportação Web e publicação são verificadas no workflow associado ao commit.

## Evidências e teste

`docs/qa/tower-relocation/mapa.png`: cena completa renderizada pelo Godot,
com linha sobre a trilha, vila e posições anterior/nova. Anotações são exclusivas
do script de QA e não entram no jogo. `entrada-mobile.png` e
`minimapa-mobile.png`: interface real, sem anotações.

No celular, sair da vila pela direita e acompanhar o caminho até o extremo
leste. Aproximar-se da porta e tocar Interagir; abaixo de 50, consultar o
progresso; com 50, abrir o painel e tocar Fechar. O mapa ampliado mantém a
escala original e o marcador do jogador próximo à borda direita.

Limitações: teste touch usa eventos automatizados, sem aparelho físico.
Desempenho/FPS em celular real não foi medido. Exportar Web não equivale a
validar renderização WebGL em navegador sem esse recurso. A prova continua
indisponível nesta versão; sem hordas, Andar 2 ou v0.5.1. Publicação apenas
no Preview de TESTE; main e produção permanecem preservadas.
