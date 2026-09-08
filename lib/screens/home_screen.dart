import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/widget_service.dart';
import 'today_tab.dart';
import 'calendar_tab.dart';
import 'stats_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final HabitService _service;
  StreamSubscription<List<Habit>>? _widgetSub;

  @override
  void initState() {
    super.initState();
    _service = HabitService(FirebaseAuth.instance, FirebaseFirestore.instance);
    // Cada vez que cambian los hábitos (en este u otro dispositivo),
    // refrescamos el widget de la pantalla de inicio.
    _widgetSub = _service.watchHabits().listen(
      (habits) => WidgetService.sync(habits, DateTime.now()),
      onError: (Object e) => debugPrint('Widget sync error: $e'),
    );
  }

  @override
  void dispose() {
    _widgetSub?.cancel();
    super.dispose();
  }

  Future<void> _showWidgetDialog() async {
    await WidgetService.requestAdd();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Si tu móvil no abre el diálogo, añádelo a mano: mantén pulsado el '
            'fondo de la pantalla → Widgets → Disciplina.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disciplina',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets_outlined),
            tooltip: 'Widget de pantalla de inicio',
            onPressed: _showWidgetDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          TodayTab(service: _service),
          CalendarTab(service: _service),
          StatsTab(service: _service),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'Hoy'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendario'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Estadísticas'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes'),
        ],
      ),
    );
  }
}
