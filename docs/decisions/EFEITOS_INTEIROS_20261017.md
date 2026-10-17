# Efeitos inteiros e retorno do Kamusari anterior

Pedido de Thiago em 17/10/2026: corrigir os fragmentos cortados destacados nas capturas de Estocada/Guarda e retornar ao Kamusari anterior à referência. Somente local.

## Diagnóstico e correção

As ilustrações de Estocada e Guarda têm elementos que atravessam as células de 512 px. A leitura da célula e os polígonos manuais de recorte exibiam fragmentos de efeitos vizinhos atrás do explorador. Os efeitos ativos agora usam geometria completa com pontas afiladas: estocada azul/branca com impacto dourado à frente, defesa azul e faíscas de reação. Os PNGs originais e os auxiliares de atlas permanecem para comparação histórica, mas não participam do renderizador ativo destas técnicas.

Kamusari restaurado ao renderizador do commit local 5519c04: círculo completo, rastros e crescente que avança para a frente. Sem a lâmina conectada da última referência. Personagem, poses, dano, alcance, recarga, contato e duração preservados. A cena de revisão e o jogo principal compartilham o renderizador corrigido.

## Validação local

- 570 verificações de renderização e combate, zero falhas. Incluem perímetro do Kamusari, avanço do crescente, dash no jogo real e ausência de fragmentos atrás nas seis etapas de Estocada/Guarda nas quatro direções.
- 169 verificações da cena de revisão, zero falhas.
- 72 verificações da identidade do explorador, zero falhas.
- Capturas reais da cena de revisão inspecionadas para Estocada e Guarda no contato.
- Logs em `outputs/ARVEON/Registros/efeitos-inteiros-*`; capturas em `outputs/ARVEON/Revisoes/kamusari-local/inteiro-*` e `Revisoes/refinamento-local` (fora do repositório).

Sem exportação Web, publicação ou teste em aparelho móvel nesta correção. Alteração preexistente em project.godot preservada e excluída deste commit.
