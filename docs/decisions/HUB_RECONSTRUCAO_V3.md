# ADR: reconstrução visual do hub do Andar 1
Status: APROVADA
Autor / data: Codex, 2026-10-11

Problema: proporções achatadas, fontes de arte inconsistentes e composição que
não acompanha a referência de vila enviada por Thiago.

Decisão: reconstruir a apresentação do hub, com casa a nordeste, oficina a
noroeste e mercado a sudeste, conectados por clareiras e caminhos. Novos atlas
com alpha original, regiões proporcionais, nearest e escala inteira. NPCs à
frente dos serviços, com interação no local visível. Pequenas bases físicas
impedem atravessar os balcões e a fachada; não bloquear as vias de circulação.
Árvores fora das novas construções mantêm pés e colisões. As que ficariam
debaixo das estruturas são omitidas junto com seus colisores apenas no Andar 1.

Aprovação explícita: Thiago concedeu “você tem liberdade de mudar o que quiser”
e respondeu “faça então” à proposta de reconstruir o hub dentro do jogo.
Essa aprovação supera a restrição anterior de composição fixa no Andar 1.

Escopo: Andar 1 e endereço TESTE, branch feat/andar1-v020-primeiro-passe.
Dimensões do mundo, área de proteção, respawn, combate, monstros aprovados,
economia, progressão e saves preservados. Andares 2–5 preservam a apresentação.
Sem rio/ponte nesta etapa; não são necessários para validar a vila.

Validação: importação Godot, contratos existentes, serviços nos pontos visíveis,
colisões das bases, capturas landscape/portrait, exportação Web e preview TESTE.
Rollback: reverter o commit deste ADR e seus commits de implementação.
