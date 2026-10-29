# Habilidades do Cajado — primeiro estudo visual local

Status: APROVADA E IMPLEMENTADA LOCALMENTE em 17/10/2026.

Autor / data: Thiago e Codex · 17/10/2026.

Decisão vigente: o ataque básico e Orbe Arcano já usam o cajado aprovado. Onda
Arcana, Selo Místico, Barreira Espiritual e Tempestade Arcana existem no catálogo
com área, duração, dano, marca, controle e proteção próprios.

Problema e evidências: as técnicas adicionais do cajado ainda usam apresentação
genérica. Thiago pediu começar a animação do cajado após aprovar as skills do
arqueiro e pedir ajuste de tamanho e velocidade das flechas.

Proposta: `outputs/previa-skills-cajado.html` usa o mesmo explorador e o atlas
existente do cajado. Onda Arcana expande um pulso circular; Selo Místico forma
runas e sinaliza a marca; Barreira Espiritual envolve o personagem; Tempestade
Arcana cria uma corrente e impactos dentro da área. A página permite quatro
direções, pausa, avanço de tempo e visualização da área do catálogo.

Impacto no Game Design, desempenho, compatibilidade e saves: a prévia continua
HTML isolado. A integração reutiliza o atlas e uma instância visual por efeito,
sem novo save. Geometrias, dano, marca, controle e duração da Barreira permanecem
os do catálogo. O contato das três técnicas ofensivas acompanha a animação.

Aprovação explícita do dono: Thiago pediu “pode implementar o cajado” em
17/10/2026, após abrir a prévia local.

Validação: teste integrado das quatro técnicas (29 verificações, zero falhas);
suíte geral (2.508 verificações, zero falhas). A conferência visual dentro do
jogo ainda depende de teste humano local. Rollback: remover a apresentação do
cajado e o agendamento das três técnicas, sem tocar no catálogo ou save.
