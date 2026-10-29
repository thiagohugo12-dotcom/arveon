# ADR: materiais por raridade e armas individuais

Status: APROVADA

Autor / data: Thiago, pedido colado em 18/10/2026; implementação local em 18/10/2026.

Decisão vigente: o Andar 1 passa a sortear ocorrência e raridade do material separadamente. Armas são instâncias independentes com raridade, aprimoramento +0 a +20 e bônus permanentes escolhidos nos marcos +5, +10, +15 e +20. Mítica continua reservada. Armaduras e acessórios mantêm as regras antigas.

Problema e evidências: o save v11 guardava no máximo uma arma por categoria e o inimigo concedia um material comum fixo. O Ferreiro só fabricava/melhorava por ID de categoria até +3.

Implementação: `EquipmentEconomy` concentra as tabelas provisórias. `GameProgress.weapon_instances` usa UID estável e o UID equipado; `equipment` mantém o espelho da categoria para o combate e os itens antigos. `bag` e `chest` usam `Tipo|raridade` para materiais acima de comum. O save v12 valida as instâncias integralmente antes de aplicar o estado; versões anteriores são convertidas.

Balanceamento provisório:

| Fonte | Ocorrência | Comum | Incomum | Raro |
| --- | ---: | ---: | ---: | ---: |
| Javali, Aranha, Mandacaru | 35% | 88% | 10% | 2% |
| Elite | 55% | 65% | 28% | 7% |
| Guardião | 75% | 45% | 40% | 15% |

Cada entrada da tabela é independente e a soma condicional de raridades é 100%. A fabricação usa 3 Madeiras comuns, material principal e Essência na raridade da arma, mais 20+25×nível de raridade de ouro. Evolução usa Essência e Couro da próxima raridade e 50+50×nível atual de ouro. O vendedor oferece materiais por raridade e Selo de Proteção de teste por 50 ouro. Aprimorar custa 10+8×nível+10×nível de raridade de ouro e Essência da raridade da arma. Chances por tentativa: +1–5 100%; +6–10 90–75%; +11–15 70–50%; +16–20 45–25%. Nas faixas altas, falha rebaixa 1 nível ou 1–2 níveis, com 50% de chance de perder 2 na última faixa. O selo evita a perda e só é consumido quando faria diferença.

Os bônus por categoria e marco estão em `EquipmentEconomy.BONUS_TEMPLATES`; +20 multiplica por quatro o valor base. Opções usam apenas atributos já presentes no combate: dano físico/mágico, crítico, intervalo básico, HP, defesa e Espírito.

Impacto: nenhuma regra do Andar 2, mineração, habilidades ou proficiência foi alterada. O modo treino recebe cinco raridades das cinco categorias e suprimentos descartáveis. O custo provisório pode ser ajustado somente nas tabelas. Os ícones de arma usam a arte existente com moldura de raridade e marcas discretas de aprimoramento.

Plano de validação: testes determinísticos de drops, receitas, cópias, falhas, selo, bônus, save e treino; suíte local; capturas reais de mochila e Ferreiro a 390×844 e 320×640. Rollback por unidade de arquivo, sem redefinir o restante do projeto.
