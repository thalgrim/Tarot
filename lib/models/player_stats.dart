import 'enums.dart';
import 'game.dart';
import 'round.dart';

class PlayerStats {
  final String name;
  final int gamesPlayed;
  final int wins;
  final double totalScore;
  final double bestGameScore;
  final double worstGameScore;
  final int contratsPris;
  final int contratsReussis;
  final int chelemsReussis;
  final int chelemsRates;

  const PlayerStats({
    required this.name,
    required this.gamesPlayed,
    required this.wins,
    required this.totalScore,
    required this.bestGameScore,
    required this.worstGameScore,
    required this.contratsPris,
    required this.contratsReussis,
    required this.chelemsReussis,
    required this.chelemsRates,
  });

  double get averageScore => gamesPlayed == 0 ? 0 : totalScore / gamesPlayed;
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  static List<PlayerStats> computeAll(List<TarotGame> games) {
    final byName = <String, _Accumulator>{};

    for (final game in games) {
      if (game.rounds.isEmpty || game.playerNames.isEmpty) continue;

      final totals = game.totals;
      final maxTotal = totals.reduce((a, b) => a > b ? a : b);

      for (int i = 0; i < game.playerNames.length; i++) {
        final name = game.playerNames[i].trim();
        if (name.isEmpty) continue;
        final acc = byName.putIfAbsent(name, _Accumulator.new);
        final score = totals[i];
        if (acc.gamesPlayed == 0 || score > acc.bestGameScore) acc.bestGameScore = score;
        if (acc.gamesPlayed == 0 || score < acc.worstGameScore) acc.worstGameScore = score;
        acc.gamesPlayed += 1;
        acc.totalScore += score;
        if (score == maxTotal) acc.wins += 1;
      }

      for (final round in game.rounds) {
        final takerName = game.playerNames[round.takerIndex].trim();
        final acc = byName[takerName];
        if (acc == null) continue;

        final result = ScoreCalculator.compute(round, game.playerNames.length);
        acc.contratsPris += 1;
        if (result.contratRempli) acc.contratsReussis += 1;

        if (round.chelem == Chelem.annonceReussi || round.chelem == Chelem.nonAnnonceReussi) {
          acc.chelemsReussis += 1;
        } else if (round.chelem == Chelem.annonceEchoue) {
          acc.chelemsRates += 1;
        }
      }
    }

    final list = byName.entries.map((e) => e.value.toStats(e.key)).toList();
    list.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    return list;
  }
}

class _Accumulator {
  int gamesPlayed = 0;
  int wins = 0;
  double totalScore = 0;
  double bestGameScore = 0;
  double worstGameScore = 0;
  int contratsPris = 0;
  int contratsReussis = 0;
  int chelemsReussis = 0;
  int chelemsRates = 0;

  PlayerStats toStats(String name) => PlayerStats(
        name: name,
        gamesPlayed: gamesPlayed,
        wins: wins,
        totalScore: totalScore,
        bestGameScore: bestGameScore,
        worstGameScore: worstGameScore,
        contratsPris: contratsPris,
        contratsReussis: contratsReussis,
        chelemsReussis: chelemsReussis,
        chelemsRates: chelemsRates,
      );
}
