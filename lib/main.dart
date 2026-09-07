import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nombres de días/meses en español para los gráficos y el calendario.
  await initializeDateFormatting('es');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DisciplinaApp());
}

class DisciplinaApp extends StatelessWidget {
  const DisciplinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disciplina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Decide entre Login y Home según el estado de sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService(FirebaseAuth.instance);
    return StreamBuilder<User?>(
      stream: auth.authState,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return const LoginScreen();
        }
        return HomeScreen();
      },
    );
  }
}
