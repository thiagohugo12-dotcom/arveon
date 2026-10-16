class_name AbilityRules
extends RefCounted

# Etapa 2: contract of independent weapon categories. Numerical values are provisional.
const CHARGE_HP_PER_POINT := 10
const MAX_ULTIMATE_CHARGE := 100
const GLOBAL_ULTIMATE_INTERVAL := 10.0
const MAX_NORMAL_GRADE := 4
const WEAPON_SKILLS := {"espada":"talho_agil","machado":"racha_chao","lanca":"impulso_perfurante","arco":"flecha_certeira","cajado":"orbe_arcano"}
const CATEGORIES := {
	"espada": {
		"skill1": {"id":"talho_agil","name":"Talho Ágil","cooldown":6.0,"power":1.35,"type":"physical"},
		"normal": [
			{"id":"corte_crescente","name":"Corte Crescente","prof":3,"cooldown":7.0,"power":1.45,"type":"physical"},
			{"id":"guarda_reativa","name":"Guarda Reativa","prof":8,"cooldown":12.0,"power":0.0,"type":"defense"},
			{"id":"estocada_precisa","name":"Estocada Precisa","prof":25,"cooldown":10.0,"power":1.80,"type":"physical"},
			{"id":"ruptura_ancestral","name":"Ruptura Ancestral","prof":40,"cooldown":14.0,"power":2.25,"type":"physical"}],
		"ultimate":{"id":"danca_laminas","name":"Kamusari","prof":15,"type":"physical"},
		"passives":[{"id":"fio_afiado","name":"Fio Afiado","prof":5},{"id":"ritmo_combate","name":"Ritmo de Combate","prof":12},{"id":"postura_firme","name":"Postura Firme","prof":20},
			{"id":"instinto_veterano","name":"Instinto Veterano","prof":35},
			{"id":"vontade_ancestral","name":"Vontade Ancestral","prof":50}],
		"specializations":["duelista","guardiao_lamina"],
		"mastery":"Lâmina Perfeita"},
	"machado": {
		"skill1":{"id":"racha_chao","name":"Racha-Chão","cooldown":10.0,"power":1.60,"type":"physical"},
		"normal":[
			{"id":"golpe_devastador","name":"Golpe Devastador","prof":3,"cooldown":9.0,"power":1.70,"type":"physical"},
			{"id":"quebra_guarda","name":"Quebra-Guarda","prof":8,"cooldown":11.0,"power":1.30,"type":"physical"},
			{"id":"impacto_brutal","name":"Impacto Brutal","prof":25,"cooldown":12.0,"power":2.10,"type":"physical"}],
		"ultimate":{"id":"furia_machado","name":"Fúria do Machado","prof":15,"type":"buff"},
		"passives":[{"id":"golpe_pesado","name":"Golpe Pesado","prof":5},{"id":"pele_ferro","name":"Pele de Ferro","prof":12},{"id":"executor","name":"Executor","prof":20}],
		"specializations":["berserker","colosso"],"mastery":"Força Implacável"},
	"lanca": {
		"skill1":{"id":"impulso_perfurante","name":"Impulso Perfurante","cooldown":8.0,"power":1.40,"type":"physical"},
		"normal":[
			{"id":"estocada_longa","name":"Estocada Longa","prof":3,"cooldown":8.0,"power":1.50,"type":"physical"},
			{"id":"varredura","name":"Varredura","prof":8,"cooldown":10.0,"power":1.25,"type":"physical"},
			{"id":"marca_caca","name":"Marca de Caça","prof":25,"cooldown":12.0,"power":1.05,"type":"physical"}],
		"ultimate":{"id":"muralha_lancas","name":"Muralha de Lanças","prof":15,"type":"physical"},
		"passives":[{"id":"alcance_treinado","name":"Alcance Treinado","prof":5},{"id":"vigilancia","name":"Vigilância","prof":12},{"id":"ponta_precisa","name":"Ponta Precisa","prof":20}],
		"specializations":["cacador","sentinela"],"mastery":"Domínio da Distância"},
	"arco": {
		"skill1":{"id":"flecha_certeira","name":"Flecha Certeira","cooldown":8.0,"power":1.45,"type":"physical"},
		"normal":[
			{"id":"rajada_flechas","name":"Rajada de Flechas","prof":3,"cooldown":9.0,"power":0.55,"type":"physical"},
			{"id":"tiro_marcado","name":"Tiro Marcado","prof":8,"cooldown":11.0,"power":1.35,"type":"physical"},
			{"id":"flecha_perfurante","name":"Flecha Perfurante","prof":25,"cooldown":12.0,"power":1.75,"type":"physical"}],
		"ultimate":{"id":"chuva_flechas","name":"Chuva de Flechas","prof":15,"type":"physical"},
		"passives":[{"id":"mira_instintiva","name":"Mira Instintiva","prof":5},{"id":"passos_leves","name":"Passos Leves","prof":12},{"id":"cacador_preciso","name":"Caçador Preciso","prof":20}],
		"specializations":["atirador_elite","batedor"],"mastery":"Olho de Águia"},
	"cajado": {
		"skill1":{"id":"orbe_arcano","name":"Orbe Arcano","cooldown":9.0,"power":1.45,"type":"magical"},
		"normal":[
			{"id":"onda_arcana","name":"Onda Arcana","prof":3,"cooldown":9.0,"power":1.50,"type":"magical"},
			{"id":"selo_mistico","name":"Selo Místico","prof":8,"cooldown":11.0,"power":1.20,"type":"magical"},
			{"id":"barreira_espiritual","name":"Barreira Espiritual","prof":25,"cooldown":16.0,"power":0.0,"type":"defense"}],
		"ultimate":{"id":"tempestade_arcana","name":"Tempestade Arcana","prof":15,"type":"magical"},
		"passives":[{"id":"canalizacao","name":"Canalização","prof":5},{"id":"foco_arcano","name":"Foco Arcano","prof":12},{"id":"guarda_eter","name":"Guarda do Éter","prof":20}],
		"specializations":["arcanista","guardiao_espiritual"],"mastery":"Convergência Arcana"}}
