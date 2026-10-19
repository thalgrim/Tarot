import 'package:flutter/material.dart';

import '../models/player_stats.dart';
import '../services/game_repository.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';

class StatsScreen extends StatefulWidget {
  final GameRepository repository;

  const StatsScreen({super.key, required this.repository});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<PlayerStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<List<PlayerStats>> _loadStats() async {
    final games = await widget.repository.listGames();
    return PlayerStats.computeAll(games);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Statistiques joueurs',
              subtitle: 'Cumul sur toutes les parties sauvegardees',
              actionLabel: 'Parties',
              onAction: () => Navigator.pop(context),
            ),
            Expanded(
              child: FutureBuilder<List<PlayerStats>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  final stats = snapshot.data ?? [];
                  if (stats.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Aucune statistique pour le moment.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Joue au moins une donne pour voir apparaitre des stats.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      const SectionLabel('Classement - score moyen par partie'),
                      for (int i = 0; i < stats.length; i++) ...[
                        _PlayerStatsRow(rank: i + 1, stats: stats[i]),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatsRow extends StatelessWidget {
  final int rank;
  final PlayerStats stats;

  const _PlayerStatsRow({required this.rank, required this.stats});

  @override
  Widget build(BuildContext context) {
    final avgColor = stats.averageScore > 0
        ? AppColors.positive
        : (stats.averageScore < 0 ? AppColors.negative : Colors.white);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rank == 1 ? AppColors.gold.withValues(alpha: 0.2) : AppColors.background,
                  border: Border.all(color: rank == 1 ? AppColors.gold : AppColors.surfaceBorder),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank == 1 ? AppColors.gold : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stats.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${formatScore(stats.averageScore)} / partie',
                style: TextStyle(color: avgColor, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatChip(label: '${stats.gamesPlayed} partie(s)'),
              _StatChip(label: '${stats.wins} victoire(s)'),
              _StatChip(label: '${(stats.winRate * 100).round()}% de victoires'),
              if (stats.contratsPris > 0)
                _StatChip(label: '${stats.contratsReussis}/${stats.contratsPris} contrats reussis'),
              if (stats.chelemsReussis > 0)
                _StatChip(label: '${stats.chelemsReussis} chelem(s) reussi(s)'),
              if (stats.chelemsRates > 0)
                _StatChip(label: '${stats.chelemsRates} chelem(s) rate(s)'),
              _StatChip(label: 'Meilleure partie ${formatScore(stats.bestGameScore)}'),
              _StatChip(label: 'Pire partie ${formatScore(stats.worstGameScore)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
