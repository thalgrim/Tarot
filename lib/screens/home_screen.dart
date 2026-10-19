import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/game_repository.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/primary_action_bar.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';
import 'game_screen.dart';
import 'new_game_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = GameRepository();
  late Future<List<TarotGame>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = _repository.listGames();
  }

  void _refresh() {
    setState(() {
      _gamesFuture = _repository.listGames();
    });
  }

  Future<void> _createGame() async {
    final game = await Navigator.push<TarotGame>(
      context,
      MaterialPageRoute(builder: (_) => NewGameScreen(repository: _repository)),
    );
    if (game == null) return;

    await _repository.saveGame(game);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(game: game, repository: _repository),
      ),
    );
    _refresh();
  }

  Future<void> _openGame(TarotGame game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(game: game, repository: _repository),
      ),
    );
    _refresh();
  }

  Future<bool> _confirmDelete(TarotGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la partie'),
        content: Text('Supprimer definitivement "${game.name}" ?'),
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
    return confirmed ?? false;
  }

  Future<void> _openStats() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsScreen(repository: _repository)),
    );
  }

  Future<void> _showBareme() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bareme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Points a realiser par l\'attaque selon le nombre de bouts :'),
            SizedBox(height: 12),
            _BaremeRow(bouts: '0 bout', points: '56 points'),
            _BaremeRow(bouts: '1 bout', points: '51 points'),
            _BaremeRow(bouts: '2 bouts', points: '41 points'),
            _BaremeRow(bouts: '3 bouts', points: '36 points'),
            SizedBox(height: 12),
            Text('Multiplicateur du contrat :'),
            SizedBox(height: 8),
            _BaremeRow(bouts: 'Prise', points: 'x1'),
            _BaremeRow(bouts: 'Garde', points: 'x2'),
            _BaremeRow(bouts: 'Garde sans', points: 'x4'),
            _BaremeRow(bouts: 'Garde contre', points: 'x6'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Tarot - Comptage de points',
              subtitle: 'Scores et donnes - 3, 4 ou 5 joueurs',
              actions: [
                HeaderLink('Stats', onTap: _openStats),
                const SizedBox(width: 16),
                HeaderLink('Bareme', onTap: _showBareme),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: FutureBuilder<List<TarotGame>>(
                  future: _gamesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    final games = snapshot.data ?? [];
                    if (games.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Aucune partie sauvegardee.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Appuie sur + pour commencer.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      children: [
                        const SectionLabel('Mes parties'),
                        for (final game in games) ...[
                          _GameRow(
                            game: game,
                            onTap: () => _openGame(game),
                            onDelete: () async {
                              if (await _confirmDelete(game)) {
                                await _repository.deleteGame(game.id);
                                _refresh();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            PrimaryActionBar(
              label: 'Nouvelle partie',
              icon: Icons.add,
              onPressed: _createGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _BaremeRow extends StatelessWidget {
  final String bouts;
  final String points;

  const _BaremeRow({required this.bouts, required this.points});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(bouts),
          Text(points, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  final TarotGame game;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GameRow({
    required this.game,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(game.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.negative.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.negative),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.rounds.length} donne(s) - ${game.playerCount} joueurs - '
                        'maj ${formatDateTime(game.updatedAt)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
