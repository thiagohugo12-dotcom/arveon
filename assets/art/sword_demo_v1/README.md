# Espada — demonstração V1

`attack.png`: 480×320, seis colunas de células 80×80, quatro linhas
(frente, costas, esquerda, direita). Pivô dos pés: (40,52).
Somente tronco/braço/espada/arco; pernas reutilizam a caminhada aprovada.

Colunas: preparação, golpe, impacto, recuperação inicial/intermediária/final.
Quatro poses-chave e duas transições de recuperação. No runtime, escala 2×,
NEAREST, sem interpolação, rotação ou deformação do sprite.

Fonte: `actors_v4/people.png`, `diary_v2/items_skin.png`. Originais intactos.
Regenerar na Godot 4.5.1 com renderização Compatibility:

`godot --path . --rendering-method gl_compatibility --script res://tools/bake_sword_demo.gd`

O rig em `tools/sword_pose_rig.gd` recorta o braço aprovado, fixa o cabo na
mão e desloca a parte superior em um pixel. A rasterização ocorre em 80×80,
antes da ampliação. Nenhuma alteração de hitbox, cadência ou dano.
