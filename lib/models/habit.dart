import 'dart:math';

/// Un hábito que el usuario quiere cumplir.
class Habit {
  final String id;
  final String name;
  final String emoji;
  final int color; // color ARGB
  final List<int> weekdays; // 0=Lunes ... 6=Domingo. Vacío = todos los días.
  final int createdAt; // epoch millis
  final List<String> completedDates; // fechas "yyyy-MM-dd" completadas

  Habit({
    required this.id,
    required this.name,
    this.emoji = '✅',
    this.color = 0xFF4CAF50,
    this.weekdays = const [],
    required this.createdAt,
    this.completedDates = const [],
  });

  bool get isDaily => weekdays.isEmpty;

  /// ¿Este hábito "debe cumplirse" el día dado?
  bool isDueOn(DateTime day) {
    if (weekdays.isEmpty) return true;
    // DateTime.weekday: 1=Lunes..7=Domingo → convertimos a 0..6
    return weekdays.contains(day.weekday - 1);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': color,
        'weekdays': weekdays,
        'createdAt': createdAt,
        'completedDates': completedDates,
      };

  factory Habit.fromMap(Map<String, dynamic> m) => Habit(
        id: m['id'] as String,
        name: m['name'] as String? ?? 'Hábito',
        emoji: m['emoji'] as String? ?? '✅',
        color: (m['color'] as int?) ?? 0xFF4CAF50,
        weekdays:
            (m['weekdays'] as List?)?.map((e) => e as int).toList() ?? [],
        createdAt: (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        completedDates:
            (m['completedDates'] as List?)?.map((e) => e as String).toList() ??
                [],
      );
}

/// Utilidades de fecha compartidas.
class Dates {
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime fromKey(String k) {
    final p = k.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Estadísticas y rachas de un hábito.
class HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final int dueInLast30;
  final int doneInLast30;

  HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.dueInLast30,
    required this.doneInLast30,
  });

  double get last30Rate =>
      dueInLast30 == 0 ? 0 : doneInLast30 / dueInLast30;
}

/// Calcula las estadísticas de un hábito a partir de hoy.
HabitStats computeStats(Habit habit, DateTime now) {
  final today = Dates.startOfDay(now);
  final set = habit.completedDates.toSet();

  int due = 0, done = 0;
  // Racha actual: contar hacia atrás desde hoy (o ayer si hoy aún no se ha hecho).
  int current = 0;
  var cursor = today;
  if (set.contains(Dates.key(today))) {
    current++;
    cursor = today.subtract(const Duration(days: 1));
  }
  while (true) {
    if (habit.isDueOn(cursor)) {
      if (set.contains(Dates.key(cursor))) {
        current++;
      } else {
        break;
      }
    }
    cursor = cursor.subtract(const Duration(days: 1));
    if (cursor.year < today.year - 5) break; // tope de seguridad
  }

  // Racha máxima + totales, recorriendo desde la creación hasta hoy.
  var longest = 0;
  var run = 0;
  totalCompletions = 0;
  var start = DateTime.fromMillisecondsSinceEpoch(habit.createdAt);
  start = Dates.startOfDay(start);
  var d = start;
  while (!d.isAfter(today)) {
    if (habit.isDueOn(d)) {
      final isDone = set.contains(Dates.key(d));
      if (isDone) {
        totalCompletions++;
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    // últimos 30 días
    final daysAgo = today.difference(d).inDays;
    if (daysAgo < 30) {
      due++;
      if (set.contains(Dates.key(d))) done++;
    }
    d = d.add(const Duration(days: 1));
  }

  return HabitStats(
    currentStreak: current,
    longestStreak: max(longest, current),
    totalCompletions: totalCompletions,
    dueInLast30: due,
    doneInLast30: done,
  );
}
