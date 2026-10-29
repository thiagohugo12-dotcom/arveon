# Análise do jogo — animações e Guardião do Andar 1

Data: 16/10/2026
Status das mudanças sugeridas: **PROPOSTA**
Base analisada: versão corrigida da espada, commit remoto `4dc2ef6481336f1c6018e7801bbd94b0dabab4c2`.

## Diagnóstico

A mata e a vila já oferecem uma identidade visual reconhecível. O explorador, os NPCs e os inimigos comuns têm linguagem próxima. A correção da espada resolveu a troca de personagem, mas não encerrou o trabalho de animação: o corpo ainda participa pouco de algumas técnicas, o dano pode anteceder o contato visível e os inimigos não comunicam bem intenção e peso.

Minha prioridade seria **fazer cada ação parecer conectada ao corpo e ao alvo**, antes de aumentar partículas, tamanho ou duração dos efeitos.

## O que foi realmente verificado

- Abri as artes usadas pelo jogo e revisei os caminhos atuais de apresentação e combate.
- Executei o jogo localmente no Godot 4.5.1 com renderização OpenGL real.
- Capturei a cena de treino em 960 × 540 e 390 × 844, com save temporário isolado.
- Montei uma comparação dos desenhos atuais em repouso, caminhada, ataque/aviso e dano. Essa prancha usa os componentes reais, com estados congelados para comparação; não representa uma partida completa.
- Medi a vida do alvo imediatamente após a chamada real das técnicas, antes de avançar a animação:

| Técnica | Vida antes | Vida após a chamada | Tempo visual | Quadro |
|---|---:|---:|---:|---:|
| Estocada Precisa | 1.000.000 | 999.972 | 0,000 s | 0 |
| Kamusari | 999.972 | 999.908 | 0,000 s | 0 |

Os valores são do personagem de treino e servem para verificar a ordem dos eventos, não para julgar balanceamento. Não fiz nesta análise uma campanha completa, medição de FPS em celular físico ou avaliação auditiva em dispositivo. O projeto atual não contém efeitos sonoros implementados nos caminhos de jogo revisados; `audio/sfx` e `audio/music` contêm apenas marcadores vazios.

## Prioridades

| Ordem | Problema observado | Melhoria proposta | Resultado esperado |
|---|---|---|---|
| 1 | Dano aplicado antes do contato visível | Definir um instante claro de impacto e alinhar corpo, efeito, reação do alvo e número de dano | Golpes que parecem acertar de verdade |
| 2 | Kamusari desenhado para a frente, mas dano em círculo | Fazer a apresentação comunicar a área circular vigente; se a intenção for um corte frontal, decidir essa mudança de regra separadamente | O jogador entende quem será atingido |
| 3 | Poucas poses corporais nas técnicas | Criar poses próprias usando o mesmo explorador, arma e proporções | Estocada, guarda e ultimate têm gestos diferentes |
| 4 | Inimigos pouco expressivos; Guardião com corpo estático | Preparação, execução e recuperação próprias por ataque | Ataques previsíveis e criaturas com peso |
| 5 | Feedback visual se afasta do alvo ou compete com cenário/HUD | Rever posição dos números, hierarquia dos efeitos e oclusão | Combate legível no celular |
| 6 | Falta de som no combate | Sons curtos de preparo, golpe, acerto, defesa e derrota | Mais presença sem aumentar o efeito visual |
| 7 | Folhas de efeitos grandes e com enquadramento irregular | Empacotar quadros regulares, com margem e origem fixa | Menos fragilidade em recortes e melhor controle de memória |

## Animação do explorador

### 1. Corrigir a relação entre dano e imagem

O teste confirmou que a vida cai no quadro inicial. O código executa o dano e depois inicia a apresentação dessas técnicas. A reação do inimigo pode, portanto, acontecer enquanto o jogador ainda está preparando o golpe.

Há duas soluções possíveis:

- **Manter resposta imediata:** iniciar a apresentação já no contato, com preparação visual anterior quando possível. Preserva a ordem atual do combate, mas limita uma antecipação longa em técnicas acionadas manualmente.
- **Preparar e depois atingir:** executar o dano no momento do contato da animação. Produz o gesto mais natural, mas altera o tempo de resposta e precisa definir o comportamento ao andar, trocar arma, abrir menu ou morrer durante a preparação.

