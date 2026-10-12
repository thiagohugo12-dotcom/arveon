# Props pequenos da área segura — 11/10/2026

Pedido: padronizar apenas os objetos pequenos da Mata V2 do Andar 1 pela referência de vila pixel art. Base: c144759a3ab128d9724849bda6f0b2ccbaf41352.

Foi criado `assets/art/mata_v2/camp_props.png`, um atlas nativo 128×64 de oito props: cerca, placa direcional, barril, caixa, fogueira, poste com lanterna, banco e pequenas pedras. Cada um usa massas largas, contorno marrom escuro e duas ou três cores de madeira, pedra e fogo. A placa não contém texto; o símbolo simples permanece legível em escala mobile.

O Andar 1 usa o atlas somente dentro de `FloorV2View`: substitui as cercas, placas, barris, caixas, lanternas e fogueira já presentes, inclui um único banco e usa a região de pedrinhas em poucas decorações livres. Posições de serviços, árvores, NPCs, trilhas, itens, colisores, regras e saves são preservados. Sem nós, processos, sombras dinâmicas ou props adicionais nos Andares 2–5.

A ferramenta integrada imagegen gerou uma folha de referência de formas a partir da imagem da direção artística. A versão gerada trouxe brilho suave inadequado para o jogo, então foi usada apenas como guia. O atlas final foi desenhado em pixels nativos por `tools/build_camp_props.gd`, garantindo transparência binária e escala consistente. Fonte gerada: `work/raw/props-reference.png`, fora do pacote do jogo.

Validação local: importação Godot 4.5.1, suíte de 1317 verificações sem falhas e 34 verificações de captura em quatro resoluções sem falhas. Ainda falta teste em celular físico.
