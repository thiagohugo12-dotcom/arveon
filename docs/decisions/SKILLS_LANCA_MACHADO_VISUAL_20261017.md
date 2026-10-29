# Habilidades da Lança e do Machado — estudos visuais locais

Status: MACHADO E LANÇA IMPLEMENTADOS LOCALMENTE.

Autor / data: Thiago e Codex · 17/10/2026.

Decisão vigente: os ataques básicos e as Skills 1 de lança e machado já usam
sprites aprovados no jogo. As técnicas adicionais continuam com apresentação
genérica, mas têm regras de área, alcance, dano, marca, controle e duração no
catálogo atual.

Problema e evidências: após aprovar a prévia e pedir a integração das skills do
cajado, Thiago pediu fazer as animações da lança e do machado.

Proposta: duas prévias locais, `outputs/previa-skills-lanca.html` e
`outputs/previa-skills-machado.html`, compartilham o mesmo controlador visual e
reutilizam o explorador e os atlas existentes. Lança: Estocada Longa, Varredura,
Marca de Caça e Muralha de Lanças. Machado: Golpe Devastador, Quebra-Guarda,
Impacto Brutal e Fúria do Machado. Cada página oferece quatro direções, pausa,
avanço de tempo e área real do catálogo. A Fúria tem prévia curta, sem propor
alteração dos oito segundos reais do buff.

Impacto no Game Design, desempenho, compatibilidade e saves: somente HTML, CSS
e JS isolados, sem Main, dano, gravação, novos atlas ou alteração do projeto
Godot. Alcances, ângulos, hitboxes e tempos reais só mudariam após decisão
explícita. A integração futura deve sincronizar o contato visual e as regras.

Aprovação explícita do dono: Thiago autorizou começar as animações da lança e
do machado em 17/10/2026. Após avaliar a prévia do machado, pediu corrigir o
contato pela parte de baixo da lâmina e integrar o machado ao jogo local.
Na sequência, Thiago esclareceu que machado e lança precisam estar nos arquivos
do jogo local e pediu levar as duas animações ao projeto aberto pelos atalhos.

Integração: Impacto Brutal usa quadro descendente e contato luminoso à frente
dos pés; a onda circular mantém o centro e alcance reais. Golpe Devastador,
Quebra-Guarda e Impacto Brutal executam o combate original uma vez no contato.
Fúria mantém oito segundos reais; a aura segue seu temporizador. Sem alterações
no catálogo, economia ou save. Teste integrado: 29 verificações; suíte geral:
2.508 verificações, ambas sem falhas. A lança também usa o mesmo relógio físico
para Estocada Longa, Varredura, Marca de Caça e Muralha de Lanças, com seus
alcances e efeitos originais. Teste integrado da lança: 32 verificações, zero
falhas. Falta avaliação humana visual no jogo. Rollback: remover as Views e o
agendamento das técnicas; as prévias e regras originais permanecem disponíveis.

Thiago pediu reverter o refinamento visual seguinte. O jogo local e as prévias
voltaram a usar os atlas do machado e da lança e os efeitos anteriores. A
integração das habilidades, regras e saves continua como acima.