Recomendo a segunda como direção de polimento, em uma mudança pequena e testada. Isso é proposta de comportamento, não uma correção visual já aplicada. Cooldown, acerto único, múltiplos golpes, linha de visão e cancelamentos precisam continuar corretos.

### 2. Dar movimento próprio a cada técnica

As técnicas atuais têm seis quadros de efeito, mas usam apenas três índices do atlas corporal aprovado. Na Estocada e no Kamusari, por exemplo, o mapeamento corporal é `0, 0, 1, 1, 1, 5`. O efeito muda mais do que o personagem.

Proposta:

- **Estocada:** mão e arma recolhem; tronco inclina; braço estende em linha; corpo retorna. O pé de apoio não deve deslizar. A apresentação pode avançar dentro do desenho sem deslocar a colisão física.
- **Guarda:** espada cruza a frente do torso; ombros fecham; pequeno recuo visual ao receber golpe; retorno à guarda. A pose mantida deve parecer defesa, e não só caminhada dentro de um círculo azul.
- **Kamusari:** preparação curta e reconhecível; transferência de peso; corte forte; recuperação visível. Pela regra atual, o efeito também precisa indicar a área ao redor do explorador.

Preservar rosto, cabelo, roupa, altura e ponto dos pés em todos os quadros. Separar corpo, arma e efeitos ajuda a corrigir uma parte sem redesenhar as demais.

### 3. Direção, transições e ritmo

- Os efeitos da espada são espelhados horizontalmente ou girados para cima/baixo. O torso usa poses nas quatro direções. A montagem precisa ser revisada especialmente em cima/baixo para a energia realmente sair da lâmina.
- Definir prioridade clara entre básico, técnica, guarda, dano, dash e morte. Hoje o básico pode seguir contando por baixo da técnica; revisar o retorno evita cortes de pose ou um golpe aparentemente incompleto.
- Validar contato e recuperação andando e parado. Animar apenas as pernas da caminhada pode dar sensação de corpo flutuando se a técnica não tiver apoio coerente.
- Alguns quadros de efeito duram 35–45 ms. A 30 FPS, isso representa aproximadamente um quadro. O gesto deve continuar entendível sem depender desses quadros muito curtos.
- Usar brilho e partículas como acento do contato. Aumentar todo o efeito tende a esconder braço, espada e inimigo.

## Inimigos comuns

O conjunto atual contém Javali, Aranha e Mandacaru, além do Javali de elite. Os sprites da vila têm quatro quadros por espécie. A caminhada seleciona esses quadros; o ataque reutiliza dois deles. A direção de perseguição é calculada, mas a folha usada no desenho não contém linhas direcionais.

- **Javali:** baixar a cabeça e firmar as patas durante os 0,42 s de aviso da investida; corpo horizontal e patas rápidas na corrida; derrapagem curta na recuperação. O elite precisa se distinguir também pela silhueta, além de texto e cor.
- **Aranha:** alternar pares de pernas, orientar o corpo para o alvo e preparar o contato com um gesto pequeno. A movimentação lateral existente já oferece uma boa base de personalidade.
- **Mandacaru:** comprimir o corpo e orientar o braço antes do disparo; abrir/estender no instante em que o espinho sai. O aviso de 0,34 s existente deve ser aproveitado pelo gesto.
- **Todos:** reação curta ao dano e derrota com pose própria. Evitar usar apenas clareamento e desaparecimento. O movimento visual não precisa empurrar fisicamente a criatura.

## Novo visual do Guardião da Mata

Interpretei “monstro do andar 1” como o Guardião da Mata da Torre. Há também o Guardião das Raízes opcional: atualmente os dois compartilham o mesmo corpo básico. A proposta abaixo é para o chefe da Torre; manter essa distinção evita trocar a criatura errada.

### Direção de desenho

Manter o tema já existente de árvore viva e raízes, com leitura mais forte:

- Tronco compacto e largo, com rosto reconhecível em poucos pixels.
- Dois braços de raízes claramente separados do torso.
- Pés de raízes articulados, para caminhar com peso.
- Musgo e copa concentrados nos ombros, com pequena assimetria para reconhecer a silhueta.
- Madeira em tons quentes, folhagem mais escura e olhos âmbar discretos. O contraste deve funcionar sobre a mata verde.
- Aparência de protetor da floresta. Não acrescentar uma identidade de vilão ou narrativa nova.
- Como ponto inicial de estudo, altura visível de aproximadamente 1,6 vez a do explorador. Conferir escala na cena real antes de fechar o sprite; a arte não deve determinar o alcance da colisão.

