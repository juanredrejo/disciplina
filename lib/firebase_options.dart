import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// ⚠️  PEGA AQUÍ TU CONFIGURACIÓN DE FIREBASE  ⚠️
///
/// Cómo conseguirla (5 minutos):
///   1. Entra en https://console.firebase.google.com
///   2. Crea un proyecto (o abre el que hayas creado) → elige un nombre.
///   3. En el panel del proyecto, pulsa la rueda ⚙️ "Configuración del proyecto".
///   4. Baja hasta "Tus aplicaciones". Si no aparece ninguna, pulsa el icono
///      Web `</>` y añade una app (el nombre da igual, p. ej. "disciplina").
///      NO necesitas marcar nada de hosting.
///   5. Te mostrará un objeto `firebaseConfig = { ... }`.
///   6. Copia los valores y pégamelos (o pégalos tú aquí abajo, entre comillas).
///
/// Con esa misma configuración se sincronizarán el móvil y la tablet.
const Map<String, String> _firebaseConfig = {
  'apiKey': 'PASTE_YOUR_API_KEY',
  'authDomain': 'TU-PROYECTO.firebaseapp.com',
  'projectId': 'TU-PROYECTO',
  'storageBucket': 'TU-PROYECTO.appspot.com',
  'messagingSenderId': 'TU_SENDER_ID',
  'appId': 'TU_APP_ID',
};

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: _firebaseConfig['apiKey']!,
      authDomain: _firebaseConfig['authDomain']!,
      projectId: _firebaseConfig['projectId']!,
      storageBucket: _firebaseConfig['storageBucket']!,
      messagingSenderId: _firebaseConfig['messagingSenderId']!,
      appId: _firebaseConfig['appId']!,
    );
  }
}
