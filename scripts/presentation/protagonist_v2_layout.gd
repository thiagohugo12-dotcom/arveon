class_name ProtagonistV2Layout
extends RefCounted
## Gerado por tools/build_protagonist_v2.gd — não editar à mão.
## Folhas em 3 texels por pixel do mundo; âncora = pés na origem do ator.
const TEXELS := 3
const SHEETS := {
	"idle": {"texture": "res://assets/art/protagonist_v2/idle.png", "cell": Vector2i(178, 196), "anchor": Vector2i(86, 194), "rows": 4, "frames": 4},
	"corrida": {"texture": "res://assets/art/protagonist_v2/corrida.png", "cell": Vector2i(233, 200), "anchor": Vector2i(110, 198), "rows": 4, "frames": 6},
	"espada_basico": {"texture": "res://assets/art/protagonist_v2/espada_basico.png", "cell": Vector2i(306, 225), "anchor": Vector2i(103, 223), "rows": 1, "frames": 6},
	"espada_estocada": {"texture": "res://assets/art/protagonist_v2/espada_estocada.png", "cell": Vector2i(385, 198), "anchor": Vector2i(107, 196), "rows": 1, "frames": 6},
	"espada_guarda": {"texture": "res://assets/art/protagonist_v2/espada_guarda.png", "cell": Vector2i(235, 243), "anchor": Vector2i(115, 241), "rows": 1, "frames": 4},
}
