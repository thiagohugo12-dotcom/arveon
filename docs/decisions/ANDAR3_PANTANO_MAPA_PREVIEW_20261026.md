# Andar 3 — estrutura inicial e prévia

**Status:** aprovado para a etapa inicial por solicitação explícita de Thiago em 26/10/2026.  
**Escopo aprovado:** configuração do Andar 3, mapa explorável, colisões, regiões, pontos reservados, entrada/retorno, integração inicial com o Mapa e a Torre; prévia real mobile vertical.  
**Fora desta etapa:** monstros e chefes definitivos, combate, recompensas, materiais funcionais, receitas, balanceamento e desbloqueio do Andar 4.

## Andar 3 — Pântano das Vozes

O mundo mede 1700×1350, mesma escala física dos dois andares aprovados. A rota principal liga Entrada Encharcada, Lodaçal Nebuloso, Bosque Afundado e Coração do Brejo; ramificações e clareiras reservam pontos de spawn e coleta. Os pontos usam marcadores de descoberta já persistidos por andar. A área segura e os três serviços reaproveitam `SafeCamp` e os NPCs atuais.

## Referência de combate do Andar 2

Antes de calibrar qualquer inimigo do Andar 3, o catálogo atual fornece esta referência: o multiplicador de dificuldade do Vale é 1,5 e o de recompensa é 1,1. Os dados base (HP/velocidade/contato/XP) são Goblin Garimpeiro 52/95/8/10, Tatu Rochoso 108/54/11/16 e Escorpião da Chapada 72/105/13/20. Aplicando as funções atuais, ficam HP 78/162/108, velocidades 95/54/105, contato arredondado 12/17/20 e XP escalado 11/18/22. Colosso de Arenito usa 540 HP de campo e 520 na Torre antes do fator de andar. Esses são dados observados, não propostas de balanceamento para o Pântano.

A composição atual é **provisória para validar estrutura e navegação**, feita por desenho geométrico pixelado no Godot. Não é arte final e não substitui a aprovação de sprites. Itens, baús, inimigos e chefes não são instanciados como conteúdo funcional nesta etapa. O actor legado de `Main` permanece oculto e sem colisão para preservar as referências internas sem criar combate de teste.

## Proteções

- `encounters_enabled`, `field_guardian_enabled` e `tower_enabled` permanecem falsos até a etapa posterior à aprovação do mapa.
- `FloorCatalog` dos Andares 1 e 2, seus mundos, NPCs, inimigos, colisões e valores não são alterados por este documento.
- Nenhuma versão ou formato de save muda. Os POIs do Andar 3 usam `discovered_pois` e a estrutura existente `floor_states`.
- Os itens de coleta e baús aparecem apenas como locais reservados, sem conceder materiais antes da etapa de conteúdo.

## Próxima sequência

1. Aprovar ou ajustar esta planta e a prévia temporária.
2. Produzir e aprovar os sprites próprios do Pântano: Limo do Brejo, Sapo Venenoso, Vulto do Brejo, Jacaré Ancião e Mãe dos Sussurros; cada estado precisa de movimento, ataque, dano e morte, além dos avisos dos golpes fortes.
3. Depois da aprovação de arte, calibrar inimigos, mini-chefe, chefe, itens, drops e receitas comparando o combate real do Andar 2.
4. Implementar a Cripta dos Ecos somente após validar o Andar 3; repetir a aprovação visual própria antes de integrar os atores do Andar 4.
