import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/game_repository.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/pill_group.dart';
import '../widgets/primary_action_bar.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';

class NewGameScreen extends StatefulWidget {
  final GameRepository repository;

  const NewGameScreen({super.key, required this.repository});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  final List<TextEditingController> _nameControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nameFocusNodes = List.generate(5, (_) => FocusNode());
  int _playerCount = 4;
  List<String> _knownNames = [];

  @override
  void initState() {
    super.initState();
    _loadKnownNames();
  }

  Future<void> _loadKnownNames() async {
    final games = await widget.repository.listGames();
    final seen = <String>{};
    final names = <String>[];
    for (final game in games) {
      for (final name in game.playerNames) {
        final trimmed = name.trim();
        if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
          names.add(trimmed);
        }
      }
    }
    if (!mounted) return;
    setState(() => _knownNames = names);
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final f in _nameFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final names = List.generate(
      _playerCount,
      (i) => _nameControllers[i].text.trim(),
    );
    final gameName = _gameNameController.text.trim().isEmpty
        ? 'Partie du ${formatDateTime(now)}'
        : _gameNameController.text.trim();

    final game = TarotGame(
      id: now.microsecondsSinceEpoch.toString(),
      name: gameName,
      createdAt: now,
      updatedAt: now,
      playerNames: names,
      rounds: [],
    );

    Navigator.pop(context, game);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Nouvelle partie',
              actionLabel: 'Annuler',
              onAction: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    const SectionLabel('Nombre de joueurs'),
                    PillGroup<int>(
                      options: const [
                        PillOption(3, '3 joueurs'),
                        PillOption(4, '4 joueurs'),
                        PillOption(5, '5 joueurs'),
                      ],
                      selected: _playerCount,
                      onChanged: (value) =>
                          setState(() => _playerCount = value),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('Nom de la partie'),
                    TextFormField(
                      controller: _gameNameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Laisser vide pour un nom automatique',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('Joueurs'),
                    for (int i = 0; i < _playerCount; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlayerNameField(
                          controller: _nameControllers[i],
                          focusNode: _nameFocusNodes[i],
                          hint: 'Joueur ${i + 1}',
                          suggestions: _knownNames,
                          otherChosenNames: [
                            for (int j = 0; j < _playerCount; j++)
                              if (j != i)
                                _nameControllers[j].text.trim().toLowerCase(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            PrimaryActionBar(label: 'Creer la partie', onPressed: _create),
          ],
        ),
      ),
    );
  }
}

class _PlayerNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final List<String> suggestions;
  final List<String> otherChosenNames;

  const _PlayerNameField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.suggestions,
    required this.otherChosenNames,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return suggestions.where(
          (name) =>
              name.toLowerCase().contains(query) &&
              !otherChosenNames.contains(name.toLowerCase()),
        );
      },
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: fieldController,
              focusNode: focusNode,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: hint),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom requis';
                }
                return null;
              },
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final width = MediaQuery.of(context).size.width - 40;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            child: Container(
              width: width,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
