import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/widget_service.dart';

/// Pestaña de ajustes: widget de pantalla de inicio + cuenta.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _addWidget(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await WidgetService.requestAdd();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
            'Si tu móvil no abre el diálogo, añádelo a mano: mantén pulsado el '
            'fondo de la pantalla → Widgets → Disciplina.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
            '¿Seguro? Tus datos se quedan guardados en la nube. '
            'Vuelve a entrar con la misma cuenta cuando quieras.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true) {
      await AuthService(FirebaseAuth.instance).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Ajustes',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // ---- Widget de pantalla de inicio ----
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.widgets, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Widget de la pantalla de inicio',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Añade el widget para ver tus hábitos de hoy y marcarlos '
                  'con un toque, sin abrir la app. Se sincroniza en tiempo '
                  'real con el móvil y la tablet.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _addWidget(context),
                  icon: const Icon(Icons.add_home),
                  label: const Text('Añadir widget'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ---- Cuenta ----
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Cuenta',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(user?.email ?? '—',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Disciplina v1.1 — tus datos se guardan en Firebase y se '
          'sincronizan entre tus dispositivos.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
