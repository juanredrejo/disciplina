import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../firebase_options.dart';
import '../models/habit.dart';
import 'habit_service.dart';

/// Sincroniza el estado de los hábitos con el widget de la pantalla de inicio.
///
/// Cómo funciona:
///  - [sync] guarda en SharedPreferences (leídos por el provider nativo) la
///    fecha de hoy y el JSON de los hábitos, y pide al sistema redibujar el
///    widget.
///  - [registerWidgetCallback] registra la función que se ejecuta en segundo
///    plano cuando el usuario toca un hábito DENTRO del widget (marca/desmarca
///    en Firestore y vuelve a actualizar el widget).
class WidgetService {
  static const String qualifiedAndroidName = 'com.disciplina.app.HabitWidgetProvider';

  /// Pone el widget al día con los hábitos actuales.
  /// Devuelve true si el widget está instalado y se actualizó.
  static Future<bool> sync(List<Habit> habits, DateTime now) async {
    final today = Dates.startOfDay(now);
    final todayKey = Dates.key(today);
    final due = habits.where((h) => h.isDueOn(today)).toList();
    final items = due
        .map((h) => {
              'id': h.id,
              'name': h.name,
              'emoji': h.emoji,
              'done': h.completedDates.contains(todayKey),
            })
        .toList();
    final done = due
        .where((h) => h.completedDates.contains(todayKey))
        .length;

    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('dateKey', todayKey),
        HomeWidget.saveWidgetData<String>('dateLabel', _dateLabel(today)),
        HomeWidget.saveWidgetData<String>('progress', '$done/${due.length}'),
        HomeWidget.saveWidgetData<String>('habits', jsonEncode(items)),
      ]);
      final ok = await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
      return ok ?? false;
    } catch (e) {
      // Widget no instalado o error de plataforma: no es grave.
      debugPrint('Widget sync error: $e');
      return false;
    }
  }

  /// Pide al sistema añadir el widget (Android 8+). En launchers que no lo
  /// soportan devuelve sin hacer nada y el usuario lo añade a mano desde el
  /// menú de widgets.
  static Future<void> requestAdd() async {
    try {
      await HomeWidget.requestPinWidget(qualifiedAndroidName: qualifiedAndroidName);
    } catch (e) {
      debugPrint('requestPinWidget error: $e');
    }
  }

  /// Registra el callback de interactividad (taps dentro del widget).
  /// Debe llamarse una vez en [main], antes de runApp.
  static Future<void> registerWidgetCallback() async {
    try {
      await HomeWidget.registerInteractivityCallback(_widgetCallback);
    } catch (e) {
      debugPrint('registerInteractivityCallback error: $e');
    }
  }

  /// Se ejecuta en un ISOLATE EN SEGUNDO PLANO cuando se toca el widget.
  /// No comparte estado con la app: inicializa Firebase si hace falta.
  @pragma('vm:entry-point')
  static Future<void> _widgetCallback(Uri? uri) async {
    try {
      if (uri == null || uri.host != 'toggle') return;
      final id = uri.queryParameters['id'] ?? '';
      if (id.isEmpty) return;

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final service = HabitService(FirebaseAuth.instance,
          FirebaseFirestore.instance);
      await service.toggle(id, Dates.key(DateTime.now()));
      // Volver a dibujar el widget con el nuevo estado.
      await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
    } catch (e) {
      debugPrint('Widget callback error: $e');
    }
  }

  static String _dateLabel(DateTime d) {
    const names = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    return '${names[d.weekday - 1]} ${d.day} ${d.month}';
  }
}
