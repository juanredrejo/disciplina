import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_sheet.dart';

class TodayTab extends StatelessWidget {
  final HabitService service;
  const TodayTab({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayKey = Dates.key(now);
    final dateLabel =
        DateFormat('EEEE, d MMMM', 'es').format(now).replaceAll(' de ', ' ');

    return StreamBuilder<List<Habit>>(
      stream: service.watchHabits(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final habits = snap.data ?? [];

        if (habits.isEmpty) {
          return _EmptyState(
            onAdd: () => showAddHabitSheet(context, service),
          );
        }

        // Progreso de hoy: cuántos de los que están "debido" hoy ya están hechos.
        final dueToday = habits.where((h) => h.isDueOn(now)).toList();
        final doneToday =
            dueToday.where((h) => h.completedDates.contains(todayKey)).length;
        final progress =
            dueToday.isEmpty ? 0.0 : doneToday / dueToday.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$doneToday/${dueToday.length} hoy',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final habit = habits[i];
                  final due = habit.isDueOn(now);
                  final done = habit.completedDates.contains(todayKey);
                  final stats = computeStats(habit, now);
                  return HabitCard(
                    habit: habit,
                    stats: stats,
                    dueToday: due,
                    doneToday: done,
                    onToggleToday: () =>
                        service.toggle(habit.id, todayKey),
                    onEdit: () =>
                        showAddHabitSheet(context, service, habit: habit),
                    onDelete: () => service.deleteHabit(habit.id),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 80,
                color: Color(0xFFB0BEC5)),
            const SizedBox(height: 16),
            Text('Aún no tienes hábitos',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Empieza por algo pequeño que quieras mantener cada día.\n'
              'Beber agua, leer, hacer ejercicio, meditar…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Añadir mi primer hábito'),
            ),
          ],
        ),
      ),
    );
  }
}
