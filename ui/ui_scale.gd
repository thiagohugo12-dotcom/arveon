class_name UiScale
extends RefCounted

# Densidade da Interface 2.0.
#  - compact: celular na horizontal (altura < 600): cabeçalho de uma linha, duas colunas.
#  - dense:   painéis de serviço e de Evolução um pouco menores, para pedir menos rolagem.
#             A Derrota fica no tamanho cheio, porque cabe inteira sem rolar.
# O HUD chama update() ao abrir cada painel; os construtores só consultam.
const COMPACT_MAX_HEIGHT := 600.0
const DENSE_RATIO := 0.9
const COMPACT_RATIO := 0.78
static var compact := false
static var dense := true
static var narrow_portrait := false

static func update(size: Vector2, use_dense: bool = true) -> void:
	compact = size.y < COMPACT_MAX_HEIGHT and size.x > size.y
	dense = use_dense
	narrow_portrait = size.y > size.x and size.x <= 400.0

static func ratio() -> float:
	return COMPACT_RATIO if compact else DENSE_RATIO if dense else 1.0

static func px(value: float) -> int:
	return roundi(value * ratio())

static func font(value: int) -> int:
	if compact:
		return maxi(11, roundi(value * 0.84))
	return maxi(11, roundi(value * ratio())) if dense else value

static func icon_scale(value: int) -> int:
	return maxi(1, value - 1) if compact and value >= 2 else value
