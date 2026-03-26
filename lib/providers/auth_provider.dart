// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/*class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email and password cannot be empty.',
      );
      return;
    }

    if (!email.contains('@')) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter a valid email address.',
      );
      return;
    }

    // Mock successful login
    final user = AppUser(
      id: 'user_001',
      name: email.split('@').first.replaceAll('.', ' ').split(' ').map((w) =>
        w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
      ).join(' '),
      email: email,
      quizzesTaken: 12,
      totalPoints: 1480,
      totalCorrect: 89,
      totalAnswered: 120,
    );

    state = state.copyWith(isLoading: false, user: user);
  }

  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'All fields are required.',
      );
      return;
    }

    final user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );

    state = state.copyWith(isLoading: false, user: user);
  }

  void addQuizResult({
    required int correct,
    required int total,
    required int points,
  }) {
    final currentUser = state.user;
    if (currentUser == null) return;
    state = state.copyWith(
      user: currentUser.copyWith(
        quizzesTaken: currentUser.quizzesTaken + 1,
        totalPoints: currentUser.totalPoints + points,
        totalCorrect: currentUser.totalCorrect + correct,
        totalAnswered: currentUser.totalAnswered + total,
      ),
    );
  }

  void logout() {
    state = const AuthState();
  }
}*/

class AuthNotifier extends StateNotifier<AuthState> {
  // Use Firebase instances
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState()) {
    // Automatically check if user is already logged in when app starts
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchUserProfile(firebaseUser.uid);
    } else {
      // No logged-in user, done initializing
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      state = state.copyWith(
        user: AppUser.fromMap(doc.data()!),
        isLoading: false,
        isInitializing: false,
      );
    } else {
      state = state.copyWith(isInitializing: false);
    }
  }

  // 1. LIVE LOGIN
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Real Firebase Login
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch the extra details (points, name) from Firestore
      await _fetchUserProfile(result.user!.uid);

    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }


  // 2. LIVE SIGN UP
  // 4. LIVE QUIZ RESULT UPDATE
  Future<void> addQuizResult({
    required int correct,
    required int total,
    required int points,
    String categoryId = '',
    String categoryName = '',
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    // Save to history subcollection
    try {
      final historyRef = _db
          .collection('users')
          .doc(currentUser.id)
          .collection('history')
          .doc();
      await historyRef.set({
        'id': historyRef.id,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'correctAnswers': correct,
        'totalQuestions': total,
        'pointsEarned': points,
        'playedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("History save error: $e");
    }

    // Create the updated user object locally using copyWith
    final updatedUser = currentUser.copyWith(
      quizzesTaken: currentUser.quizzesTaken + 1,
      totalPoints: currentUser.totalPoints + points,
      totalCorrect: currentUser.totalCorrect + correct,
      totalAnswered: currentUser.totalAnswered + total,
    );

    // Update local state so UI updates instantly
    state = state.copyWith(user: updatedUser);

    // Sync with Firebase Cloud
    try {
      await _db
          .collection('users')
          .doc(currentUser.id)
          .update(updatedUser.toMap());
    } catch (e) {
      print("Firestore Update Error: $e");
    }
  }
  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Create account in Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the user profile in Firestore (Your Step 6/7 structure)
      final newUser = AppUser(
        id: result.user!.uid,
        name: name,
        email: email,
        quizzesTaken: 0,
        totalPoints: 0,
        totalCorrect: 0,
        totalAnswered: 0,
      );

      await _db.collection('users').doc(result.user!.uid).set(newUser.toMap());

      state = state.copyWith(isLoading: false, user: newUser);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  // 3. LIVE LOGOUT
  void logout() async {
    await _auth.signOut();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
