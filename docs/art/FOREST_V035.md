# Floresta simplificada v0.3.5

Cinco sprites de 20 cores substituem os cinco originais v0.3.4. As dimensões
armazenadas são 60×59, 37×60, 42×60, 22×17 e 62×64 pixels; são desenhados em
96×96, 78×96, 68×96, 32×26 e 96×96 com filtro nearest. As bordas
transparentes foram recortadas. Importação Godot: lossless (modo 0), sem mipmaps;
o projeto usa filtro nearest. Os originais v0.3.4 e o atlas legado permanecem
recuperáveis no commit `dfdae1d`, mas não entram no Web export atual.

| Medida | v0.3.4 | v0.3.5 (primeiro passe) |
| --- | ---: | ---: |
| PNGs da floresta no repositório | 72.561 bytes | 14.400 bytes |
| Tentativas de sub-bosque | 1.250 | 260 |
| Tentativas de árvore | 290 | 155 |
| Detalhes por tile de solo | 7 | 2 |
| Pacote Web do CI (artifact ZIP) | 15.165.924 bytes | 10.936.768 bytes |

O `tests/perf_probe.gd` registra tempo de abertura da cena, contagem de nós,
colisores e memória estática headless. A medição não substitui FPS, GPU ou
memória em aparelho físico; comparar números apenas no mesmo ambiente.
