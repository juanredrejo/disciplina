import 'package:flutter/material.dart';
import '../models/habit.dart';

/// Tarjeta de un hábito en la lista de "Hoy".
class HabitCard extends StatelessWidget {
  final Habit habit;
  final HabitStats stats;
  final bool dueToday;
  final bool doneToday;
  final VoidCallback onToggleToday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  const HabitCard({
    super.key,
    required this.habit,
    required this.stats,
    required this.dueToday,
    required this.doneToday,
    required this.onToggleToday,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.color);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: dueToday ? onToggleToday : onEdit,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji en un círculo con el color del hábito.
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(habit.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StreakChip(
                          value: stats.currentStreak,
                          active: stats.currentStreak > 0,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          habit.isDaily
                              ? 'Diario'
                              : _weekdaysLabel(habit.weekdays),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón de check de hoy.
              if (dueToday)
                _CheckButton(done: doneToday, color: color)
              else
                Icon(Icons.schedule,
                    size: 28, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdaysLabel(List<int> wd) {
    const names = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return wd.map((i) => names[i]).join(' ');
  }
}

class _StreakChip extends StatelessWidget {
  final int value;
  final bool active;
  const _StreakChip({required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? const Color(0xFFFB8C00)
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFFF3E0)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 14, color: color),
          const SizedBox(width: 3),
          Text('$value',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool done;
  final Color color;
  const _CheckButton({required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.transparent,
        border: Border.all(
            color: done ? color : Colors.grey, width: done ? 0 : 2.5),
      ),
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 28)
          : const SizedBox.shrink(),
    );
  }
}
