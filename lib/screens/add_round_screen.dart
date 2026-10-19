import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/round.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/pill_group.dart';
import '../widgets/primary_action_bar.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';

class AddRoundScreen extends StatefulWidget {
  final List<String> playerNames;
  final RoundData? initialRound;

  const AddRoundScreen({
    super.key,
    required this.playerNames,
    this.initialRound,
  });

  bool get isEditing => initialRound != null;

  @override
  State<AddRoundScreen> createState() => _AddRoundScreenState();
}

class _AddRoundScreenState extends State<AddRoundScreen> {
  late int _takerIndex;
  late bool _solo;
  late int? _partnerIndex;
  late Contract _contract;
  late int _oudlers;
  late double _points;
  late PetitAuBout _petitAuBout;
  late Poignee _poignee;
  late Camp? _poigneeCamp;
  late Chelem _chelem;

  bool get _isFivePlayers => widget.playerNames.length == 5;
  bool get _isFourPlayers => widget.playerNames.length == 4;
  double get _pointsStep => _isFourPlayers ? 1 : 0.5;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRound;
    if (initial != null) {
      _takerIndex = initial.takerIndex;
      _solo = initial.takerSolo;
      _partnerIndex = initial.partnerIndex ?? _firstAvailablePartner();
      _contract = initial.contract;
      _oudlers = initial.oudlers;
      _points = initial.pointsRealises;
      _petitAuBout = initial.petitAuBout;
      _poignee = initial.poignee;
      _poigneeCamp = initial.poigneeCamp;
      _chelem = initial.chelem;
    } else {
      _takerIndex = 0;
      _solo = false;
      _contract = Contract.garde;
      _oudlers = 0;
      _points = _isFourPlayers ? 46 : 45.5;
      _petitAuBout = PetitAuBout.personne;
      _poignee = Poignee.aucune;
      _poigneeCamp = null;
      _chelem = Chelem.aucun;
      _partnerIndex = _firstAvailablePartner();
    }
  }

  int? _firstAvailablePartner() {
    for (int i = 0; i < widget.playerNames.length; i++) {
      if (i != _takerIndex) return i;
    }
    return null;
  }

  void _onTakerChanged(int value) {
    setState(() {
      _takerIndex = value;
      if (_partnerIndex == _takerIndex) {
        _partnerIndex = _firstAvailablePartner();
      }
    });
  }

  Poignee get _attackPoignee =>
      _poigneeCamp == Camp.attaque ? _poignee : Poignee.aucune;
  Poignee get _defensePoignee =>
      _poigneeCamp == Camp.defense ? _poignee : Poignee.aucune;

  void _onAttackPoigneeChanged(Poignee value) {
    setState(() {
      if (value == Poignee.aucune) {
        if (_poigneeCamp == Camp.attaque) {
          _poignee = Poignee.aucune;
          _poigneeCamp = null;
        }
      } else {
        _poignee = value;
        _poigneeCamp = Camp.attaque;
      }
    });
  }

  void _onDefensePoigneeChanged(Poignee value) {
    setState(() {
      if (value == Poignee.aucune) {
        if (_poigneeCamp == Camp.defense) {
          _poignee = Poignee.aucune;
          _poigneeCamp = null;
        }
      } else {
        _poignee = value;
        _poigneeCamp = Camp.defense;
      }
    });
  }

  void _movePoints(double delta) {
    setState(() {
      _points = (_points + delta).clamp(0, 91);
    });
  }

  RoundData _buildRound() {
    return RoundData(
      takerIndex: _takerIndex,
      partnerIndex: (_isFivePlayers && !_solo) ? _partnerIndex : null,
      takerSolo: _isFivePlayers && _solo,
      contract: _contract,
      oudlers: _oudlers,
      pointsRealises: _points,
      petitAuBout: _petitAuBout,
      poignee: _poignee,
      poigneeCamp: _poigneeCamp,
      chelem: _chelem,
    );
  }

  void _validate() {
    if (_isFivePlayers && !_solo && _partnerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionnez un partenaire')),
      );
      return;
    }
    Navigator.pop(context, _buildRound());
  }

  @override
  Widget build(BuildContext context) {
    final pointsRequis = ScoreCalculator.pointsRequis(_oudlers);
    final round = _buildRound();
    final result = ScoreCalculator.compute(round, widget.playerNames.length);

    final diff = _points - pointsRequis;
    final contratRempli = _points >= pointsRequis;
    final baseScore = (diff.abs() + 25) * _contract.multiplier;
    final contractTotal = contratRempli ? baseScore : -baseScore;

    final takerDelta = result.deltas[_takerIndex];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: widget.isEditing ? 'Modifier la donne' : 'Nouvelle donne',
              actionLabel: 'Annuler',
              onAction: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  const SectionLabel('Preneur'),
                  PillGroup<int>(
                    options: [
                      for (int i = 0; i < widget.playerNames.length; i++)
                        PillOption(i, widget.playerNames[i]),
                    ],
                    selected: _takerIndex,
                    onChanged: _onTakerChanged,
                  ),
                  if (_isFivePlayers) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                      title: const Text(
                        'Le preneur joue seul (roi appele en main)',
                      ),
                      value: _solo,
                      onChanged: (value) => setState(() => _solo = value),
                    ),
                    if (!_solo) ...[
                      const SizedBox(height: 8),
                      const SectionLabel('Partenaire (appele)'),
                      PillGroup<int>(
                        accent: PillAccent.cream,
                        options: [
                          for (int i = 0; i < widget.playerNames.length; i++)
                            if (i != _takerIndex)
                              PillOption(i, widget.playerNames[i]),
                        ],
                        selected: _partnerIndex ?? -1,
                        onChanged: (value) =>
                            setState(() => _partnerIndex = value),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  const SectionLabel('Contrat'),
                  PillGroup<Contract>(
                    options: [
                      for (final c in Contract.values)
                        PillOption(c, '${c.label} x${c.multiplier}'),
                    ],
                    selected: _contract,
                    onChanged: (value) => setState(() => _contract = value),
                  ),
                  const SizedBox(height: 24),
                  SectionLabel(
                    'Bouts de l\'attaque',
                    trailing: Text(
                      'il faut $pointsRequis points',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  PillGroup<int>(
                    accent: PillAccent.gold,
                    options: const [
                      PillOption(0, '0'),
                      PillOption(1, '1'),
                      PillOption(2, '2'),
                      PillOption(3, '3'),
                    ],
                    selected: _oudlers,
                    onChanged: (value) => setState(() => _oudlers = value),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Points de l\'attaque'),
                  Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        onTap: () => _movePoints(-_pointsStep),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              formatMaybeInt(_points),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'defense : ${formatMaybeInt(91 - _points)} pts',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        onTap: () => _movePoints(_pointsStep),
                      ),
                    ],
                  ),
                  Slider(
                    value: _points,
                    min: 0,
                    max: 91,
                    divisions: _isFourPlayers ? 91 : 182,
                    onChanged: (value) => setState(() => _points = value),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Petit au bout'),
                  PillGroup<PetitAuBout>(
                    accent: PillAccent.gold,
                    options: [
                      for (final p in PetitAuBout.values)
                        PillOption(p, p.label),
                    ],
                    selected: _petitAuBout,
                    onChanged: (value) => setState(() => _petitAuBout = value),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Poignee de l\'attaque'),
                  PillGroup<Poignee>(
                    accent: PillAccent.cream,
                    options: [
                      for (final p in Poignee.values)
                        PillOption(
                          p,
                          p.bonus > 0 ? '${p.label} (+${p.bonus})' : p.label,
                        ),
                    ],
                    selected: _attackPoignee,
                    onChanged: _onAttackPoigneeChanged,
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Poignee de la defense'),
                  PillGroup<Poignee>(
                    accent: PillAccent.cream,
                    options: [
                      for (final p in Poignee.values)
                        PillOption(
                          p,
                          p.bonus > 0 ? '${p.label} (+${p.bonus})' : p.label,
                        ),
                    ],
                    selected: _defensePoignee,
                    onChanged: _onDefensePoigneeChanged,
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Chelem'),
                  PillGroup<Chelem>(
                    accent: PillAccent.cream,
                    options: [
                      for (final c in Chelem.values) PillOption(c, c.label),
                    ],
                    selected: _chelem,
                    onChanged: (value) => setState(() => _chelem = value),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Apercu de la marque'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.playerNames[_takerIndex]} '
                                '${takerDelta >= 0 ? "gagne" : "perd"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              formatScore(takerDelta),
                              style: TextStyle(
                                color: takerDelta >= 0
                                    ? AppColors.positive
                                    : AppColors.negative,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _PreviewLine(
                          label:
                              'Contrat ${contratRempli ? "reussi" : "chute"} de '
                              '${formatScore(diff)} -> (25 + ${formatMaybeInt(diff.abs())}) '
                              'x ${_contract.multiplier}',
                          value: formatScore(contractTotal),
                        ),
                        if (_petitAuBout != PetitAuBout.personne)
                          _PreviewLine(
                            label:
                                'Petit au bout (${_petitAuBout.camp!.label.toLowerCase()})',
                            value: formatScore(_petitAuBout.bonus),
                          ),
                        if (_poignee != Poignee.aucune)
                          _PreviewLine(
                            label:
                                'Poignee ${_poignee.label.toLowerCase()} '
                                '(${_poigneeCamp!.label.toLowerCase()})',
                            value: formatScore(
                              _poigneeCamp == Camp.attaque
                                  ? _poignee.bonus.toDouble()
                                  : -_poignee.bonus.toDouble(),
                            ),
                          ),
                        if (_chelem != Chelem.aucun)
                          _PreviewLine(
                            label: _chelem.label,
                            value: formatScore(_chelem.bonus.toDouble()),
                          ),
                        const Divider(height: 20),
                        _PreviewLine(
                          label: 'Total',
                          value: formatScore(result.total),
                          bold: true,
                        ),
                        const Divider(height: 20),
                        for (int i = 0; i < widget.playerNames.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.playerNames[i],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  formatScore(result.deltas[i]),
                                  style: TextStyle(
                                    color: result.deltas[i] > 0
                                        ? AppColors.positive
                                        : (result.deltas[i] < 0
                                              ? AppColors.negative
                                              : AppColors.textMuted),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PrimaryActionBar(
              label: widget.isEditing
                  ? 'Enregistrer les modifications'
                  : 'Enregistrer la donne',
              onPressed: _validate,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PreviewLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: bold ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}