const TALENTS := {
	"espada":[{"id":"sequencia_precisa","prof":10,"parent":""},{"id":"contra_ataque_fatal","prof":20,"parent":"sequencia_precisa"},{"id":"guarda_aperfeicoada","prof":10,"parent":""},{"id":"postura_equilibrada","prof":20,"parent":"guarda_aperfeicoada"},
		{"id":"ritmo_afiado","prof":45,"parent":"sequencia_precisa"},
		{"id":"bastiao_ancestral","prof":55,"parent":"postura_equilibrada"}],
	"machado":[{"id":"impacto_crescente","prof":10,"parent":""},{"id":"finalizador","prof":20,"parent":"impacto_crescente"},{"id":"corpo_ferro","prof":10,"parent":""},{"id":"presenca_imponente","prof":20,"parent":"corpo_ferro"}],
	"lanca":[{"id":"alcance_ideal","prof":10,"parent":""},{"id":"ponta_letal","prof":20,"parent":"alcance_ideal"},{"id":"posicao_firme","prof":10,"parent":""},{"id":"recuo_tatico","prof":20,"parent":"posicao_firme"}],
	"arco":[{"id":"primeiro_disparo","prof":10,"parent":""},{"id":"mira_continua","prof":20,"parent":"primeiro_disparo"},{"id":"distancia_segura","prof":10,"parent":""},{"id":"evasao_agil","prof":20,"parent":"distancia_segura"}],
	"cajado":[{"id":"energia_focada","prof":10,"parent":""},{"id":"eco_arcano","prof":20,"parent":"energia_focada"},{"id":"veu_espiritual","prof":10,"parent":""},{"id":"protecao_mistica","prof":20,"parent":"veu_espiritual"}]}

static func active_skill(category: String, id: String) -> Dictionary:
	var data: Dictionary = CATEGORIES.get(category, {})
	if data.is_empty():
		return {}
	for ability: Dictionary in data.normal:
		if ability.id == id:
			return ability
	var ultimate: Dictionary = data.ultimate
	return ultimate if ultimate.id == id else {}

static func passive(category: String, id: String) -> Dictionary:
	var data: Dictionary = CATEGORIES.get(category, {})
	if data.is_empty():
		return {}
	for ability: Dictionary in data.passives:
		if ability.id == id:
			return ability
	return {}

static func talent(category: String, id: String) -> Dictionary:
	for entry: Dictionary in TALENTS.get(category, []):
		if entry.id == id:
			return entry
	return {}

static func available(category: String, id: String, proficiency: int) -> bool:
	var ability := active_skill(category, id)
	return not ability.is_empty() and proficiency >= int(ability.prof)

static func skill1(weapon_id: String) -> Dictionary:
	var category := ArsenalRules.weapon_category(weapon_id)
	return CATEGORIES[category].skill1 if CATEGORIES.has(category) and WEAPON_SKILLS.get(weapon_id,"") == CATEGORIES[category].skill1.id else {}

