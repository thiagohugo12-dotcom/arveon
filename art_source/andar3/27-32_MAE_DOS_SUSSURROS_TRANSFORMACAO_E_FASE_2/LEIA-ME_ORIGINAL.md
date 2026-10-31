# ARVÉON — MÃE DOS SUSSURROS — PACOTE DE REVISÃO

## Conteúdo
- `fase1/`: spritesheets originais já aprovadas (Idle 4, Movimento 4, Ataque 6, Dano 3 quadros).
- `transformacao/`: spritesheet ORIGINAL aprovada, transformação de Fase 1 para Fase 2 (6 quadros).
- `fase2/ORIGINAL_COMPOSTO_5_ANIMACOES.png`: arte ORIGINAL recebida, com Idle 4, Movimento 4, Ataque 6, Dano 3, Morte 6, todos organizados numa prancha.
- `fase2/recortes_PRELIMINARES/`: regiões recortadas sem redesenho e sem reamostragem. **NÃO são spritesheets finais**.
- `manifesto.json`: descrições e retângulos dos recortes.

## Avaliação
Os cinco movimentos da Fase 2 estão visivelmente coerentes com a forma final transformada e têm a quantidade solicitada de quadros (total 23). A arte composta, contudo, contém títulos, linhas brancas, ruídos de borda e possíveis invasões entre quadros, inclusive próximos às silhuetas. Não converter automaticamente em recursos prontos para `SpriteFrames`. A divisão exata por largura não é confiável.

## Próximo passo para Claude
1. Examinar arte de referência e prévias (não sobrescrever).
2. Solicitar/receber, se necessário, exportação limpa de cada uma das cinco animações da Fase 2 em PNGs separados, sem títulos, linhas nem divisórias, mantendo identidade visual EXATA do quadro 6 da transformação.
3. Quando existirem PNGs aptos, configurar recorte, quadros, alinhamento, escala e transições de ataque/movimento/dano/morte. Validar visualmente em 360×800.
4. Salvar apenas localmente; **não fazer push, deploy, merge nem alterar main/produção**.

Uma prévia conceitual aprovada não é prova de que a spritesheet possa ser diretamente importada no jogo.
