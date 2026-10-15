/* ARVÉON — Web loader. Reuses Godot's real #status-progress and #status-notice. */
(() => {
  'use strict';
  function boot() {
    const status = document.getElementById('status');
    const progress = document.getElementById('status-progress');
    const notice = document.getElementById('status-notice');
    if (!status || !progress || !notice || status.classList.contains('arveon-loading')) return;
    const tips = [
      'O Ferreiro vende as cinco armas iniciais usando apenas ouro.',
      'Cada arma determina sua classe e possui uma proficiência própria.',
      'O Baú protege os materiais que você guarda antes de explorar.',
      'Seu ataque básico acontece automaticamente quando um alvo está ao alcance.',
      'As Skills 2 e 3 são escolhidas enquanto você está na área segura.',
      'Ultimates precisam ser equipadas e carregadas durante o combate.',
      'Explore a Mata para encontrar recursos e baús escondidos.',
      'Cada categoria de arma tem suas próprias habilidades e talentos.'
    ];
    document.title = 'ARVÉON: Ascensão Ancestral';
    const oldIcon = document.querySelector('link[rel="icon"]');
    if (oldIcon) oldIcon.href = './arveon-icon.svg';
    status.classList.add('arveon-loading');
    const art = document.createElement('div');
    art.className = 'arveon-scene';
    art.setAttribute('role', 'img');
    art.setAttribute('aria-label', 'Paisagem de ARVÉON: acampamento, floresta e torre ancestral');
    status.prepend(art);
    const footer = document.createElement('div');
    footer.className = 'arveon-footer';
    const box = document.createElement('div');
    box.className = 'arveon-tip';
    const icon = document.createElement('span');
    icon.className = 'arveon-tip-icon';
    icon.textContent = '✦';
    icon.setAttribute('aria-hidden','true');
    const text = document.createElement('span');
    text.className = 'arveon-tip-text';
    text.setAttribute('aria-live', 'polite');
    text.textContent = 'Dica: ' + tips[0];
    box.append(icon, text);
    const dots = document.createElement('div');
    dots.className = 'arveon-dots';
    dots.setAttribute('aria-hidden', 'true');
    for (let i = 0; i < 5; i++) {
      const dot = document.createElement('span');
      dot.className = 'arveon-dot';
      dot.setAttribute('aria-current', i === 0 ? 'true' : 'false');
      dots.appendChild(dot);
    }
    const caption = document.createElement('div');
    caption.className = 'arveon-loading-caption';
    caption.textContent = 'Carregando aventura...';
    progress.setAttribute('aria-label', 'Progresso real de carregamento do jogo');
    footer.append(box, dots, progress, caption, notice);
    status.appendChild(footer);
    let n = 0;
    const interval = setInterval(() => {
      if (!status.isConnected || getComputedStyle(status).display === 'none') {
        clearInterval(interval);
        return;
      }
      n = (n + 1) % tips.length;
      text.textContent = 'Dica: ' + tips[n];
      for (let i = 0; i < dots.children.length; i++)
        dots.children[i].setAttribute('aria-current', i === n % dots.children.length ? 'true' : 'false');
    }, 4500);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded',boot,{once:true});
  else boot();
})();