# Geometry and mechanics are provisional. No global old skill is used here.
const EFFECTS := {
	"talho_agil":{"shape":"cone","reach":120.0,"dot":0.0},
	"racha_chao":{"shape":"disk","reach":110.0,"control":0.25},
	"impulso_perfurante":{"shape":"line","reach":190.0,"width":28.0},
	"flecha_certeira":{"shape":"projectile","reach":340.0},
	"orbe_arcano":{"shape":"projectile","reach":290.0},
	"corte_crescente":{"shape":"cone","reach":140.0,"dot":-0.15},
	"guarda_reativa":{"shape":"guard","duration":3.0},
	"estocada_precisa":{"shape":"line","reach":155.0,"width":22.0},
	"ruptura_ancestral":{"shape":"line","reach":205.0,"width":40.0},
	"golpe_devastador":{"shape":"cone","reach":125.0,"dot":0.1},
	"quebra_guarda":{"shape":"cone","reach":120.0,"dot":0.0,"mark":0.18},
	"impacto_brutal":{"shape":"disk","reach":135.0,"control":0.7},
	"estocada_longa":{"shape":"line","reach":220.0,"width":24.0},
	"varredura":{"shape":"disk","reach":175.0,"control":0.4},
	"marca_caca":{"shape":"line","reach":230.0,"width":28.0,"mark":0.20},
	"rajada_flechas":{"shape":"cone","reach":310.0,"dot":0.8,"hits":3},
	"tiro_marcado":{"shape":"line","reach":330.0,"width":24.0,"mark":0.15},
	"flecha_perfurante":{"shape":"line","reach":360.0,"width":20.0},
	"onda_arcana":{"shape":"disk","reach":170.0},
	"selo_mistico":{"shape":"disk","reach":220.0,"mark":0.15,"control":0.5},
	"barreira_espiritual":{"shape":"guard","duration":5.0},
	# Stable ID for v11 saves; Kamusari is one powerful frontal energy cut.
	"danca_laminas":{"shape":"cone","reach":320.0,"dot":0.48,"power":3.4,"hits":1},
	"furia_machado":{"shape":"buff","duration":8.0},
	"muralha_lancas":{"shape":"cone","reach":250.0,"dot":0.1,"power":3.5,"control":1.0},
	"chuva_flechas":{"shape":"disk","reach":320.0,"power":3.2},
	"tempestade_arcana":{"shape":"disk","reach":230.0,"power":3.3,"control":0.6}}

static func effect(id: String, grade: int = 1) -> Dictionary:
	var result: Dictionary = EFFECTS.get(id,{}).duplicate()
	if result.has("duration"): result.duration = float(result.duration)+0.5*(grade-1)
	return result

const SPECIALIZATIONS := {
	"duelista":{"name":"Duelista","description":"Sequências no mesmo alvo aumentam o dano após três acertos."},
	"guardiao_lamina":{"name":"Guardião da Lâmina","description":"Guarda Reativa ganha barreira; contra-ataques controlam inimigos comuns."},
	"berserker":{"name":"Berserker","description":"Causa mais dano quando abaixo de metade da vida."},
	"colosso":{"name":"Colosso","description":"Acertar dois inimigos com técnica gera barreira temporária."},
	"cacador":{"name":"Caçador","description":"Explora a Marca de Caça para pressionar o alvo."},
	"sentinela":{"name":"Sentinela","description":"Recebe menos dano quando mantém a posição."},
	"atirador_elite":{"name":"Atirador de Elite","description":"Técnicas ganham precisão crítica a longa distância."},
	"batedor":{"name":"Batedor","description":"Manter movimento reduz o dano recebido."},
	"arcanista":{"name":"Arcanista","description":"Amplifica técnicas de área sem depender da força física."},
	"guardiao_espiritual":{"name":"Guardião Espiritual","description":"Técnicas ofensivas geram uma barreira curta; reforça Barreira Espiritual."}}
