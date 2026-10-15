/* Native Godot onProgress is the sole owner of progress.value/max. */
(() => {
  'use strict';
  const source=document.currentScript.src;
  const artwork={desktop:'__ARVEON_DESKTOP__',mobile:'__ARVEON_MOBILE__'};
  function boot() {
    const status=document.getElementById('status');
    const progress=document.getElementById('status-progress');
    const notice=document.getElementById('status-notice');
    if(!status||!progress||!notice||status.classList.contains('arveon-loading'))return;
    document.title='ARVÉON: Ascensão Ancestral';
    status.classList.add('arveon-loading');
    status.dataset.artworkVersion='approved-20261015';
    const stage=document.createElement('div');stage.className='arveon-scene';
    const picture=document.createElement('picture');picture.className='arveon-art';
    const mobile=document.createElement('source');mobile.media='(max-width:767px)';
    mobile.srcset=new URL(artwork.mobile,source).href;
    const image=document.createElement('img');image.src=new URL(artwork.desktop,source).href;
    image.alt='ARVÉON: Ascensão Ancestral — acampamento, floresta e aventureiro';
    image.width=1536;image.height=864;image.decoding='sync';image.fetchPriority='high';
    picture.append(mobile,image);
    const tip=document.createElement('div');tip.className='arveon-tip-text';
    tip.setAttribute('aria-live','polite');
    const tips=[
      'Experimente armas e evolua sua proficiência.',
      'Sua arma equipada determina sua classe.',
      'Guarde materiais no Baú antes de explorar.',
      'O ataque básico acontece automaticamente.',
      'Escolha as Skills 2 e 3 na área segura.',
      'Equipe sua Ultimate para carregar em combate.',
      'Explore a Mata: encontre recursos e baús.',
      'Cada arma tem habilidades e talentos próprios.'
    ];
    tip.textContent=tips[0];
    const meter=document.createElement('div');meter.className='arveon-meter';
    progress.setAttribute('aria-label','Progresso real de carregamento do jogo');
    meter.append(progress);
    const caption=document.createElement('span');caption.className='arveon-loading-caption';
    caption.textContent='Carregando aventura...';
    stage.append(picture,tip,meter,caption);status.prepend(stage);status.append(notice);
    let n=0;
    const interval=setInterval(()=>{
      if(!status.isConnected||getComputedStyle(status).display==='none'){clearInterval(interval);return;}
      tip.textContent=tips[++n%tips.length];
    },4500);
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});
  else boot();
})();