### Movimento ligado aos ataques existentes

| Ação atual | Preparação proposta | Execução proposta | Recuperação proposta |
|---|---|---|---|
| Golpe frontal de raízes | Baixa o torso e recolhe um braço | Braço atinge o chão, raízes acompanham o cone já existente | Braço permanece apoiado por um instante e retorna |
| Espinhos em três pontos | Ambos os braços se apoiam no solo; torso comprime | Raízes percorrem o chão e os espinhos surgem nos círculos avisados | Ombros e braços relaxam |
| Investida | Pés se firmam, copa inclina e corpo aponta a direção | Tronco avança com raiz dianteira recolhida | Freia, perde equilíbrio visual e se recompõe |
| Segunda fase | Mantém a mesma criatura, com postura mais tensa | Usa os mesmos sinais de ataque | Respiração mais marcada e pequenos acentos luminosos |

A recuperação da investida perdida já oferece uma abertura maior no combate. A animação deve mostrá-la: é uma boa oportunidade de ensinar o jogador a contra-atacar sem texto adicional.

### Pacote inicial sugerido

Produzir primeiro uma amostra de repouso, caminhada e golpe frontal nas quatro direções. Validar identidade, escala e apoio no chão. Depois completar espinhos, investida, dano e derrota. Quantidades iniciais para planejar: repouso 4 quadros, caminhada 6, golpe frontal 6–8, canalização 6, investida 6, dano 2 e derrota 6. Esses números são estimativas de produção, não regras fechadas.

Cada quadro deve ter a mesma origem dos pés, espaço suficiente para os braços e efeitos separados do corpo. A prancha conceitual é apenas um estudo de forma e intenção; não é uma folha de sprites pronta para importar.

## Outras melhorias do jogo

- **Cena de treino:** nas capturas atuais, árvores continuam muito próximas do personagem e do alvo. Reservar uma faixa realmente limpa para testar golpes nas quatro direções.
- **Números de dano:** o deslocamento para fugir dos painéis pode empurrar valores muito abaixo do inimigo. No treino capturado, aparecem perto dos botões inferiores. Procurar uma posição próxima livre ou usar uma lista discreta de acertos no treino.
- **HUD:** a versão retrato mantém boa área central, mas aviso de treino, texto de status e minimapa competem no topo. Consolidar informações repetidas e revisar a sobreposição em combate.
- **Coerência de arte:** os corpos são pequenos e feitos de grupos grandes de pixels; algumas energias da espada têm detalhe muito mais fino. Ajustar essa diferença de densidade sem perder a forma dos efeitos aprovados.
- **Objetivo e progressão:** conferir em teste humano se a escolha da primeira arma, as 50 derrotas e a entrada da Torre ficam claras sem abrir vários menus. Este fluxo não foi percorrido do início ao fim nesta análise.
- **Desempenho mobile:** medir tempo de quadro e memória no aparelho alvo antes de escolher compressão e quantidade de quadros. As três folhas atuais têm 1536 × 1024 pixels cada; reduzi-las exige conferir pontas, margens e transparência, não apenas diminuir a resolução.

## Ordem recomendada para o próximo passe

1. Resolver a comunicação da área do Kamusari e definir o instante real dos impactos.
2. Fazer poses próprias da Estocada e da Guarda usando o explorador atual.
3. Validar transições, direção e leitura a 30 FPS no treino.
4. Aprovar a silhueta do Guardião em escala real.
5. Animar um golpe completo do chefe e testar na arena antes de produzir o restante.
6. Completar reações dos inimigos, som e revisão da HUD.

## Validação e limites da proposta

Para implementar: capturar jogador e chefe nas quatro direções; testar parada, caminhada, dash, dano, morte, troca de arma e menus; comparar o instante de perda de vida com o contato visível; verificar área indicada contra os alvos realmente atingidos; validar export Web e celular. Preservar os testes existentes e saves v11.

Nesta entrega foram criados estudos e evidências locais. O jogo publicado não foi alterado. Alterações de tempo de dano ou formato de ataque continuam como proposta de design. A implementação futura deve ser dividida em etapas pequenas e reversíveis, usando os checkpoints existentes.
