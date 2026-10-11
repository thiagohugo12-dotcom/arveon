# Diagnóstico e integração dos monstros aprovados

## Problema
Na base d795af70, o `ActorView` desenhava javali, aranha e mandacaru com retângulos e polígonos internos de GDScript, em vez de usar os sprites mostrados pelo usuário na imagem com as três criaturas. É a razão direta para a prévia e o jogo terem monstros visualmente diferentes.

## Correção localizada
O arquivo `assets/art/monsters_approved.png` é um atlas PNG transparente (192×64, três células de 64×64) recortado da imagem de três monstros enviada pelo usuário em 11/10/2026, com redimensionamento nearest e uma paleta pequena. Não contém geração alternativa das criaturas.

`ActorView._draw_monster` agora usa as três regiões de textura para aparência 1 (javali), 2 (aranha) e 3 (mandacaru), mantendo o tamanho/âncora atuais, barra de HP, aviso de ataque, flash, indicação de elite e efeitos de derrota. Nenhuma IA, colisão, estatística, save, progressão ou cena foi modificada.

A rota antiga de desenho geométrico foi preservada no arquivo como código legado não chamado para comparação temporária, não é mais a apresentação ativa.

## Limitações
- Cada monstro tem apenas UM quadro visual aprovado na imagem fornecida. Os três permanecem estáticos durante o movimento; animações completas exigirão artes adicionais fornecidas/aprovadas posteriormente.
- O atlas foi recortado de imagem em fundo escuro e não substitui um PNG fonte com transparência original. Aprovação visual em escala de jogo é necessária.
- NÃO declarar validação Godot/Web nem publicar em TESTE até importação, testes e captura real. Nenhuma modificação à main ou PRODUÇÃO.

## Critérios para validar
1. Abrir a cena do jogo no Godot 4.5.1 e confirmar as três silhuetas.
2. Verificar que nenhum fundo escuro aparece ao redor dos sprites.
3. Conferir tamanho/âncora e não sobreposição da barra de HP e elite.
4. Testar dano, movimento, morte, IA e cinco andares, com controle mobile.
5. Executar suíte de regressão e exportação Web antes do Preview.
