# Arco V1 — atlas exclusivo da demonstração

Explorador original: `actors_v4/people.png`, sem alteração de seus pixels.
Rig de braços, arco e corda: `tools/bow_pose_rig.gd`. Bake reproduzível pelo
Godot 4.5.1: `--path . --audio-driver Dummy --rendering-method gl_compatibility
--script res://tools/bake_bow_demo.gd` (requer renderização GL).

- 640×320 RGBA, oito células de 80×80 por linha; pés em (40,52).
- Linhas: frente, costas, esquerda, direita.
- Quadros 0–1: preparação; 2–3: tensão; 4: corda solta, sem flecha nockada;
  5–7: recuperação. Flecha em voo pertence ao PlayerProjectile real.
- Pernas e sombra originais são desenhadas separadamente. NEAREST em 2x,
  sem rotação/estiramento do personagem durante o jogo.
- Preparação ocupa 40% do intervalo existente; disparo/recuperação 31,25%.
  Destreza altera o intervalo por suas regras originais, escalando as poses.
- MUZZLES acompanha o grip em pixels de jogo; desloca apenas a apresentação,
  nunca origem física, colisões, velocidade, dano ou alcance da flecha.
- Demo isolada. Nenhum arquivo/pose da espada substituído.
