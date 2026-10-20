# ADR: Identidade própria para o Andar 2

Status: REFINAMENTO V2 APROVADO; MAPA JOGÁVEL INTEGRADO LOCALMENTE EM 19/10/2026.

Autor / data: Codex, 19/10/2026.

Decisão anterior: os cinco andares compartilhavam a Mata, a Torre, os serviços, as hordas, o Guardião e a progressão de 50 derrotas por andar (`CINCO_ANDARES_V060.md`). A expansão e o visual recente da Mata aplicam-se ao Andar 1. Até esta integração o Andar 2 usava a apresentação anterior e o mapa de 1200×900.

Problema e evidências: uma captura real de 390×844 do Andar 2, arquivada em `outputs/capturas-andar2-atual` fora do projeto Godot, mostra piso, trilhas e vegetação de outra fase artística. A viagem e o save funcionaram no teste de campanha, com zero falhas. O contraste com o Andar 1 pode parecer uma regressão visual.

Proposta e alternativas:

- Recomendada: definir um bioma e uma silhueta de mapa exclusivos do Andar 2, dentro da direção pixel art V2. Fazer primeiro uma amostra visual e uma planta de caminhos; só depois integrar arte, colisões, câmera e minimapa. Reutilizar sprites proporcionais quando couber e criar poucos recursos novos. Manter as regras atuais de campanha nesta primeira etapa.
- Menor escopo: manter a geometria e trocar somente piso, trilhas e vegetação. A entrega seria mais rápida, mas o andar continuaria reconhecível como a Mata antiga.

Direção aprovada pelo dono em 19/10/2026: Vale das Pedras Douradas, inspirado no Cerrado brasileiro com fantasia; campos, gramíneas, árvores pequenas tortuosas, chapadas de arenito, pedreira, ruínas, pontos de água, trilhas e uma área segura compacta. Inimigos comuns planejados: Goblin Garimpeiro, Tatu Rochoso e Escorpião da Chapada. Chefe planejado: Colosso de Arenito. A Mãe-do-Ouro é apenas possibilidade futura. A direção visual não autoriza a implementação desses sistemas.

Referências visuais aprovadas: `outputs/planejamento-andar2/` fora do projeto Godot contém as amostras, planta, composição vertical e sprites reutilizáveis de estudo. A planta propõe 1700×1350 unidades, similar ao Andar 1 expandido, como referência aproximada. O mesmo sprite de depósito representa as possíveis qualidades do minério; raridade será definida futuramente pelas regras de extração, ainda não implementadas.

Refinamento solicitado pelo dono em 19/10/2026: preserva bioma, escala, distribuição geral e dimensões; reforça quatro depósitos de mineração, arquitetura das ruínas, entrada e piso da arena, identidade terrosa da área segura, clareiras do Cerrado, diferenciação da região perigosa e pista ambiental de passagem a leste. Referências V2 e comparações estão em `outputs/planejamento-andar2/refinamento-v2/` fora do projeto Godot. Thiago aprovou essa direção e pediu a implementação jogável na versão local em 19/10/2026.

Decisões futuras do dono: regras de mineração, inimigos, Colosso, puzzle, segredos e recompensas em decisões separadas.

Impacto no Game Design, desempenho, compatibilidade e saves: a proposta visual inicial preserva viagem, 50 derrotas, inimigos, economia, habilidades, baú global e estrutura de save. Um mapa separado exigirá conferir pontos de surgimento, área segura, Torre, recursos, baús, colisões, limites de câmera e minimapa. Novas regras ou recompensas exigirão decisão separada.

Aprovação explícita do dono (referência/data): identidade e planejamento visual solicitados no texto colado "ARVÉON: Ascensão Ancestral — Andar 2: Vale das Pedras Douradas", 19/10/2026; mensagem de 19/10/2026 "a direção artística, a identidade do bioma e a planta refinada [...] foram analisadas e aprovadas" e ordem para implementar o mapa jogável local.

Plano de validação e rollback: capturar antes/depois em desktop e 390×844; testar viagem, circulação, interações, combate, coleta, baús, minimapa, salvamento e retorno ao Andar 1. Isolar o cenário do Andar 2 para que o Andar 1 permaneça recuperável sem redefinir a campanha.

Resultado local: `scenes/world/andar_2.tscn` contém o Vale próprio; `Floor2Layout` e os sprites em `assets/art/andar2/` mantêm composição e colisões na mesma lista. O acampamento conserva Ferreiro, Vendedor, baú e Torre; a pedreira, as ruínas, a região perigosa, a arena e a pista da passagem são exploráveis. A arena não contém o Colosso. Oito pontos de coleta e três baús usam os tipos e o save já existentes. Teste físico percorreu todas as regiões, inclusive a passagem, e testou viagem, serviços, minimapa e persistência; capturas reais estão em `outputs/capturas-andar2-jogavel/` fora do projeto. A mineração dos quatro depósitos foi autorizada depois e está registrada separadamente em `ANDAR2_MINERACAO_20261019.md`.

