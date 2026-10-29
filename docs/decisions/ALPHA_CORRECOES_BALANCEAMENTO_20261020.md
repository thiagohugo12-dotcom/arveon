# Alpha 0.2 — correções de interface e combate (2026-10-20)

Valores provisórios aprovados para os testes da Alpha.

## Causa e correção

- Toques: a emulação de toque e mouse permanece habilitada; mochila e proficiências mantêm seus botões e passam por teste real de `InputEventScreenTouch` em 390 × 844.
- Andar 1: a cena inicia com o renderizador visual V2. Elementos com ordenação por profundidade recebem desenho de segurança no primeiro quadro e depois passam aos sprites ordenados.
- Inimigos ágeis: antes recuavam a menos de 74 unidades, embora o contato exigisse cerca de 36. Agora se aproximam, avisam por 0,34 s e atacam até 56 unidades; afastar-se durante o aviso evita o dano.
- Sprites do Andar 2: mantida a grade aprovada de 72 × 64, validada com margem transparente em todos os quadros usados.

## Valores alterados

| Inimigo | HP anterior | HP novo | Dano anterior | Dano novo |
|---|---:|---:|---:|---:|
| Ágil do Andar 1 | 30 | 36 | 5 | 7 |
| Goblin Garimpeiro (base) | 42 | 52 | 6 | 8 |
| Tatu Rochoso (base) | 95 | 108 | 9 | 11 |
| Escorpião da Chapada (base) | 62 | 72 | 11 | 13 |

No Andar 2, o multiplicador existente de 1,2 continua aplicado. Os danos legíveis dos guardiões subiram aproximadamente 11% a 15%, sem alterar tempos de aviso ou áreas de esquiva.

## Armas

Os perfis atuais foram preservados após revisão: espada 120/0,65 s; machado 105/0,90 s; lança 170/0,75 s; arco 300/0,80 s; cajado 260/0,95 s. Dano, atributos, raridade, proficiência e aprimoramento continuam calculados pelos sistemas compartilhados existentes.
