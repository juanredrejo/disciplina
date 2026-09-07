import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

/// Bottom sheet para crear o editar un hábito.
Future<void> showAddHabitSheet(
  BuildContext context,
  HabitService service, {
  Habit? habit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _HabitForm(service: service, existing: habit),
  );
}

class _HabitForm extends StatefulWidget {
  final HabitService service;
  final Habit? existing;
  const _HabitForm({required this.service, this.existing});

  @override
  State<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<_HabitForm> {
  final _name = TextEditingController();
  final _uuid = const Uuid();

  static const _emojis = [
    '✅', '💧', '📚', '🏃', '🧘', '🥗', '😴', '💪',
    '✍️', '🎯', '🚭', '💊', '🎨', '🎸', '🧹', '💰',
  ];
  static const _colors = [
    0xFF4CAF50, 0xFF2196F3, 0xFF9C27B0, 0xFFFF5722,
    0xFF009688, 0xFF3F51B5, 0xFFE91E63, 0xFF795548,
  ];

  late String _emoji;
  late int _color;
  late Set<int> _weekdays; // 0=Lunes..6=Domingo
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name.text = h?.name ?? '';
    _emoji = h?.emoji ?? '✅';
    _color = h?.color ?? _colors[0];
    _weekdays = h == null ? {} : Set<int>.from(h.weekdays);
  }

  bool get _isDaily => _weekdays.isEmpty;

  void _toggleWeekday(int i) {
    setState(() {
      if (_weekdays.contains(i)) {
        _weekdays.remove(i);
      } else {
        _weekdays.add(i);
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ponle un nombre al hábito')));
      return;
    }
    setState(() => _busy = true);
    try {
      final data = Habit(
        id: widget.existing?.id ?? _uuid.v4(),
        name: name,
        emoji: _emoji,
        color: _color,
        weekdays: _weekdays.toList()..sort(),
        createdAt: widget.existing?.createdAt ??
            DateTime.now().millisecondsSinceEpoch,
        completedDates: widget.existing?.completedDates ?? [],
      );
      if (widget.existing == null) {
        await widget.service.addHabit(data);
      } else {
        await widget.service.updateHabit(data);
      }
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')));
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Editar hábito' : 'Nuevo hábito',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: !isEdit,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: '¿Qué quieres hacer?'),
            ),
            const SizedBox(height: 18),
            Text('Icono', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(_color).withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? Color(_color) : Colors.transparent,
                          width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: selected
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Días', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => setState(() => _weekdays.clear()),
                    style: FilledButton.styleFrom(
                        backgroundColor:
                            _isDaily ? theme.colorScheme.primary : null),
                    child: const Text('Todos los días'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .asMap()
                  .entries
                  .map((e) {
                    final i = e.key;
                    final selected = _weekdays.contains(i);
                    return GestureDetector(
                      onTap: () => _toggleWeekday(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(_color)
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          e.value,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (isEdit)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              widget.service.deleteHabit(widget.existing!.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
