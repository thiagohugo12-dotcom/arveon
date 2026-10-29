# ADR: Amostra artística isolada da Mata
Status: APROVADA (somente criação da amostra; aparência aguarda aprovação)
Autor / data: direção de Thiago, 11/10/2026

O rework 810c3137 não foi aprovado artisticamente. O pedido atual autoriza
uma cena demonstrativa separada, não a aplicação ao mapa compartilhado.
Amostra da região leste: grama viva amarelada, areia dourada, duas copas
orgânicas, pedra e vegetação escassa. Explorador existente preservado.
Sprites raster autorais preparados com geração de imagem e integração
por recorte, nearest-neighbor e transparência binária. Sem shaders.

A cena reutiliza PlayerActor, ActorView, InputDriver e controles touch.
Não instancia Main, GameProgress ou BrowserSave; não lê nem grava saves.
A Mata original, seus cinco andares e colisões não são alterados.
Publicação da amostra somente em entrada separada de TESTE, quando validada.
Depois das capturas e do commit, PARAR e aguardar aprovação visual explícita.

Validação: importação 4.5.1, suíte existente, render real desktop/mobile,
movimento e colisões da amostra, export Web e abertura da cena exportada.
Rollback: remover apenas arquivos novos da amostra e seu link Web.
