class WarMemberPresence {
  final bool isInWar;
  final int attacksDone;
  final int attacksAvailable;

  WarMemberPresence(
      {required this.isInWar,
      this.attacksDone = 0,
      this.attacksAvailable = 0});

  factory WarMemberPresence.empty() {
    return WarMemberPresence(
      isInWar: false,
      attacksDone: 0,
      attacksAvailable: 0,
    );
  }
}
