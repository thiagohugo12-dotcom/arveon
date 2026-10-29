# Progressão — Etapa 1

Status: APROVADA por Thiago em 12/10/2026, no pedido “NOVO SISTEMA DE
PROGRESSÃO — Etapa 1”, anexado à conversa. A aprovação explícita autoriza
a implementação desta fundação e substitui os atributos anteriores.

Checkpoint remoto: `checkpoint-antes-progressao-etapa1-2026-10-12`, commit
`7e6de4a`. Branch exclusiva `feat/andar1-v020-primeiro-passe`; somente TESTE.

## Fundação e migração

Manter curva geral, teto 100, dois pontos de atributos e um ponto compartilhado
de talento/habilidade por nível após o inicial. Seis atributos: Força +2 físico,
Vitalidade +8 HP, Resistência +0,5 pp até 25%, Mobilidade +1% movimento até 20%,
Destreza −0,75% intervalo básico até 15%, Espírito +2 mágico. Dash fixo 620.
Precisão é derivada, sem sorteio de erro. Armadura é redução plana física;
Resistência multiplica o dano restante físico ou mágico. Fúria mantém redução
atual depois delas. Arredondar o dano final para cima, mínimo 1 se dano positivo.

Save v8 introduz seis atributos; saves v1–7 validam o esquema original antes
de migrar. Agilidade é removida e devolvida pelo orçamento derivado: nenhum
saldo extra persistido, nenhuma duplicação no próximo carregamento.
Save v9 acrescenta domínio e nova curva de proficiência. v7–8 convertem a
curva antiga 10(N−1)N para 4(N−1)N, conservando nível e fração (arredondada
para baixo ao XP inteiro). Árvores, compras, equipamentos, economia e cinco
andares são validados integralmente antes da troca atômica em memória.

## Proficiência e dano (balanceamento provisório)

Um XP por dez pontos de vida efetivamente removidos, limitado ao orçamento de HP
original de cada vida do inimigo; regeneração não reabre orçamento. Sem bônus
por acerto ou arredondamento por golpe: o resto 0–9 fica salvo por categoria.
A taxa 0,1 XP/HP é provisória; 1 XP/HP encerraria a proficiência perto da
primeira prova, incompatível com a validação de progressão pelos cinco andares.
Sem bônus por morte nesta etapa. IDs por execução/impacto e alvo impedem reaplicação;
as verificações de origem/andar/tentativa continuam no Main. Projétil captura
categoria, tipo de dano, crítico e ID na emissão; nenhum bônus troca em voo.

Níveis 1–30, +0,5% de dano da categoria e um ponto de domínio por nível após
o primeiro. Dano básico +1%/ponto (12), especial +1,25% (12), crítico +1 pp
(10), multiplicador crítico +3 pp (10), bases 5% e 150%. Orçamentos separados.
Ordem: base + atributo + equipamento + passiva plana; bônus de proficiência
e domínio somados em um único fator; multiplicador da técnica/Fúria; crítico;
arredondamento único. Corte/Investida continuam técnicas físicas; cajado tem
básico mágico. Dano Especial não altera duração nem resistência da Fúria.

## Próximas etapas reservadas

Preservar os três efeitos atuais e os nós temporários, sem inventar técnicas.
Futuro: Skill 1 por arma individual; Skills 2/3 e duas passivas por categoria,
configurações próprias; duas especializações no nível 18, uma ativa; Maestria
no 30. Redistribuição gratuita na área segura para árvores existentes pode
ser feita sem efeitos novos. Ultimate usa um dos três slots. HUD segue três
skills, Dash e poção separada. Sem novos andares ou alteração visual do mundo.

Curva e taxas permanecem provisórias: simular orçamento dos cinco andares e
registrar estimativa de tempo; medir sessões humanas em mobile antes de
declarar balanceamento definitivo.
