import 'round.dart';

class TarotGame {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<String> playerNames;
  final List<RoundData> rounds;

  TarotGame({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.playerNames,
    required this.rounds,
  });

  int get playerCount => playerNames.length;

  List<double> get totals {
    final totals = List<double>.filled(playerNames.length, 0);
    for (final round in rounds) {
      final result = ScoreCalculator.compute(round, playerNames.length);
      for (int i = 0; i < totals.length; i++) {
        totals[i] += result.deltas[i];
      }
    }
    return totals;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'playerNames': playerNames,
        'rounds': rounds.map((r) => r.toMap()).toList(),
      };

  factory TarotGame.fromMap(Map<String, dynamic> map) => TarotGame(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        playerNames: List<String>.from(map['playerNames'] as List),
        rounds: (map['rounds'] as List)
            .map((r) => RoundData.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}
