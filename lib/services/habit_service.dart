import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

/// Capa de datos: Firestore + Auth.
///
/// Estructura:
///   users/{uid}/habits/{habitId}  →  documento Habit
class HabitService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  HabitService(this._auth, this._firestore);

  String get _uid => _auth.currentUser?.uid ?? '';
  CollectionReference<Map<String, dynamic>> get _habits =>
      _firestore.collection('users').doc(_uid).collection('habits');

  /// Stream en vivo: cada cambio (en este o el otro dispositivo) se refleja.
  Stream<List<Habit>> watchHabits() {
    return _habits.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Habit.fromMap({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<void> addHabit(Habit habit) => _habits.doc(habit.id).set(habit.toMap());

  Future<void> updateHabit(Habit habit) =>
      _habits.doc(habit.id).update(habit.toMap());

  Future<void> deleteHabit(String id) => _habits.doc(id).delete();

  /// Alterna la marcación de un hábito en una fecha, de forma atómica.
  Future<void> toggle(String habitId, String dateKey) {
    return _firestore.runTransaction((tx) async {
      final ref = _habits.doc(habitId);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final dates =
          Set<String>.from(data['completedDates'] as List? ?? []);
      if (dates.contains(dateKey)) {
        dates.remove(dateKey);
      } else {
        dates.add(dateKey);
      }
      tx.update(ref, {'completedDates': dates.toList()});
    });
  }
}
