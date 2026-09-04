import 'package:firebase_auth/firebase_auth.dart';

/// OWNER: Person A
/// Person B calls these methods from login_screen.dart / signup_screen.dart
/// and listens to authStateChanges to decide whether to show login or dashboard.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Creates a Firebase Auth user AND a matching Firestore user doc
  /// (bankBalance: 10000.0 starting default) via FirestoreService.
  /// TODO(Person A): implement, throw readable exceptions on failure
  /// (email-already-in-use, weak-password, etc.) so Person B can show
  /// a SnackBar with e.toString() or a mapped message.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// TODO(Person A): implement sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// TODO(Person A): implement sign out
  Future<void> signOut() async {
    throw UnimplementedError('TODO: Person A');
  }
}
