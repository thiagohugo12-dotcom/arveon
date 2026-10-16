# Animações de três técnicas da Espada — 15/10/2026

Status: IMPLEMENTADO, conforme as três referências aprovadas enviadas por Thiago.

- Guarda Reativa: postura e aro azul durante a guarda; impacto visual curto ao receber um golpe protegido.
- Estocada Precisa: postura de espada e rastro azul em linha na direção do golpe.
- Kamusari: novo nome exibido para a Ultimate da Espada, com corte vermelho amplo.
- O identificador persistente da Ultimate continua `danca_laminas` para preservar os saves v11.
- As referências enviadas são quadros de direção artística, não atlas de sprites isolados. A apresentação reutiliza o atlas aprovado da Espada e efeitos leves desenhados pela Godot.
- `ClassCombat` continua executando o mesmo dano, área, proteção, custo e tempo de recarga. A animação inicia somente após a execução autorizada. A guarda não ganha novo contra-ataque de dano; apenas feedback visual ao bloquear.
- Recursos das outras quatro armas e as missões continuam inalterados.

Validar em viewport vertical, horizontal, desktop e export Web no TESTE.
