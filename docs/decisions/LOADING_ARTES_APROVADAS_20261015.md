# Tela de carregamento — correção aprovada em 15/10/2026

Status: APROVADO pelo pedido explícito de Thiago.

Fontes aprovadas: 77010.png (horizontal, 1536×864) e 77011.png (vertical,
864×1536). Apesar da extensão, os arquivos recebidos contêm JPEG. A conversão
para PNG é sem perda adicional: todos os pixels RGB foram comparados e são
idênticos. Não há nova arte, recorte, upscaling do arquivo ou filtro de nitidez.
approved-artwork.json registra hashes de origem, PNG e RGB decodificado.

Diagnóstico: a exportação anterior copiava os AVIF antigos de 14,8/13 KB,
usando URLs estáveis. O CSS aplicava cover em uma área parcial da tela. Os
testes antigos verificavam nomes/tamanho, sem identificar as referências
aprovadas. O verificador público comparava apenas index.html e index.pck.
Trocar CSS ou republicar esses arquivos não substituía a arte exportada.

O exportador agora valida as fontes aprovadas por hash e resolução e instala
imagens, CSS e JS sob nomes derivados do conteúdo, em loading-artwork/. Os
AVIF antigos são removidos do código e da saída. HTML/manifesto usam no-store;
arquivos com hash são imutáveis. Imagens de loading ficam fora do PCK.

A cena mantém a imagem inteira em contain, com proporção correta, sem esticar,
sem filtros e respeitando dvh/safe areas. Desktop usa horizontal; viewport
mobile até 767px usa vertical. O limite nativo evita ampliar fontes pequenas.
As margens recebem o verde escuro da identidade existente.

Somente as áreas de texto da dica e da barra desenhadas na arte recebem
controles HTML. A lâmpada, a moldura e o CARREGANDO da imagem permanecem. Não
há segundo rodapé, pontos, título ou legenda visível. O elemento progress
original é movido para o espaço da barra; value/max continuam exclusivos do
onProgress do Godot. Dicas curtas alternam a cada 4,5 s durante a espera.

QA: quatro viewports obrigatórios, downloads realmente pendentes para captura,
fonte/resolução/enquadramento, controle nativo único, dicas alternadas,
inicialização completa, persistência v11 e hashes dos recursos servidos.
Capturas são geradas antes da publicação e novamente no TESTE. A verificação
pública compara PNG, CSS, JS, manifesto, HTML e PCK e exige remoção dos AVIF.

Checkpoint: checkpoint-antes-loading-artes-aprovadas-2026-10-15, em 1d00c61.
Sem alteração de gameplay, main, PRODUÇÃO ou formato/código de save v11.
