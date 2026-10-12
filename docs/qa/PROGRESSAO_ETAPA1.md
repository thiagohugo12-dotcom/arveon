# Progressão — evidências e limites

Checkpoint remoto anterior: `checkpoint-antes-progressao-etapa1-2026-10-12`
(`7e6de4a`). Implementação: `103fb4a` (atributos/migração), `5203862`
(proficiência/domínio/combate), `14fa4a3` (diário), seguida da integração/QA.

## Executado localmente em Godot 4.5.1

- Fundação: 1.490 verificações, zero falhas.
- Proficiência: 1.716 verificações, zero falhas.
- Diário: 1.776 verificações, zero falhas.
- Integração final: 1.802 verificações, zero falhas.
- Journal do navegador: nove testes Node, nove aprovados.
- Renderização Compatibility: 20 capturas em 360×640, 390×844, 640×360,
  960×540; atributos, domínio, ação de distribuir, árvore e skills.
- Toques reais do fluxo Godot: seis atributos, cinco categorias, quatro
  atributos de domínio, compra/rolagem/fechamento, pedido duplicado rejeitado.

As capturas estão em `docs/qa/progressao-etapa1/`. O CI também executa as
257 capturas anteriores, exporta Web, testa persistência em Chromium e só
então publica TESTE, verificando SHA-256 do HTML/PCK no alias fixo.
O resultado do CI e seu commit devem ser consultados na entrega desta conversa.
Nenhuma sessão humana prolongada em aparelho físico foi realizada pelo agente.

## Saves

Migração v1–8 aceita somente o formato de cada versão. v4–7 conservam Força,
Vitalidade e Espírito, removem Agilidade e devolvem seu investimento pelo
orçamento de atributos. Mobilidade/Destreza começam em zero. v7–8 conservam
nível de proficiência e fração na curva nova; todos os 30 níveis foram testados.
Árvores, graus comprados e equipamentos/upgrades são preservados.

Fixture v7: nível geral 40, sete pontos antigos em Agilidade, seis nós de
Espada, Corte grau 3, cajado +2, ouro 777, mochila/baú e cinco andares completos
com exploração. Carregar, salvar, exportar/importar com checksum e recarregar
produzem o mesmo estado v9; o original `.v7.original` permanece idêntico byte
a byte. Importar novamente não soma pontos, recompensas ou itens.
Novos dados de domínio inválidos/futuros/corrompidos são rejeitados atomicamente.
Os testes Chromium incluem essa migração v7 no próprio export Web.

## Exemplos calculados e testados

Nível 20; Força 4, Vitalidade 4, Resistência 6, Mobilidade 5, Destreza 5,
Espírito 4; arma +0, sem armadura/acessório. Proficiência 10 na categoria;
domínio Dano 3, Especial 2, Crítico 2, Dano Crítico 2. HP 132, Resistência 3%,
10 pontos de atributos livres, chance crítica 7%, multiplicador 156%.
Ataques +7,5%, técnicas +7%, intervalo básico −3,75%; Dash permanece 620.

| Arma / classe | Básico | Básico crítico | Corte físico | Intervalo | Movimento |
|---|---:|---:|---:|---:|---:|
| Espada / Espadachim | 22 físico | 34 | 30 | 0,625625 s | 189 |
| Machado / Guerreiro de Machado | 26 físico | 40 | 36 | 0,86625 s | 184,8 |
| Lança / Lanceiro | 24 físico | 37 | 33 | 0,721875 s | 195,3 |
| Arco / Arqueiro | 22 físico | 34 | 30 | 0,77 s | 189 |
| Cajado / Místico | 26 mágico | 40 | 30 | 0,914375 s | 189 |

O Corte atual continua físico inclusive com cajado; técnicas mágicas novas
aguardam definição. Espírito e bônus do cajado afetam seu básico mágico.
Domínio especial não estende Fúria nem amplia resistência/cura/controle.

## Simulação provisória dos cinco andares

Cenário determinístico: uma categoria do começo ao fim, sem atributos,
melhorias, pontos de domínio gastos, críticos, skills ou perdas; por andar,
50 criaturas na distribuição normal de tipos, três hordas e Guardião.
HP e intervalos são os valores reais do projeto. Somente tempo de ataques:
não inclui deslocamento, avisos, recuperação, menus, alcance/projéteis ou morte.
Não é um playthrough nem estimativa definitiva da duração da campanha.

| Após andar | HP efetivo acumulado | XP da categoria | Proficiência |
|---|---:|---:|---:|
| 1 | 3.976 | 397 | 10 |
| 2 | 8.759 | 875 | 15 |
| 3 | 14.329 | 1.432 | 19 |
| 4 | 20.687 | 2.068 | 23 |
| 5 | 27.832 | 2.783 | 26 |

Tempo de ataque acumulado: Espada 24,71 min; Machado 25,94; Lança 25,18;
Arco 30,41; Cajado 27,38. Todas recebem o mesmo XP pelo mesmo HP removido.
Proficiência 30 requer 34.800 HP efetivos nessa taxa, cerca de 25% mais combate
que o cenário acima. Trocar categorias divide o progresso; builds/skills mudam
o tempo, mas não XP por alvo. Medir sessões reais antes de ajustar curva/taxa.
O runner gera `build/progression-calculations.json` com o relatório reproduzível.

## Próxima etapa

Definir técnicas e passivas por categoria, duas especializações no 18 (uma
ativa), efeito final de Maestria no 30, Skill 1 da arma individual, duas skills
escolhidas da categoria e duas passivas equipadas, salvas por categoria.
Preservados temporariamente os nós atuais e os três efeitos existentes.
Nenhum novo andar, monstro, NPC, economia ou direção visual foi criado.
