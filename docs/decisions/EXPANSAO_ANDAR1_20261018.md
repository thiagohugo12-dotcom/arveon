# Expansão do Andar 1
Status: APROVADA — pedido explícito de Thiago, 18/10/2026.

## Decisão vigente
Expandir somente a Mata dos Primeiros Passos de 1200×900 para 1700×1350.
Preservar o acampamento e os elementos aprovados em suas posições atuais.
Adicionar Ruínas Antigas a leste/nordeste, Região Perigosa a leste, Mata
Profunda ao sul e Bosque Secreto a sudeste, com rotas principais e secundárias,
uma passagem secreta, quatro pontos de coleta e dois baús escondidos.

## Problema e evidências
A área atual termina em 1200×900. A planta enviada em 18/10/2026 propõe a
expansão principalmente para leste e sul e identifica as quatro regiões. A
arte conceitual é referência de atmosfera e exploração, não deve ser importada
como fundo. A arquitetura atual reutiliza a cena da Mata nos cinco andares.

## Proposta e alternativas
Aplicar a mudança à cena compartilhada somente quando o andar ativo for 1.
Reutilizar sprites, tiles, recursos, baús, interações, estado de exploração e
spawn já existentes. Demais andares continuam com os limites 1200×900.
Não implementar novos inimigos, chefes, missões, eventos, habilidades ou
balanceamento. O Bosque Secreto prepara um ponto de interesse visual para uso
futuro, sem evento interativo nesta etapa.

## Impacto no Game Design, desempenho, compatibilidade e saves
O escopo aprovado substitui a restrição anterior de manter as dimensões da
Mata, apenas para o Andar 1. As regras e recompensas atuais continuam válidas.
O limite existente de inimigos ativos permanece; spawns devem ser locais ao
jogador, respeitar o acampamento seguro e manter as regras de território.
Novos IDs de recursos e baús são aditivos nos mapas de persistência existentes;
nenhum campo, versão, formato ou dado de save é removido ou renomeado.
As áreas novas usam os assets e a direção artística já existentes.

## Aprovação explícita do dono
O arquivo colado “ARVÉON: Ascensão Ancestral — Expansão do Andar 1” veio
marcado na mensagem de Thiago como contendo o pedido do usuário. O próprio
texto solicita implementação real local, dimensiona o mapa, especifica as
quatro regiões e define preservações e limites. As imagens enviadas na mesma
mensagem são referências de organização e atmosfera. Registrado em 18/10/2026.

## Plano de validação e rollback
Validar visualização, limites/câmera, minimapa, rotas e colisões, interações,
coleta/abertura, saves existentes, limite e ativação dos inimigos, e viagem aos
demais andares. Reverter os arquivos de mapa para o checkpoint anterior à
implementação se houver regressão; manter o save original intocado.