const DESCRIPTIONS := {
	"fio_afiado":"Críticos deixam uma abertura para o próximo ataque.",
	"ritmo_combate":"A cada três básicos válidos, reduz recargas normais em 0,3s.",
	"postura_firme":"Parado, recebe 8% menos dano.",
	"instinto_veterano":"Ataques com Espada recebem +6 pontos percentuais de chance crítica.",
	"vontade_ancestral":"Abaixo de metade do HP, recebe 10% menos dano.",
	"golpe_pesado":"Básicos interrompem brevemente inimigos comuns.",
	"pele_ferro":"Abaixo de metade da vida, recebe 10% menos dano.",
	"executor":"Causa 20% mais dano a inimigos abaixo de 30% de HP.",
	"alcance_treinado":"Aumenta em 20px o alcance básico e das técnicas.",
	"vigilancia":"Acertar um inimigo próximo abre uma janela defensiva.",
	"ponta_precisa":"Causa 10% mais dano além de 110px.",
	"mira_instintiva":"Cada terceiro básico marca o alvo por 2s.",
	"passos_leves":"Um segundo em movimento reduz dano recebido em 8%.",
	"cacador_preciso":"Causa 15% mais dano além de 180px.",
	"canalizacao":"Cada terceiro básico reduz 0,5s da recarga de Orbe Arcano.",
	"foco_arcano":"Críticos fortalecem a próxima técnica por uma janela curta.",
	"guarda_eter":"Recebe 10% menos dano enquanto possui barreira.",
	"sequencia_precisa":"Cada terceiro básico causa 15% mais dano.",
	"contra_ataque_fatal":"Técnicas na janela de contra-ataque são críticas.",
	"guarda_aperfeicoada":"Guarda Reativa dura mais um segundo.",
	"postura_equilibrada":"A guarda reduz mais 5% do dano recebido.",
	"ritmo_afiado":"Ritmo avançado: após três básicos, ataques básicos causam 8% mais dano.",
	"bastiao_ancestral":"Enquanto a guarda está ativa, recebe 8% menos dano adicional.",
	"impacto_crescente":"Básicos sucessivos no mesmo alvo aumentam o impacto.",
	"finalizador":"Técnicas causam mais dano a alvos abaixo de 20% de HP.",
	"corpo_ferro":"Acertar uma técnica concede guarda curta.",
	"presenca_imponente":"Técnicas interrompem brevemente inimigos comuns.",
	"alcance_ideal":"Favorece ataques feitos entre 100 e 170px.",
	"ponta_letal":"Técnicas na janela de posição firme são críticas.",
	"posicao_firme":"Básicos parado abrem uma janela de posicionamento.",
	"recuo_tatico":"Recebe menos dano durante o dash, sem alterar sua recarga.",
	"primeiro_disparo":"O primeiro básico no alvo interrompe inimigos comuns.",
	"mira_continua":"Três básicos no mesmo alvo expõem uma abertura.",
	"distancia_segura":"Favorece ataques a mais de 240px.",
	"evasao_agil":"Recebe menos dano durante o dash, sem alterar sua velocidade.",
	"energia_focada":"Técnicas ganham potência enquanto há barreira.",
	"eco_arcano":"Técnicas deixam uma abertura arcana no alvo.",
	"veu_espiritual":"Acertar técnicas gera uma pequena barreira temporária.",
	"protecao_mistica":"A barreira reduz mais 10% do dano recebido."}
const TALENT_NAMES := {
	"sequencia_precisa":"Sequência Precisa","contra_ataque_fatal":"Contra-ataque Fatal","guarda_aperfeicoada":"Guarda Aperfeiçoada","postura_equilibrada":"Postura Equilibrada",
	"ritmo_afiado":"Ritmo Afiado","bastiao_ancestral":"Bastião Ancestral",
	"impacto_crescente":"Impacto Crescente","finalizador":"Finalizador","corpo_ferro":"Corpo de Ferro","presenca_imponente":"Presença Imponente",
	"alcance_ideal":"Alcance Ideal","ponta_letal":"Ponta Letal","posicao_firme":"Posição Firme","recuo_tatico":"Recuo Tático",
	"primeiro_disparo":"Primeiro Disparo","mira_continua":"Mira Contínua","distancia_segura":"Distância Segura","evasao_agil":"Evasão Ágil",
	"energia_focada":"Energia Focada","eco_arcano":"Eco Arcano","veu_espiritual":"Véu Espiritual","protecao_mistica":"Proteção Mística"}
const MASTERY_HELP := {
	"espada":"Após três básicos, a próxima técnica é crítica.",
	"machado":"Técnicas ficam mais fortes quanto menor o HP do alvo.",
	"lanca":"Mantém vantagem de dano a partir de 120px.",
	"arco":"Técnicas contra alvos marcados são críticas.",
	"cajado":"Cada terceira técnica ofensiva cria barreira; a janela arcana favorece críticos."}

static func talent_tree(category: String) -> Dictionary:
	var result := {}
	var entries: Array = TALENTS.get(category,[])
	for i in range(entries.size()):
		var rule: Dictionary = entries[i].duplicate()
		rule["name"] = TALENT_NAMES[rule.id]
		rule["description"] = DESCRIPTIONS[rule.id]
		rule["icon"] = category
		rule["kind"] = "Talento"
		rule["position"] = Vector2(0.25 if i < 2 else 0.75,90 if i%2 == 0 else 200)
		result[rule.id] = rule
	return result
