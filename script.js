(()=>{
  const DATA=window.PB_ART_CONTENT||{realms:[],works:[]};
  const qs=(s,r=document)=>r.querySelector(s);
  const qsa=(s,r=document)=>[...r.querySelectorAll(s)];
  const state={filter:'all',shown:16};
  const labels={'fine-art':'Fine Art','tattoo':'Tattoo Art','video':'Video Art','3d':'3D Design','jewelry':'Jewelry Design'};
  const esc=(v='')=>String(v).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  const isMotion=w=>w?.mediaType==='video'||w?.mediaType==='youtube';
  const isLocalFile=location.protocol==='file:';
  const youtubePoster=id=>`https://i.ytimg.com/vi/${encodeURIComponent(id)}/hqdefault.jpg`;
  const youtubeEmbedUrl=(w,autoplay=false)=>{
    const params=new URLSearchParams({rel:'0',playsinline:'1'});
    if(autoplay)params.set('autoplay','1');
    if(/^https?:$/.test(location.protocol))params.set('origin',location.origin);
    return `https://www.youtube.com/embed/${encodeURIComponent(w.youtubeId)}?${params.toString()}`;
  };

  const realmGrid=qs('#realm-grid');
  DATA.realms.forEach((realm,i)=>{
    const a=document.createElement('a');
    a.className='realm-card reveal';
    a.href=realm.href;
    a.style.setProperty('--image',`url("${realm.image}")`);
    a.innerHTML=`<span class="realm-index">${String(i+1).padStart(2,'0')} / REALM</span><h3>${esc(realm.title)}</h3><p>${esc(realm.label)}</p>`;
    realmGrid.append(a);
  });

  const grid=qs('#project-grid'),load=qs('#load-more'),count=qs('#fine-art-count');
  const filtered=()=>state.filter==='all'?DATA.works:DATA.works.filter(w=>w.category===state.filter);
  function render(){
    const arr=filtered();
    grid.innerHTML='';
    arr.slice(0,state.shown).forEach((w,i)=>{
      const b=document.createElement('button');
      b.className=`project-card${isMotion(w)?' is-video':''}`;
      b.type='button';
      b.dataset.id=w.id;
      const poster=w.poster||w.image;
      b.innerHTML=`<span class="project-visual"><img src="${poster}" alt="${esc(w.alt)}" loading="lazy" decoding="async"><span class="project-overlay"></span>${isMotion(w)?'<span class="card-play" aria-hidden="true">▶</span>':''}</span><span class="project-number">${String(i+1).padStart(3,'0')}</span><span class="project-meta"><span>${labels[w.category]||esc(w.medium)}</span><h3>${esc(w.title)}</h3></span>`;
      grid.append(b);
    });
    const artworks=arr.filter(w=>!isMotion(w)).length;
    const films=arr.filter(isMotion).length;
    count.textContent=state.filter==='all'?`${artworks} artworks · ${films} films`:`${arr.length} ${arr.length===1?'entry':'entries'} cataloged`;
    load.hidden=state.shown>=arr.length;
  }
  render();

  qsa('.filter').forEach(b=>b.addEventListener('click',()=>{
    qsa('.filter').forEach(x=>x.classList.remove('active'));
    b.classList.add('active');state.filter=b.dataset.filter;state.shown=16;render();
  }));
  load.addEventListener('click',()=>{state.shown+=16;render()});
  qsa('.filter-jump').forEach(b=>b.addEventListener('click',()=>{
    const target=qs(`.filter[data-filter="${b.dataset.jump}"]`);target?.click();qs('#fine-art').scrollIntoView({behavior:'smooth'});
  }));

  const objectGrid=qs('#object-grid');
  DATA.works.filter(w=>w.category==='3d'||w.category==='jewelry').forEach(w=>{
    const b=document.createElement('button');b.className='machine-card';b.dataset.id=w.id;
    b.innerHTML=`<img src="${w.image}" alt="${esc(w.alt)}" loading="lazy"><span>${esc(w.title)}</span>`;objectGrid.append(b);
  });

  const videoGrid=qs('#video-grid');
  DATA.works.filter(isMotion).forEach((w,i)=>{
    const article=document.createElement('article');article.className='video-card reveal';
    const player=w.mediaType==='youtube'
      ? `<button class="youtube-poster-button" type="button" data-youtube-open="${w.id}" aria-label="Open ${esc(w.title)}"><img src="${youtubePoster(w.youtubeId)}" alt="${esc(w.alt||w.title)}" loading="lazy"><span class="youtube-play" aria-hidden="true">▶</span><span class="youtube-poster-label">${isLocalFile?'OPEN VIDEO':'PLAY VIDEO'}</span></button>`
      : `<video controls playsinline preload="metadata" poster="${w.poster||''}"><source src="${w.src}" type="video/mp4">Your browser does not support HTML5 video.</video>`;
    const sourceLabel=w.mediaType==='youtube'?'YOUTUBE VIDEO':'LOCAL VIDEO';
    article.innerHTML=`<div class="video-frame">${player}</div><div class="video-meta"><span class="eyebrow">${String(i+1).padStart(2,'0')} / ${sourceLabel}</span><h3>${esc(w.title)}</h3><p>${esc(w.description||w.medium)}</p><button class="text-link video-expand" data-id="${w.id}" type="button">Open full-screen <span>↗</span></button></div>`;
    videoGrid.append(article);
  });

  const dialog=qs('#project-dialog'),visual=qs('.dialog-visual'),dimg=qs('.dialog-image'),dvideo=qs('.dialog-video'),dyoutube=qs('.dialog-youtube'),dyoutubeFallback=qs('.dialog-youtube-fallback'),dyoutubeFallbackPoster=qs('.youtube-fallback-poster'),dyoutubeFallbackLink=qs('.youtube-fallback-link'),dtype=qs('.dialog-type'),dtitle=qs('.dialog-title'),ddesc=qs('.dialog-description'),dmail=qs('.dialog-email'),doriginal=qs('.dialog-original'),dzoom=qs('.dialog-zoom');
  let current=null;
  function resetZoom(){visual.classList.remove('zoomed');dzoom.textContent='View actual size'}
  function openWork(id){
    const w=DATA.works.find(x=>x.id===id);if(!w)return;current=w;resetZoom();
    const isLocalVideo=w.mediaType==='video';
    const isYouTube=w.mediaType==='youtube';
    const isVideo=isLocalVideo||isYouTube;
    dimg.hidden=isVideo;dvideo.hidden=!isLocalVideo;dyoutube.hidden=true;dyoutubeFallback.hidden=true;dzoom.hidden=isVideo;
    dvideo.pause();dvideo.removeAttribute('src');dvideo.load();dyoutube.removeAttribute('src');
    if(isLocalVideo){dimg.removeAttribute('src');dvideo.poster=w.poster||'';dvideo.src=w.src;doriginal.href=w.src;doriginal.innerHTML='Open video file <span>↗</span>'}
    else if(isYouTube){
      dimg.removeAttribute('src');doriginal.href=w.src;doriginal.innerHTML='Watch on YouTube <span>↗</span>';
      if(isLocalFile){
        dyoutubeFallback.hidden=false;dyoutubeFallbackPoster.src=youtubePoster(w.youtubeId);dyoutubeFallbackPoster.alt=w.alt||w.title;dyoutubeFallbackLink.href=w.src;
      }else{
        dyoutube.hidden=false;dyoutube.src=youtubeEmbedUrl(w,true);
      }
    }
    else{dimg.src=w.image;dimg.alt=w.alt||w.title;doriginal.href=w.image;doriginal.innerHTML='Open original <span>↗</span>'}
    dtype.textContent=labels[w.category]||w.medium;dtitle.textContent=w.title;ddesc.textContent=w.description||w.medium;
    dmail.href=`mailto:lastritestattoo@gmail.com?subject=${encodeURIComponent('Inquiry: '+w.title)}`;
    dialog.showModal();
  }
  function closeDialog(){dvideo.pause();dyoutube.removeAttribute('src');dyoutubeFallback.hidden=true;dialog.close();resetZoom()}
  document.addEventListener('click',e=>{
    const youtubeOpen=e.target.closest('[data-youtube-open]');if(youtubeOpen){openWork(youtubeOpen.dataset.youtubeOpen);return}
    const expand=e.target.closest('.video-expand');if(expand){openWork(expand.dataset.id);return}
    const card=e.target.closest('[data-id]');if(card&&!card.closest('.video-card'))openWork(card.dataset.id);
    const feature=e.target.closest('[data-open-id]');if(feature)openWork(feature.dataset.openId);
  });
  dzoom.addEventListener('click',()=>{const z=visual.classList.toggle('zoomed');dzoom.textContent=z?'Fit full image':'View actual size'});
  qs('.dialog-close').addEventListener('click',closeDialog);
  dialog.addEventListener('click',e=>{if(e.target===dialog)closeDialog()});
  dialog.addEventListener('cancel',e=>{e.preventDefault();closeDialog()});

  const menu=qs('.menu-button'),panel=qs('.mobile-panel');
  menu.addEventListener('click',()=>{const o=panel.classList.toggle('open');menu.setAttribute('aria-expanded',String(o));panel.setAttribute('aria-hidden',String(!o))});
  qsa('.mobile-panel a').forEach(a=>a.addEventListener('click',()=>{panel.classList.remove('open');menu.setAttribute('aria-expanded','false')}));

  const observer=new IntersectionObserver(es=>es.forEach(e=>e.isIntersecting&&e.target.classList.add('visible')),{threshold:.1});
  qsa('.reveal').forEach(x=>observer.observe(x));
  // Observe dynamically created cards as well.
  qsa('.video-card,.realm-card').forEach(x=>observer.observe(x));

  const glow=qs('.cursor-glow'),stage=qs('.hero-logo-stage');
  window.addEventListener('pointermove',e=>{if(glow){glow.style.left=e.clientX+'px';glow.style.top=e.clientY+'px'}if(stage&&innerWidth>760){const x=(e.clientX/innerWidth-.5),y=(e.clientY/innerHeight-.5);stage.style.transform=`rotateY(${x*8}deg) rotateX(${-y*7}deg) translate3d(${x*18}px,${y*13}px,0)`}});
  window.addEventListener('pointerleave',()=>{if(stage)stage.style.transform=''});
  const canvas=qs('.hero-particles'),ctx=canvas.getContext('2d');let pts=[];
  function resize(){canvas.width=innerWidth*devicePixelRatio;canvas.height=innerHeight*devicePixelRatio;ctx.setTransform(devicePixelRatio,0,0,devicePixelRatio,0,0);pts=Array.from({length:Math.min(90,Math.floor(innerWidth/15))},()=>({x:Math.random()*innerWidth,y:Math.random()*innerHeight,r:Math.random()*1.2+.2,s:Math.random()*.22+.05,a:Math.random()*.45+.08}))}
  function draw(){ctx.clearRect(0,0,innerWidth,innerHeight);for(const p of pts){p.y-=p.s;if(p.y<0){p.y=innerHeight;p.x=Math.random()*innerWidth}ctx.fillStyle=`rgba(204,198,187,${Math.min(p.a,.26)})`;ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2);ctx.fill()}requestAnimationFrame(draw)}
  resize();draw();addEventListener('resize',resize);qs('#year').textContent=new Date().getFullYear();
})();
