(function(){
  const pages=['login','portal','staff','admin','change-password'];
  const current=location.pathname.replace(/\/+$/,'').split('/').pop().replace(/\.html$/,'');
  if(pages.includes(current) && location.pathname.endsWith('.html')){
    const clean=location.pathname.replace(/\.html$/,'');
    history.replaceState({},'',clean+location.search+location.hash);
  }
})();
