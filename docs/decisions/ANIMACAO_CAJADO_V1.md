# Cajado V1 — demonstração isolada

Status: APROVADA para desenvolver/publicar demonstração pelo pedido de Thiago
de 14/10/2026. Integração ao jogo depende de aprovação visual posterior.

- Base: 10f00de. Checkpoint: checkpoint-antes-cajado-v1-2026-10-14.
- Reutilizar o explorador, pernas, filtros, rig de braços curtos e estrutura
  Antes/Agora. Nenhum arquivo/atlas aprovado de espada ou arco será refeito.
- Quatro direções e fases próprias: preparação, canalização, disparo,
  recuperação. Cajado pequeno de madeira, ponta verde-azulada, poucos brilhos.
- Preparação somente visual durante cooldown com alvo válido. O sinal real
  dispara a pose e o orbe no mesmo ciclo. Primeiro disparo pronto é imediato.
- AutoAttack/PlayerProjectile continuam responsáveis por cadência, rastreio,
  dano mágico, alcance, velocidade e colisão. Somente origem/desenho visual
  do orbe do básico são substituídos na demonstração.
- Reutilizar dois mundos/alvos da demonstração do arco. Sem Main, save,
  recompensas ou conexão de recibos à proficiência. Skills/Ultimates/passivas
  não recebem alterações; a apresentação nova aceita apenas source=basic.
- Preview exclusivo amostra-cajado/index.html. Política de publicação deve
  bloquear o alias TESTE e conferir seus hashes originais.
- Não integrar Cajado, iniciar Machado/Lança, alterar andares, cenário, main
  ou produção. Limpar poses ao morrer/trocar arma/bloquear controles.
