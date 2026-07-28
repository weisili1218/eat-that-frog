import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../shared/animations/fade_up.dart';
import '../settings/settings_provider.dart';
import 'stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final data = ref.watch(statsProvider);

    return ColoredBox(
      color: AppColors.ivoryL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeUp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 58, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['progressMono'], style: AppText.mono()),
                  const SizedBox(height: 6),
                  Text(s['statsTitle'], style: AppText.title()),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
              children: [
                FadeUp(index: 1, child: _StreakCard(data: data, strings: s)),
                const SizedBox(height: 16),
                FadeUp(index: 2, child: _ChartCard(data: data, strings: s)),
                const SizedBox(height: 16),
                FadeUp(index: 3, child: _FrogRateCard(rate: data.frogRate, strings: s)),
                const SizedBox(height: 16),
                FadeUp(
                  index: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                            value: data.frogsEaten, label: s['frogsEatenLabel']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                            value: data.tadpolesEaten, label: s['tadpolesEatenLabel']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration([double radius = AppRadius.statCard]) => BoxDecoration(
      color: AppColors.ivoryL,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.ivoryD),
    );

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.data, required this.strings});
  final StatsData data;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(strings['streakLabel'],
              style: AppText.mono(size: 11, color: AppColors.accent, letterSpacing: 0.12)),
          const SizedBox(height: 12),
          Text('${data.streak}', style: AppText.statHuge()),
          const SizedBox(height: 6),
          Text(strings['streakSub'], style: AppText.body(color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          Transform.rotate(
            angle: -0.009,
            child: Text(
              data.frogDoneToday ? strings['hintDone'] : strings['hintNotDone'],
              style: AppText.caveat(size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.data, required this.strings});
  final StatsData data;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final maxVal =
        data.bars.map((b) => b.value).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal < 1 ? 1 : maxVal).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings['chartTitle'], style: AppText.cardTitle()),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY * 1.25, // headroom for value labels
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 4,
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${data.bars[group.x.toInt()].value}',
                      AppText.mono(size: 10.5, color: AppColors.inkSoft, letterSpacing: 0),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.bars.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            data.bars[i].label,
                            style: AppText.mono(
                                size: 9, color: AppColors.cloud, letterSpacing: 0.05),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < data.bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      showingTooltipIndicators: const [0],
                      barRods: [
                        BarChartRodData(
                          toY: data.bars[i].value.toDouble(),
                          width: 20,
                          color: data.bars[i].isToday
                              ? AppColors.accent
                              : AppColors.chartBar,
                          borderRadius: BorderRadius.circular(5),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY * 1.25,
                            color: AppColors.ivoryM,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrogRateCard extends StatelessWidget {
  const _FrogRateCard({required this.rate, required this.strings});
  final int rate;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(strings['frogRateLabel'], style: AppText.cardTitle()),
              Text('$rate%',
                  style: AppText.mono(size: 13, color: AppColors.accent, letterSpacing: 0)),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.ivoryM,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(AppRadius.smallCard),
      child: Column(
        children: [
          Text('$value', style: AppText.statMedium()),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.mono(size: 9.5, color: AppColors.cloud, letterSpacing: 0.08),
          ),
        ],
      ),
    );
  }
}
