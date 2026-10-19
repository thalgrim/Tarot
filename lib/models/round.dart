import 'enums.dart';

class RoundData {
  final int takerIndex;
  final int? partnerIndex;
  final bool takerSolo;
  final Contract contract;
  final int oudlers;
  final double pointsRealises;
  final PetitAuBout petitAuBout;
  final Poignee poignee;
  final Camp? poigneeCamp;
  final Chelem chelem;

  const RoundData({
    required this.takerIndex,
    this.partnerIndex,
    required this.takerSolo,
    required this.contract,
    required this.oudlers,
    required this.pointsRealises,
    required this.petitAuBout,
    required this.poignee,
    this.poigneeCamp,
    required this.chelem,
  });

  Map<String, dynamic> toMap() => {
        'takerIndex': takerIndex,
        'partnerIndex': partnerIndex,
        'takerSolo': takerSolo,
        'contract': contract.name,
        'oudlers': oudlers,
        'pointsRealises': pointsRealises,
        'petitAuBout': petitAuBout.name,
        'poignee': poignee.name,
        'poigneeCamp': poigneeCamp?.name,
        'chelem': chelem.name,
      };

  factory RoundData.fromMap(Map<String, dynamic> map) => RoundData(
        takerIndex: map['takerIndex'] as int,
        partnerIndex: map['partnerIndex'] as int?,
        takerSolo: map['takerSolo'] as bool,
        contract: Contract.values.byName(map['contract'] as String),
        oudlers: map['oudlers'] as int,
        pointsRealises: (map['pointsRealises'] as num).toDouble(),
        petitAuBout: PetitAuBout.values.byName(map['petitAuBout'] as String),
        poignee: Poignee.values.byName(map['poignee'] as String),
        poigneeCamp: map['poigneeCamp'] != null ? Camp.values.byName(map['poigneeCamp'] as String) : null,
        chelem: Chelem.values.byName(map['chelem'] as String),
      );
}

class RoundResult {
  final double total;
  final List<double> deltas;
  final bool contratRempli;

  const RoundResult({required this.total, required this.deltas, required this.contratRempli});
}

class ScoreCalculator {
  static int pointsRequis(int oudlers) {
    switch (oudlers) {
      case 0:
        return 56;
      case 1:
        return 51;
      case 2:
        return 41;
      case 3:
        return 36;
      default:
        throw ArgumentError('Le nombre de bouts doit etre entre 0 et 3');
    }
  }

  static RoundResult compute(RoundData round, int playerCount) {
    final requis = pointsRequis(round.oudlers);
    final diff = round.pointsRealises - requis;
    final contratRempli = round.pointsRealises >= requis;
    final baseScore = (diff.abs() + 25) * round.contract.multiplier;
    double total = contratRempli ? baseScore : -baseScore;

    total += round.petitAuBout.bonus;

    if (round.poignee != Poignee.aucune) {
      final bonus = round.poignee.bonus;
      total += (round.poigneeCamp == Camp.attaque) ? bonus : -bonus;
    }
    total += round.chelem.bonus;

    final deltas = List<double>.filled(playerCount, 0);
    for (int i = 0; i < playerCount; i++) {
      double delta;
      if (i == round.takerIndex) {
        if (playerCount == 5 && !round.takerSolo) {
          delta = 2 * total;
        } else if (playerCount == 5) {
          delta = 4 * total;
        } else if (playerCount == 4) {
          delta = 3 * total;
        } else {
          delta = 2 * total;
        }
      } else if (i == round.partnerIndex) {
        delta = total;
      } else {
        delta = -total;
      }
      deltas[i] = delta;
    }

    return RoundResult(total: total, deltas: deltas, contratRempli: contratRempli);
  }
}
