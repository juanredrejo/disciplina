import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/add_habit_sheet.dart';

/// Rejilla tipo HelloHabit: cada fila un hábito, cada columna un día del mes.
class CalendarTab extends StatefulWidget {
  final HabitService service;
  const CalendarTab({super.key, required this.service});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  int _daysInMonth() =>
      DateTime(_month.year, _month.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return StreamBuilder<List<Habit>>(
      stream: widget.service.watchHabits(),
      builder: (context, snap) {
        final habits = snap.data ?? [];
        final days = _daysInMonth();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'es')
                          .format(_month)
                          .capitalize(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shift(1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        showAddHabitSheet(context, widget.service),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Añade un hábito para ver su calendario.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: habits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final habit = habits[i];
                        return _HabitMonthRow(
                          habit: habit,
                          month: _month,
                          days: days,
                          today: now,
                          onDayTap: (day) => widget.service.toggle(
                              habit.id, Dates.key(day)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HabitMonthRow extends StatelessWidget {
  final Habit habit;
  final DateTime month;
  final int days;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  const _HabitMonthRow({
    required this.habit,
    required this.month,
    required this.days,
    required this.today,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.color);
    final set = habit.completedDates.toSet();
    final todayKey = Dates.key(today);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Rejilla de días.
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
              children: List.generate(days, (i) {
                final day = DateTime(month.year, month.month, i + 1);
                final key = Dates.key(day);
                final isDone = set.contains(key);
                final isFuture = day.isAfter(today);
                final isDue = habit.isDueOn(day);
                final isToday = key == todayKey;

                Color bg;
                if (isDone) {
                  bg = color;
                } else if (isFuture) {
                  bg = Colors.transparent;
                } else if (isDue) {
                  bg = color.withValues(alpha: 0.12);
                } else {
                  bg = Colors.transparent;
                }

                return GestureDetector(
                  onTap: isFuture ? null : () => onDayTap(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday
                            ? theme.colorScheme.primary
                            : (isDue && !isDone && !isFuture)
                                ? color.withValues(alpha: 0.4)
                                : Colors.transparent,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? Icon(Icons.check,
                            size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isFuture
                                  ? theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
