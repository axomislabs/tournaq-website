(function () {
  var path = window.location.pathname;
  var inFeaturesDir = path.indexOf('/features/') !== -1;
  var inModes = path.indexOf('/modes/') !== -1;

  var f, m, overview;
  if (inFeaturesDir) {
    f = '';
    m = '../modes/';
    overview = '../features.html';
  } else if (inModes) {
    f = '../features/';
    m = '';
    overview = '../features.html';
  } else {
    f = 'features/';
    m = 'modes/';
    overview = 'features.html';
  }

  var style = document.createElement('style');
  style.textContent = `
    .features-subnav {
      background: white;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 18px 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.05);
      margin-bottom: 40px;
    }
    .subnav-overview {
      display: flex;
      justify-content: center;
      margin-bottom: 14px;
    }
    .subnav-overview a {
      background: var(--olive);
      color: white;
      text-decoration: none;
      font-size: 13px;
      font-weight: 700;
      padding: 7px 20px;
      border-radius: 999px;
      transition: background 0.15s;
    }
    .subnav-overview a:hover,
    .subnav-overview a.active { background: var(--olive-dark); }
    .subnav-groups {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    @media (max-width: 600px) {
      .subnav-groups { grid-template-columns: 1fr; }
    }
    .subnav-group {
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 12px 14px;
    }
    .subnav-group-label {
      font-size: 10px;
      font-weight: 700;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.6px;
      margin-bottom: 8px;
    }
    .subnav-group-links {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    .subnav-group-links a {
      background: var(--olive-light);
      color: var(--olive);
      text-decoration: none;
      font-size: 12px;
      font-weight: 700;
      padding: 5px 11px;
      border-radius: 999px;
      transition: background 0.15s, color 0.15s;
    }
    .subnav-group-links a:hover,
    .subnav-group-links a.active {
      background: var(--olive);
      color: white;
    }
  `;
  document.head.appendChild(style);

  var placeholder = document.getElementById('feature-subnav');
  if (!placeholder) return;

  placeholder.outerHTML = `
    <nav class="features-subnav" aria-label="Feature areas">
      <div class="subnav-overview">
        <a href="${overview}">Overview – All Features</a>
      </div>
      <div class="subnav-groups">
        <div class="subnav-group">
          <div class="subnav-group-label">Game &amp; Tournament Modes</div>
          <div class="subnav-group-links">
            <a href="${m}quick-game.html">Quick Game</a>
            <a href="${m}social-scramble.html">Social Scramble</a>
            <a href="${m}doghouse.html">Doghouse</a>
            <a href="${m}king-of-the-court.html">King of the Court</a>
            <a href="${m}ko-system.html">KO System</a>
            <a href="${m}league.html">League</a>
            <a href="${m}double-elimination.html">Double Elimination</a>
            <a href="${m}group-single-elimination.html">Group &amp; Single Elim.</a>
            <a href="${m}group-double-elimination.html">Group &amp; Double Elim.</a>
            <a href="${m}swiss-system.html">Swiss System</a>
            <a href="${m}other-tournament-modes.html">Other Modes</a>
          </div>
        </div>
        <div class="subnav-group">
          <div class="subnav-group-label">Platform Features</div>
          <div class="subnav-group-links">
            <a href="${f}scoring.html">Match Scoring</a>
            <a href="${f}tournament-features.html">Tournament Management</a>
            <a href="${f}device-scalability.html">Device &amp; Screen</a>
            <a href="${f}live-tournament.html">Live Tournaments</a>
            <a href="${f}user-administration.html">User Administration</a>
          </div>
        </div>
      </div>
    </nav>
  `;

  var currentFile = path.split('/').pop();
  document.querySelectorAll('.features-subnav a').forEach(function (a) {
    if (a.getAttribute('href').split('/').pop() === currentFile) {
      a.classList.add('active');
    }
  });
})();
