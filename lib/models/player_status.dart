enum PlayerStatus { active, late, swappedIn, swappedOut, ejected }

extension PlayerStatusX on PlayerStatus {
  bool get isActive =>
      this == PlayerStatus.active ||
      this == PlayerStatus.late ||
      this == PlayerStatus.swappedIn;
}
