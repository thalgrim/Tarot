import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PillAccent { primary, gold, cream }

class PillOption<T> {
  final T value;
  final String label;

  const PillOption(this.value, this.label);
}

class PillGroup<T> extends StatelessWidget {
  final List<PillOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final PillAccent accent;

  const PillGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accent = PillAccent.primary,
  });

  Color _background(bool isSelected) {
    if (!isSelected) return AppColors.surface;
    switch (accent) {
      case PillAccent.primary:
        return AppColors.primary;
      case PillAccent.gold:
        return AppColors.gold;
      case PillAccent.cream:
        return AppColors.cream;
    }
  }

  Color _foreground(bool isSelected) {
    if (!isSelected) return AppColors.textMuted;
    switch (accent) {
      case PillAccent.primary:
        return Colors.white;
      case PillAccent.gold:
      case PillAccent.cream:
        return AppColors.background;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _Pill(
            label: option.label,
            background: _background(option.value == selected),
            foreground: _foreground(option.value == selected),
            onTap: () => onChanged(option.value),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
