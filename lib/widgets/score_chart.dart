import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/round.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

/// Couleurs fixes par joueur (ordre de saisie, jamais par classement).
const playerSeriesColors = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
];

/// Evolution des scores cumules de chaque joueur, donne par donne.
/// Toucher ou glisser sur le graphique pour lire les scores d'une donne.
class ScoreChart extends StatefulWidget {
  final TarotGame game;

  const ScoreChart({super.key, required this.game});

  @override
  State<ScoreChart> createState() => _ScoreChartState();
}

class _ScoreChartState extends State<ScoreChart> {
  int? _selected;
  int _pointCount = 0;

  /// series[joueur][donne], avec la donne 0 = depart a 0.
  List<List<double>> _cumulative() {
    final game = widget.game;
    final series = List.generate(game.playerCount, (_) => <double>[0]);
    for (final round in game.rounds) {
      final result = ScoreCalculator.compute(round, game.playerCount);
      for (int i = 0; i < game.playerCount; i++) {
        series[i].add(series[i].last + result.deltas[i]);
      }
    }
    return series;
  }

  void _select(Offset position, double width, int pointCount) {
    final plotWidth = width - _ScoreChartPainter.leftPad - _ScoreChartPainter.rightPad;
    final x = position.dx - _ScoreChartPainter.leftPad;
    final index = (x / plotWidth * (pointCount - 1)).round().clamp(0, pointCount - 1);
    if (index != _selected) setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final series = _cumulative();
    final pointCount = series.first.length;
    // Une donne ajoutee ou supprimee ramene la selection sur la derniere.
    if (pointCount != _pointCount) {
      _pointCount = pointCount;
      _selected = null;
    }
    final selected = (_selected ?? pointCount - 1).clamp(0, pointCount - 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected == 0 ? 'Depart' : 'Apres la donne $selected',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (int i = 0; i < series.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: playerSeriesColors[i % playerSeriesColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.game.playerNames[i]} ${formatScore(series[i][selected])}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _select(d.localPosition, width, pointCount),
                onHorizontalDragStart: (d) =>
                    _select(d.localPosition, width, pointCount),
                onHorizontalDragUpdate: (d) =>
                    _select(d.localPosition, width, pointCount),
                child: CustomPaint(
                  size: Size(width, 180),
                  painter: _ScoreChartPainter(
                    series: series,
                    selected: selected,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  static const leftPad = 40.0;
  static const rightPad = 8.0;
  static const topPad = 8.0;
  static const bottomPad = 20.0;

  final List<List<double>> series;
  final int selected;

  _ScoreChartPainter({required this.series, required this.selected});

  /// Pas "rond" (1, 2, 5 x 10^n) pour environ [target] intervalles.
  static double _niceStep(double range, int target) {
    final raw = range / target;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return nice * magnitude;
  }

  void _drawText(Canvas canvas, String text, Offset anchor, {bool alignRight = false, bool center = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = anchor.dx;
    if (alignRight) dx -= painter.width;
    if (center) dx -= painter.width / 2;
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pointCount = series.first.length;
    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );

    var minY = 0.0;
    var maxY = 0.0;
    for (final s in series) {
      for (final v in s) {
        minY = math.min(minY, v);
        maxY = math.max(maxY, v);
      }
    }
    if (maxY - minY < 1) {
      minY -= 10;
      maxY += 10;
    }
    final step = _niceStep(maxY - minY, 4);
    minY = (minY / step).floor() * step;
    maxY = (maxY / step).ceil() * step;

    double xOf(int i) => pointCount == 1
        ? plot.center.dx
        : plot.left + plot.width * i / (pointCount - 1);
    double yOf(double v) => plot.bottom - plot.height * (v - minY) / (maxY - minY);

    // Grille horizontale discrete, ligne du zero plus marquee.
    final gridPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 1;
    final zeroPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var v = minY; v <= maxY + step / 2; v += step) {
      final y = yOf(v);
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        v == 0 ? zeroPaint : gridPaint,
      );
      _drawText(canvas, formatMaybeInt(v), Offset(plot.left - 6, y), alignRight: true);
    }

    // Numeros de donne en abscisse (espaces si beaucoup de donnes).
    final labelEvery = math.max(1, (pointCount / 8).ceil());
    for (int i = 0; i < pointCount; i += labelEvery) {
      _drawText(canvas, '$i', Offset(xOf(i), plot.bottom + 10), center: true);
    }

    // Repere vertical de la donne selectionnee.
    final selX = xOf(selected);
    canvas.drawLine(
      Offset(selX, plot.top),
      Offset(selX, plot.bottom),
      Paint()
        ..color = AppColors.textMuted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Courbes.
    for (int p = 0; p < series.length; p++) {
      final color = playerSeriesColors[p % playerSeriesColors.length];
      final path = Path()..moveTo(xOf(0), yOf(series[p][0]));
      for (int i = 1; i < pointCount; i++) {
        path.lineTo(xOf(i), yOf(series[p][i]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Points de la donne selectionnee, entoures de la couleur de fond.
    for (int p = 0; p < series.length; p++) {
      final center = Offset(selX, yOf(series[p][selected]));
      canvas.drawCircle(center, 6, Paint()..color = AppColors.surface);
      canvas.drawCircle(
        center,
        4,
        Paint()..color = playerSeriesColors[p % playerSeriesColors.length],
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreChartPainter old) =>
      old.selected != selected || old.series != series;
}
