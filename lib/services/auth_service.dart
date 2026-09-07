import 'package:firebase_auth/firebase_auth.dart';

/// Autenticación por email/contraseña.
///
/// El usuario crea una cuenta la primera vez; usa la MISMA cuenta en el
/// móvil y en la tablet → todo lo que marque en uno aparece en el otro.
class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;
  String? get email => _auth.currentUser?.email;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
