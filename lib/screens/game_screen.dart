import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game.dart';
import '../models/round.dart';
import '../services/game_repository.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/dashed_box.dart';
import '../widgets/primary_action_bar.dart';
import '../widgets/score_chart.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';
import 'add_round_screen.dart';

class GameScreen extends StatefulWidget {
  final TarotGame game;
  final GameRepository repository;

  const GameScreen({super.key, required this.game, required this.repository});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late TarotGame _game;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
  }

  Future<void> _addRound() async {
    final round = await Navigator.push<RoundData>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoundScreen(playerNames: _game.playerNames),
      ),
    );
    if (round == null) return;

    setState(() {
      _game.rounds.add(round);
      _game.updatedAt = DateTime.now();
    });
    await widget.repository.saveGame(_game);

    if (!mounted) return;
    final result = ScoreCalculator.compute(round, _game.playerNames.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.contratRempli ? "Contrat rempli" : "Contrat chute"} - '
          'Score de la donne : ${formatScore(result.total)}',
        ),
      ),
    );
  }

  Future<void> _editRound(int roundIndex) async {
    final updated = await Navigator.push<RoundData>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoundScreen(
          playerNames: _game.playerNames,
          initialRound: _game.rounds[roundIndex],
        ),
      ),
    );
    if (updated == null) return;

    setState(() {
      _game.rounds[roundIndex] = updated;
      _game.updatedAt = DateTime.now();
    });
    await widget.repository.saveGame(_game);
  }

  void _copyRecap() {
    final buffer = StringBuffer()..writeln(_game.name);
    final totals = _game.totals;
    for (int i = 0; i < _game.playerNames.length; i++) {
      buffer.writeln('${_game.playerNames[i]} : ${formatScore(totals[i])}');
    }
    if (_game.rounds.isNotEmpty) {
      buffer.writeln();
      for (int i = 0; i < _game.rounds.length; i++) {
        final round = _game.rounds[i];
        final result = ScoreCalculator.compute(round, _game.playerNames.length);
        final taker = _game.playerNames[round.takerIndex];
        buffer.writeln(
          'Donne ${i + 1} - $taker - ${round.contract.label} - ${formatScore(result.total)}',
        );
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Recapitulatif copie.')));
  }

  Future<void> _deleteGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la partie'),
        content: Text('Supprimer definitivement "${_game.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.repository.deleteGame(_game.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  List<MapEntry<int, double>> _sortedTotals() {
    final totals = _game.totals;
    final entries = List.generate(totals.length, (i) => MapEntry(i, totals[i]));
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedTotals();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: _game.name,
              subtitle:
                  '${_game.rounds.length} donne(s) - ${_game.playerCount} joueurs',
              actionLabel: 'Parties',
              onAction: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  for (final entry in sorted) ...[
                    Expanded(
                      child: _ScoreCard(
                        name: _game.playerNames[entry.key],
                        score: entry.value,
                      ),
                    ),
                    if (entry != sorted.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  if (_game.rounds.isNotEmpty) ...[
                    const SectionLabel('Evolution des scores'),
                    ScoreChart(game: _game),
                    const SizedBox(height: 20),
                  ],
                  SectionLabel(
                    'Donnes',
                    trailing: InkWell(
                      onTap: _copyRecap,
                      child: const Text(
                        'Copier le recap',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_game.rounds.isEmpty)
                    DashedBox(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Aucune donne saisie.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'La premiere marque t\'attend.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (int index = 0; index < _game.rounds.length; index++)
                      Builder(
                        builder: (context) {
                          final roundIndex = _game.rounds.length - 1 - index;
                          final round = _game.rounds[roundIndex];
                          final roundNumber = roundIndex + 1;
                          final result = ScoreCalculator.compute(
                            round,
                            _game.playerNames.length,
                          );
                          return _RoundCard(
                            roundNumber: roundNumber,
                            game: _game,
                            round: round,
                            result: result,
                            onTap: () => _editRound(roundIndex),
                          );
                        },
                      ),
                  const SizedBox(height: 16),
                  Center(
                    child: InkWell(
                      onTap: _deleteGame,
                      child: const Text(
                        'Supprimer cette partie',
                        style: TextStyle(
                          color: AppColors.negative,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PrimaryActionBar(
              label: 'Nouvelle donne',
              icon: Icons.add,
              onPressed: _addRound,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String name;
  final double score;

  const _ScoreCard({required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0
        ? AppColors.positive
        : (score < 0 ? AppColors.negative : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            formatScore(score),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final int roundNumber;
  final TarotGame game;
  final RoundData round;
  final RoundResult result;
  final VoidCallback onTap;

  const _RoundCard({
    required this.roundNumber,
    required this.game,
    required this.round,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taker = game.playerNames[round.takerIndex];
    final partner = round.partnerIndex != null
        ? game.playerNames[round.partnerIndex!]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Donne $roundNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (result.contratRempli
                                    ? AppColors.positive
                                    : AppColors.negative)
                                .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        result.contratRempli ? 'Rempli' : 'Chute',
                        style: TextStyle(
                          color: result.contratRempli
                              ? AppColors.positive
                              : AppColors.negative,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$taker${round.takerSolo
                      ? " (seul)"
                      : partner != null
                      ? " + $partner"
                      : ""} '
                  '- ${round.contract.label}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${round.oudlers} bout(s) - ${formatPoints(round.pointsRealises)} pts realises - '
                  'total ${formatScore(result.total)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (int i = 0; i < game.playerNames.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          '${game.playerNames[i]} ${formatScore(result.deltas[i])}',
                          style: TextStyle(
                            color: result.deltas[i] > 0
                                ? AppColors.positive
                                : (result.deltas[i] < 0
                                      ? AppColors.negative
                                      : AppColors.textMuted),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
