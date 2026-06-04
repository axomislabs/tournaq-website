/// Central registry of external URLs and contact addresses used in TournaQ.
///
/// Single source of truth for all outbound links. Keeping them here means:
///   - URLs can be audited and updated in one place.
///   - Future CMS-driven or remote-config link management is easy to add.
///   - Legal and support links are visible to non-developer team members.
abstract final class AppLinks {
  // ── Support & Feedback ────────────────────────────────────────────────────

  static const String feedbackForm =
      'https://docs.google.com/forms/d/e/1FAIpQLSc9XrG02hfj0Gt4bgWZJtmuGdJehVBpVMW7j_oWBfLtEgWZmQ/viewform?usp=publish-editor';

  static const String contactEmail = 'team@tournaq.com';

  // ── Social ────────────────────────────────────────────────────────────────

  static const String instagram =
      'https://www.instagram.com/tournaq?igsh=MWd5cThxOGh6dmdnMQ%3D%3D&utm_source=qr';

  // ── Website (GitHub Pages via custom domain) ──────────────────────────────

  static const String website = 'https://www.tournaq.com';
  static const String userGuide = '$website/pages/user-guide.html';
  static const String legalHub = website;

  // ── Individual legal docs (published under the current site root) ─────────

  static const String _legalBase = 'https://www.tournaq.com/legal';

  static const String privacyPolicy = '$_legalBase/privacy-policy.html';
  static const String termsOfUse = '$_legalBase/terms-of-use.html';
  static const String legalNotice = '$_legalBase/legal-notice.html';
}
