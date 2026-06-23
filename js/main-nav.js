(function () {
  var path = window.location.pathname;
  var inFeaturesDir = path.indexOf('/features/') !== -1;
  var inModes = path.indexOf('/modes/') !== -1;
  var isSubpage = inFeaturesDir || inModes;
  var base = isSubpage ? '../' : '';

  var placeholder = document.getElementById('main-nav-links');
  if (!placeholder) return;

  placeholder.outerHTML = `
    <div class="nav-links">
      <a href="${base}index.html" data-i18n="nav.home">Home</a>
      <a href="${base}features.html" data-i18n="nav.features">Features</a>
      <a href="${base}modes/games-and-tournaments.html" data-i18n="nav.games">Games</a>
      <a href="${base}downloads.html" data-i18n="nav.downloads">Downloads</a>
      <a href="${base}legal.html" data-i18n="nav.legal">Legal</a>
      <a href="${base}contact.html" data-i18n="nav.contact">Contact</a>
    </div>
  `;

  // Highlight active link by filename
  var currentFile = path.split('/').pop();
  var matched = false;
  document.querySelectorAll('.nav-links a').forEach(function (a) {
    if (a.getAttribute('href').split('/').pop() === currentFile) {
      a.classList.add('active');
      matched = true;
    }
  });
  // Sub-pages: highlight the correct top-level nav item
  if (!matched && isSubpage) {
    var highlightHref = inModes ? 'games-and-tournaments.html' : 'features.html';
    document.querySelectorAll('.nav-links a').forEach(function (a) {
      if (a.getAttribute('href').indexOf(highlightHref) !== -1) {
        a.classList.add('active');
      }
    });
  }
})();
