import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';

/// Theme-aware tooltip styling shared by all 4 Dashboard charts, so the
/// tap-to-see-value tooltip always uses the current Light/Dark theme's
/// colors instead of fl_chart's fixed dark default (which was unreadable
/// once Light theme was added).
class ChartStyle {
  static BarTouchTooltipData tooltipData({String Function(double)? formatValue}) {
    return BarTouchTooltipData(
      getTooltipColor: (group) => AppColors.surfaceLight,
      tooltipRoundedRadius: 8,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        final text = formatValue != null ? formatValue(rod.toY) : rod.toY.toStringAsFixed(0);
        return BarTooltipItem(
          text,
          TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
        );
      },
    );
  }
}