Refinamento visual posterior aprovado pelo dono: manter a vegetação simples da prévia do Cerrado e usar a cor quente de solo e grama indicada na imagem enviada em 19/10/2026. O terreno do Andar 2 passou a usar campo verde-oliva dourado, trilhas bege, tufos espaçados e manchas menores. As árvores têm troncos tortos e copas abertas; alguns exemplares próximos foram removidos com suas colisões, ampliando as clareiras. Os paredões de arenito foram reduzidos apenas na altura visual, conservando apoio e largura física. O Ferreiro foi deslocado para a frente da forja, fora da tenda. A arte foi regenerada pela fonte `outputs/planejamento-andar2/render_refinamento_v2.py` fora do projeto, instalada em `assets/art/andar2/` e conferida em capturas reais em `outputs/ARVEON/Registros/andar2-cerrado-implementacao/`. Nenhuma regra de combate, mineração ou progressão foi alterada.

## Correção da implementação visual — 20/10/2026

Diagnóstico na cena efetiva: `data/floor_config.gd` carrega `scenes/world/andar_2.tscn`; `scripts/presentation/floor2_view.gd` desenhava `assets/art/andar2/terreno.png` numa única textura em escala 2 e posicionava sprites separados conforme `data/floor2_layout.gd`. `scripts/world/andar_2_world.gd` cria colisões a partir da mesma lista. Filtragem nearest e escala dos pixels estavam corretas. O desvio visual vinha principalmente da arte-fonte: solo com manchas geométricas, sprites de rocha/vegetação simplificados e ruínas pouco volumétricas. Não havia TileSet do Andar 2; os elementos da prévia aprovada não estavam ligados à cena jogável.

Primeiro passe isolado: a Pedreira recebeu terreno texturizado, boulders/afloramentos de arenito, árvore de copa aberta e depósitos com minério integrado. A cena foi executada na Godot e comparada no mesmo enquadramento em `outputs/ARVEON/Registros/andar2-correcao-visual/pedreira-primeiro-passe/` e `.../antes/`. Após a melhora perceptível, a linguagem foi aplicada ao mapa inteiro.

Arte atual: `tools/build_floor2_art.py` extrai e dimensiona sprites reutilizáveis das fontes aprovadas em `outputs/ARVEON/Registros/andar2-correcao-visual/fonte-rochas-arvore.png` e `fonte-ruinas-arena.png`, fora da pasta do projeto. Gera 18 PNGs em `assets/art/andar2/refined/` (aproximadamente 244 KB): variações de chão em atlas, terreno final, rochas, depósito, árvores e arbustos de Cerrado, pilar, marco, muro, altar e borda de arena. O terreno permanece apenas sob os objetos; árvore, pedra, depósito e estrutura continuam sprites independentes com profundidade e colisões próprias. Grama e flores anteriores ainda aparecem de forma discreta. As trilhas mantêm conexões, com deslocamento suave e desgaste nas bordas; o piso da arena usa arenito quente em vez do grande disco acinzentado.

Integração: `Floor2View` usa explicitamente a nova textura e escolhe sprites por tipo/posição, com duas variações de árvore, arbusto e pilar. Os quatro depósitos existentes seguem nas mesmas posições e usam o mesmo estado de mineração. `Andar2World` ajustou apenas as bases sólidas de rochas, muro, altar e pilares para a largura inferior dos novos sprites; não mudou os demais sistemas nem as dimensões do mapa. A área segura mantém Ferreiro, Vendedor, Baú e Torre acessíveis.

Evidência e validação: as nove capturas em `outputs/ARVEON/Registros/andar2-correcao-visual/versao-refinada/` vieram do jogo carregado pela Godot 4.5.1 Compatibility, incluindo visão geral, Pedreira, Ruínas, Arena, Campos/Região Perigosa, Área Segura e 390×844. `tools/build_floor2_comparisons.py` alinha capturas reais de antes/depois, sem alterar a escala. Os testes direcionados `tests/andar2_integration.gd` e `tests/mining_integration.gd` terminaram com zero falhas, cobrindo circulação física, serviços, viagem, minimapa, câmera, save e mineração. A captura final depois da correção do piso da arena também executou sem erros.

Limites: esta revisão aproxima volume, paleta e composição, mas não reproduz pixel a pixel a referência ilustrada. A referência tem maior densidade e variedade manual de pequenas plantas; a arte jogável ainda usa distribuição e piso das ruínas da planta existente. Refinamentos posteriores podem introduzir alguns tufos/fragmentos adicionais ou variantes de copa, mantendo o custo de renderização e a leitura em celular.
