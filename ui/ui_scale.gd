class_name UiScale
extends RefCounted

# Modo compacto (celular na horizontal): os painéis da Interface 2.0 usam menos
# altura, fontes e ícones menores e duas colunas, para exigir pouca rolagem.
# O HUD chama update() sempre que o tamanho muda; os construtores só consultam.
const COMPACT_MAX_HEIGHT := 600.0
static var compact := false

static func update(size: Vector2) -> void:
	compact = size.y < COMPACT_MAX_HEIGHT and size.x > size.y

static func px(value: float) -> int:
	return roundi(value * 0.78) if compact else roundi(value)

static func font(value: int) -> int:
	return maxi(11, roundi(value * 0.84)) if compact else value

static func icon_scale(value: int) -> int:
	return maxi(1, value - 1) if compact and value >= 2 else value
