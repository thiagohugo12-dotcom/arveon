# Arco V1 — demonstração isolada

Status: APROVADA para correção das proporções dos braços, integração ao jogo
e publicação exclusivamente no TESTE fixo, conforme pedido de 14/10/2026.
Reutilizar o atlas/rig existente, sem recriar o explorador ou a animação.
Ponto de retorno: checkpoint-antes-arco-integrado-2026-10-14 em 0f8aa5f.
Machado/Lança/Cajado e produção continuam fora do escopo.

- Base preservada: d8c48a4, checkpoint-antes-arco-v1-2026-10-13.
- Referência de qualidade: demonstração de espada 8a07d93; espada integrada
  permanece byte a byte intacta.
- Quatro direções, preparação, tensão, disparo e recuperação. Reutilizar os
  pixels do explorador aprovado e manter pernas/caminhada independentes.
- Antecipação somente durante cooldown com alvo válido. O primeiro disparo
  sem cooldown anterior continua imediato, sem atraso artificial de gameplay.
- AutoAttack e PlayerProjectile reais, sem mudanças. Uma subclasse de
  apresentação desloca somente o desenho da flecha do básico para o arco. Colisão,
  velocidade, trajetória física, alcance e dano permanecem originais.
- Antes/Agora usam o mesmo alvo EnemyActor de treino, sem IA, recompensas,
  proficiência, skills, Ultimates, passivas ou persistência.
- Demonstração amostra-arco/index.html mantida como referência.
- Aprovação recebida: publicar a integração no TESTE fixo após validação.
- Habilidades/projéteis especiais preservam sua apresentação anterior.
- Arco cancela poses ao desequipar, trocar arma, morrer, bloquear controles,
  entrar na área segura ou sair da apresentação do Andar 1.
