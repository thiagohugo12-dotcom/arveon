# Acampamento simples e arbustos — 11/10/2026

Pedido de Thiago: acrescentar arbustos visíveis e simplificar apenas as construções da área segura, seguindo a referência de vila pixel art enviada em 11/10. Base: 48910b0fd4a574209c7f871e8894ba467d612a47.

Cabana com telhado terracota, paredes creme, madeira quente e janela azul. Loja com toldo creme/vermelho e dois sacos grandes no balcão. Ferreiro com abrigo de madeira, toldo laranja, forno de pedra e bigorna. Detalhes amplos para leitura mobile. Atlas camp_simple.png mantém a região do portal original; apenas CABIN, MARKET e FORGE são substituídos. Dimensões e pontos de interação existentes preservados.

Arbustos usam o sprite aprovado em nature_simple.png, em um passe determinístico separado, limitado a 18. Respeita exclusões de trilhas, área segura, pedras, recursos, baús e posições reservadas; evita as copas das árvores e mantém espaçamento de 64 pixels entre arbustos. São decoração sem colisões, processos ou nós adicionais. Chão, caminhos, árvores, NPCs, Torre, regras e saves preservados. Apenas Andar 1 usa o novo atlas.

Arte gerada com a ferramenta integrada imagegen. Prompts: cabana compacta com telhado terracota, paredes creme e madeira quente; barraca com toldo creme e duas faixas vermelhas, balcão com dois sacos; ferreiro compacto com toldo laranja, forno e bigorna. Todos pedem pixel art top-down com cores simples, poucos detalhes, transparência e sem cenário. Segunda passagem do ferreiro pediu remoção de brilho e fundo. Preparação offline no Godot: alpha binário para remover franjas, recorte e encaixe proporcional, redução nearest para resolução nativa e ampliação 2x. Fontes geradas não entram no pacote Web.

Validação local: importação Godot 4.5.1; 34 verificações de renderização em 360x640, 390x844, 640x360 e 960x540 sem falhas. Capturas revisadas em escala real. Suíte de gameplay e validação Web registradas na entrega/CI. Celular físico não testado; estilo adaptado à escala existente, sem promessa de reprodução pixel a pixel da imagem de referência.
