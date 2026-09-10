(function () {
  var path = window.location.pathname;
  // pages/modes/* sit one level below the site root and need a '../' prefix.
  // The baked guide pages also live under a /modes/ path but pin their own
  // prefix with data-nav-base, so they never reach this sniff.
  var isSubpage = path.indexOf('/modes/') !== -1;
  // Pages living outside the published tree (local drafts) can pin the link
  // prefix with data-nav-base on <html>; everything else sniffs the path.
  var navBase = document.documentElement.getAttribute('data-nav-base');
  var base = navBase || (isSubpage ? '../' : '');

  var placeholder = document.getElementById('main-nav-links');
  if (!placeholder) return;

  placeholder.outerHTML = `
    <div class="nav-links">
      <a href="${base}index.html" data-i18n="nav.home">Home</a>
      <a href="${base}platform.html" data-i18n="nav.platform">Platform</a>
      <a href="${base}guide.html" data-i18n="nav.guide">User Guide</a>
      <a href="${base}downloads.html" data-i18n="nav.downloads">Downloads</a>
      <a href="${base}legal.html" data-i18n="nav.legal">Legal</a>
      <a href="${base}contact.html" data-i18n="nav.contact">Contact</a>
    </div>
  `;

  // Highlight active link by filename. Pages that do not want the filename
  // sniffed — the baked guide pages live under /guide/modes/ and would be read
  // as mode pages — name their nav entry with data-nav-active on <html>.
  // pages/modes/* have no top-row entry of their own since the Features
  // section was archived; the left rail carries where-you-are for them.
  var currentFile = document.documentElement.getAttribute('data-nav-active')
                 || path.split('/').pop();
  document.querySelectorAll('.nav-links a').forEach(function (a) {
    if (a.getAttribute('href').split('/').pop() === currentFile) {
      a.classList.add('active');
    }
  });
})();
