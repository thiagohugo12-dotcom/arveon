class_name TestBuild
extends RefCounted

# Atalhos só da versão de TESTE publicada na Vercel: viagem livre pela Torre entre os
# andares que existem e ouro infinito. O workflow de TESTE troca ENABLED para true antes
# de exportar; o arquivo versionado (e portanto a produção) fica sempre com false.
const ENABLED := false
const GOLD := 999999

static func active() -> bool:
	return ENABLED or OS.get_environment("ARVEON_TEST_BUILD") == "1"

# Andar com conteúdo no jogo, liberado na Torre mesmo sem a Prova do andar anterior.
static func free_travel(id: int) -> bool:
	return active() and FloorCatalog.has_floor(id)
