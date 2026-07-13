import '../l10n/app_localizations.dart';
import '../models/scramble_tournament.dart';

/// Resolves a seat id to its display name, substituting the localized
/// "Placeholder" label for an ejected player's anonymous stand-in seat
/// (see [ScrambleGame.placeholderId]).
String scramblePlayerLabel(
  ScrambleTournament tournament,
  String playerId,
  AppLocalizations l10n,
) {
  if (ScrambleGame.isPlaceholder(playerId)) return l10n.overviewPlaceholderName;
  return tournament.getPlayer(playerId)?.name ?? playerId;
}
