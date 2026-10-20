# Ficha do Personagem local — 17/10/2026

Status: APROVADA. Thiago solicitou reunir atributos, mochila e equipamento em
uma ficha maior, no lugar da navegação que separava essas informações em muitas
telas. A implementação local foi autorizada pelo pedido “vamos fazer” e pela
continuidade para a próxima tela.

## Decisão

A página inicial do Diário passa a se chamar **Ficha do Personagem**. Ela reúne:

- classe, nível e resumo de combate;
- seis atributos distribuíveis e seus botões existentes;
- três equipamentos ativos, com atalho para a gestão detalhada;
- materiais da mochila, com ícone e quantidade.

A gestão detalhada de equipamentos, comparação e equipar/desequipar permanece
na Mochila completa, aberta somente pelo atalho da ficha. Proficiências e
Habilidades continuam como páginas próprias do Diário.

## Limites

Somente apresentação e navegação local. Não altera itens, atributos, custos,
ações, regras de treino, combate, progressão, save v11 ou Andar 1. Os mesmos
handlers e validações de equipar, desequipar e distribuir atributos são usados.

## Validação

Verificar a ficha nas quatro resoluções mobile existentes, a abertura da Mochila
completa, distribuição de atributos, comparação/equipamento e regressões de
save. Rollback: restaurar a abertura anterior da Mochila e a composição da
página inicial do Diário.
