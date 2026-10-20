# Habilidades do Arqueiro — primeiro estudo visual local

Status: APROVADA E IMPLEMENTADA LOCALMENTE em 17/10/2026.

Autor / data: Thiago e Codex · 17/10/2026.

Decisão vigente: Flecha Certeira (Skill 1) e o ataque básico já usam o explorador
aprovado. Rajada de Flechas, Tiro Marcado, Flecha Perfurante e Chuva de Flechas
continuam com dano, alcance, área, recarga e progressão próprios no catálogo.

Problema e evidências: a ação do corpo e o efeito dessas quatro técnicas não
comunicam com clareza qual disparo saiu, em que direção e qual área é atingida.
O usuário pediu começar as habilidades do arqueiro após a revisão do acampamento.

Proposta: prévia local em `outputs/previa-skills-arqueiro.html`, construída com
o atlas do arqueiro existente. Rajada mostra três flechas em leque; Tiro Marcado
mostra preparação e marca no alvo; Flecha Perfurante conserva uma ponta única
através da linha; Chuva de Flechas usa a área circular do catálogo. Quatro
direções, pausa, avanço de tempo e indicação de área permitem avaliar a leitura.
Os tempos da prévia orientaram a linha temporal local. O contato visual e o dano
real agora usam o mesmo marco, sem mudar as regras do catálogo.

Impacto no Game Design, desempenho, compatibilidade e saves: a prévia continua
isolada; o jogo local usa uma única instância visual reutilizável. Catálogo,
alcances 310/330/360/320, área, número de acertos e save não mudaram.

Aprovação explícita do dono: Thiago aprovou as quatro skills após corrigir a
Chuva de Flechas para queda vertical e pediu “pode implementar no local” em
17/10/2026.

Implementação: BowTechniqueEffect reproduz as quatro apresentações na cena do
Andar 1 com o atlas do arqueiro já usado no jogo. ClassCombat conserva as
geometrias, os alcances, os acertos, o dano, a recarga, a carga e o save; adia
apenas a execução para o contato visível. A linha temporal transitória cancela
por morte, troca de arma, área segura ou saída do Andar 1, e pausa em menus.
Nos outros andares segue o caminho anterior. Chuva usa flechas e rastros
verticais. Nenhum atlas novo foi criado.

Refinamento pedido por Thiago em 17/10/2026: Rajada, Tiro Marcado e Flecha
Perfurante usam flechas próximas do tamanho da básica (hastes visuais de
16/18/21 px) e viagem visual de 550 px/s, 25% acima dos 440 px/s da flecha
básica. O contato real acompanha o novo tempo de viagem. Chuva e regras do
catálogo permanecem iguais.

Validação: teste local das quatro técnicas, contato único e flechas verticais
(35 verificações, zero falhas); suíte completa (2.508 verificações, zero falhas).
Renderização visual humana ainda depende de abrir o jogo local. Rollback:
remover a apresentação e o agendamento do arco, preservando o catálogo e saves.
