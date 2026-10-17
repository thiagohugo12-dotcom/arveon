# Kamusari local — correção do recorte traseiro

17/10/2026. Autorização: Thiago testou o jogo pelo BAT e pediu corrigir o Kamusari com aspecto de PNG recortado e sprite/movimento estranho. Trabalho exclusivamente local.

## Causa reproduzida

O jogo completo ainda usava a apresentação bitmap aprovada anteriormente, enquanto a proposta circular estava restrita à revisão. O PNG tinha efeitos cruzando células; polígonos de recorte manuais removiam parte do rastro traseiro. O enquadramento também variava por quadro. Capturas reais nas quatro direções reproduziram o problema.

## Correção aplicada ao jogo completo local

- Kamusari passa a desenhar curvas contínuas com cauda afunilada, um corte próximo da espada e uma expansão circular no contato. Não usa a folha PNG, máscaras ou recortes de célula. O PNG original fica preservado e é usado apenas para comparação na revisão.
- Raio visual acompanha a regra vigente de 150 px e o bônus de 20 px quando a passiva está equipada. Direção do corte permanece capturada na ativação.
- Poses corporais usam mais quadros do atlas básico já aprovado: `0,0,1,2,3,5`, preservando o explorador.
- `_ready` da view volta a chamar a inicialização original de ActorView: filtro NEAREST e posição inicial dos pés. Isso mantém os pixels nítidos e inicializa corretamente a distância da caminhada.
- Revisão e jogo normal compartilham o novo renderizador. O painel ANTES conserva o bitmap antigo para comparação.
- Duração 0,485 s, contato 0,215 s, dano, quatro acertos, cooldown, alcance, movimento e Dash não tiveram seus valores alterados.

## Verificação local

- 382 verificações renderizadas: perímetro completo frente/trás/lados em quatro direções, raios 150/170, curvas trianguláveis, personagem nítido e acompanhamento durante movimento/Dash no Main real. Colisões com árvores foram preservadas; não se interpretou bloqueio físico legítimo como falha da animação.
- 72 verificações renderizadas da identidade do explorador.
- 516 verificações funcionais relevantes de contato/cancelamentos/colisões: zero falhas.
- 169 verificações da cena de revisão: zero falhas.
- 24 capturas antes e 24 depois no jogo completo, usando save temporário isolado.

O BAT existente abre a correção ao reiniciar o jogo. Protótipos do Guardião e das outras técnicas permanecem aguardando aprovação. Nenhum push, PR, Actions ou deployment.

## Ajuste seguinte — corte projetado para frente

Thiago aprovou o dano em área e pediu que o ataque também saísse para a frente.
Acrescentado um corte em crescente que nasce junto à espada e avança na direção
capturada durante 0,14 s após o contato. O crescente possui duas pontas afuniladas
e rastro curto, sem recorte de textura. A energia circular permanece. É somente
apresentação: não há segundo projétil de dano, alcance novo ou acerto adicional.
Teste renderizado ampliado: 394 verificações, zero falhas. Detecta o avanço real
dos pixels do crescente em duas posições e quatro direções; mantém perímetro,
movimento, Dash e acertos conforme a linha de visão real do cenário.
