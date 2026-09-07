import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class StatsTab extends StatelessWidget {
  final HabitService service;
  const StatsTab({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return StreamBuilder<List<Habit>>(
      stream: service.watchHabits(),
      builder: (context, snap) {
        final habits = snap.data ?? [];
        if (habits.isEmpty) {
          return Center(
            child: Text(
              'Añade hábitos para ver tus estadísticas.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }

        // Cumplimiento por día de la última semana (0..1).
        final week = _last7Days(now);
        final weekData = <double>[];
        final weekLabels = <String>[];
        const dayLetters = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
        for (final d in week) {
          final due = habits.where((h) => h.isDueOn(d)).toList();
          final done = due
              .where((h) => h.completedDates.contains(Dates.key(d)))
              .length;
          weekData.add(due.isEmpty ? 0 : done / due.length);
          weekLabels.add(dayLetters[d.weekday % 7]);
        }

        // Global últimos 30 días.
        var totalDue = 0, totalDone = 0;
        for (final h in habits) {
          final s = computeStats(h, now);
          totalDue += s.dueInLast30;
          totalDone += s.doneInLast30;
        }
        final global30 = totalDue == 0 ? 0.0 : totalDone / totalDue;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tarjeta resumen global.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _Ring(value: global30, color: theme.colorScheme.primary),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cumplimiento · 30 días',
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text('${(global30 * 100).round()}%',
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '$totalDone de $totalDue hábitos al día',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gráfico semanal.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Última semana',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (g, x, p, d) {
                                final v =
                                    (x < weekData.length) ? weekData[x] : 0;
                                return BarTooltipItem(
                                  '${(v * 100).round()}%',
                                  TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= weekLabels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final isLast = i == weekLabels.length - 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      isLast ? 'Hoy' : weekLabels[i],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isLast
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          axisSideTitles: const AxisSideTitles(showTitles: false),
                          barGroups: List.generate(weekData.length, (i) {
                            final v = weekData[i];
                            final isLast = i == weekData.length - 1;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: v,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  color: isLast
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary
                                          .withValues(alpha: 0.45),
                                ),
                              ],
                            );
                          }),
                          minY: 0,
                          maxY: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Por hábito',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...habits.map((h) => _HabitStatRow(habit: h, now: now)),
          ],
        );
      },
    );
  }

  List<DateTime> _last7Days(DateTime now) {
    final t = Dates.startOfDay(now);
    return List.generate(7, (i) => t.subtract(Duration(days: 6 - i)));
  }
}

class _HabitStatRow extends StatelessWidget {
  final Habit habit;
  final DateTime now;
  const _HabitStatRow({required this.habit, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.color);
    final s = computeStats(habit, now);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 14, color: Color(0xFFFB8C00)),
                      const SizedBox(width: 3),
                      Text('${s.currentStreak}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFB8C00))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.last30Rate,
                minHeight: 8,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(label: 'Racha actual', value: '${s.currentStreak}'),
                _Stat(label: 'Récord', value: '${s.longestStreak}'),
                _Stat(label: 'Total', value: '${s.totalCompletions}'),
                _Stat(
                    label: '30 días',
                    value: '${(s.last30Rate * 100).round()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Anillo de progreso circular.
class _Ring extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const _Ring({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final size = 84.0;
    final strokeWidth = 10.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            color: color,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
