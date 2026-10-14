# Arco V1 — demonstração isolada

Status: APROVADA para desenvolvimento da demonstração pelo pedido de Thiago
de 13/10/2026. Integração ao jogo e demais armas aguardam avaliação visual.

- Base preservada: d8c48a4, checkpoint-antes-arco-v1-2026-10-13.
- Referência de qualidade: demonstração de espada 8a07d93; espada integrada
  permanece byte a byte intacta.
- Quatro direções, preparação, tensão, disparo e recuperação. Reutilizar os
  pixels do explorador aprovado e manter pernas/caminhada independentes.
- Antecipação somente durante cooldown com alvo válido. O primeiro disparo
  sem cooldown anterior continua imediato, sem atraso artificial de gameplay.
- AutoAttack e PlayerProjectile reais, sem mudanças. Uma subclasse exclusiva
  da demonstração desloca somente o desenho da flecha para o arco. Colisão,
  velocidade, trajetória física, alcance e dano permanecem originais.
- Antes/Agora usam o mesmo alvo EnemyActor de treino, sem IA, recompensas,
  proficiência, skills, Ultimates, passivas ou persistência.
- Preview exclusivo amostra-arco/index.html. Nunca reatribuir TESTE fixo nem
  alterar a demonstração/preview da espada ou produção nesta etapa.
- Publicação do arco deve bloquear a rotina de alias antes de qualquer chamada
  de publicação do TESTE. Aprovação visual obrigatória antes de outras armas.
