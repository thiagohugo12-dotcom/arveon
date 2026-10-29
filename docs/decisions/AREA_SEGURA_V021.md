# ADR: base mínima da Área Segura — v0.2.1

Status: APROVADA
Autor / data: Codex / 2026-10-08

## Decisão vigente e evidências

Branch examinada: `feat/andar1-v020-primeiro-passe`, commit
`3e9f0c3a71bd75538d424e49bed426ab87db31d1`.
`scripts/main.gd` mantém ouro, XP, abates e materiais apenas em memória;
`CommonMission` concede recompensas reais. Não existe inventário persistente,
serviço de salvamento, loja ou evolução de equipamentos. Morte oferece recarregar
a cena, não retorno com penalidades seletivas. GAME_DESIGN registra capacidade,
percentuais de morte e valores de economia como pendentes.

## Proposta mínima, aguardando aprovação

- Reutilizar os materiais existentes como mochila empilhável; baú separado somente
  como destino de transferência, sem segunda carteira ou economia paralela.
  Sem limite de slots nesta versão experimental, até definição de capacidade.
- Persistir localmente mochila, baú, ouro, XP, abates e estado da missão em um
  único save versionado. Na Web, armazenamento por navegador e domínio, sem
  sincronização entre dispositivos; limpar dados do site pode apagar progresso.
- Loja compra e vende somente materiais existentes: Couro, Seda e Essência.
  Preços experimentais propostos: comprar por 5 ouro e vender por 2 ouro por unidade.
  Broto Ancestral não comercializável. Não introduzir poções ou equipamentos fictícios.
- Ferreiro tem NPC e interface informativa do equipamento inicial; sem cobrança,
  botão de melhoria funcional ou receita inventada. Evolução fica explicitamente indisponível.
- Morte retorna ao acampamento, preserva equipamento e baú e perde uma unidade de
  material da mochila, quando houver. Não adicionar perda de XP/ouro enquanto
  seus percentuais não forem aprovados. Exibir essa limitação na interface/documentação.
- Acampamento no mapa atual, proteção física exclusiva contra inimigos e bloqueio
  de ataques/projéteis; interação E e botão touch contextual, sem Andar 2.

## Impacto e alternativas

Sem backend, autoload global, plugins, shaders ou novos sistemas de equipamentos.
Um estado de progresso compartilhado pelo loot, missões, transferências e loja.
Alternativa: dono fornecer capacidade, mercadorias, preços e penalidades diferentes
antes da implementação. Não implementar regras desta proposta sem aprovação.

## Aprovação explícita do dono

Thiago respondeu "Aprovo" nesta conversa em 2026-10-08 à proposta acima.

## Validação e rollback

Testar transferências sem duplicação/perda, persistência, saldo insuficiente,
missões, morte seletiva, proteção contra contato/investida/projéteis, teclado e
layout touch nas duas orientações. Importar e exportar com Godot 4.5.1, executar
runner headless e publicar somente TESTE. Nenhuma alteração em main ou produção.
Save versionado deve rejeitar dados inválidos sem sobrescrever silenciosamente
o arquivo original. Testes usam caminhos isolados, nunca o save real.
