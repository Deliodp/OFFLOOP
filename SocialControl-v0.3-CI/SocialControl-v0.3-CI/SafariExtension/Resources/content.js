let cfg={reels:true,shorts:true,ads:false};

async function load(){
  try{cfg={...cfg,...await browser.runtime.sendMessage({type:"settings"})}}catch(_){}
  apply();
}

const hide=e=>{if(e)e.style.setProperty("display","none","important")};

function apply(){
  const host=location.hostname,path=location.pathname;

  if(host.includes("instagram.com")&&cfg.reels){
    if(path.startsWith("/reel/")||path.startsWith("/reels")){
      location.replace("https://www.instagram.com/"); return;
    }
    document.querySelectorAll('a[href^="/reel/"],a[href^="/reels/"]').forEach(a=>{
      hide(a.closest("article")||a.closest("div")||a);
    });
  }

  if(host.includes("youtube.com")&&cfg.shorts){
    if(path.startsWith("/shorts")){
      location.replace("https://www.youtube.com/"); return;
    }
    document.querySelectorAll('a[href^="/shorts/"],a[title="Shorts"]').forEach(a=>{
      hide(a.closest("ytd-reel-shelf-renderer")||a.closest("ytd-rich-item-renderer")||a.closest("ytd-video-renderer")||a);
    });
    document.querySelectorAll("ytd-reel-shelf-renderer").forEach(hide);
  }

  if(host.includes("youtube.com")&&cfg.ads){
    [
      ".ytp-ad-module",".ytp-ad-overlay-container","ytd-ad-slot-renderer",
      "ytd-display-ad-renderer","ytd-promoted-video-renderer",
      "ytd-in-feed-ad-layout-renderer","ytd-banner-promo-renderer"
    ].forEach(sel=>document.querySelectorAll(sel).forEach(hide));

    document.querySelectorAll(
      ".ytp-ad-skip-button,.ytp-ad-skip-button-modern,button.ytp-skip-ad-button"
    ).forEach(btn=>{if(btn instanceof HTMLElement&&!btn.disabled)btn.click()});
  }
}

let scheduled=false;
new MutationObserver(()=>{
  if(scheduled)return;scheduled=true;
  requestAnimationFrame(()=>{scheduled=false;apply()})
}).observe(document.documentElement,{childList:true,subtree:true});

load();
