// lib/models/user.dart

/*class AppUser {
  final String id;
  final String name;
  final String email;
  final int quizzesTaken;
  final int totalPoints;
  final int totalCorrect;
  final int totalAnswered;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.quizzesTaken = 0,
    this.totalPoints = 0,
    this.totalCorrect = 0,
    this.totalAnswered = 0,
  });

  double get accuracy =>
      totalAnswered == 0 ? 0 : (totalCorrect / totalAnswered) * 100;

  AppUser copyWith({
    int? quizzesTaken,
    int? totalPoints,
    int? totalCorrect,
    int? totalAnswered,
  }) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      totalPoints: totalPoints ?? this.totalPoints,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAnswered: totalAnswered ?? this.totalAnswered,
    );
  }
}
*/

class AppUser {
  final String id;
  final String name;
  final String email;
  final int quizzesTaken;
  final int totalPoints;
  final int totalCorrect;
  final int totalAnswered;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.quizzesTaken = 0,
    this.totalPoints = 0,
    this.totalCorrect = 0,
    this.totalAnswered = 0,
  });

  // Helper to calculate accuracy %
  double get accuracy => totalAnswered == 0 ? 0 : (totalCorrect / totalAnswered) * 100;

  // 1. Convert AppUser object to a Map (to SAVE to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'quizzesTaken': quizzesTaken,
      'totalPoints': totalPoints,
      'totalCorrect': totalCorrect,
      'totalAnswered': totalAnswered,
    };
  }

  // 2. Create AppUser object from a Map (to READ from Firestore)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      quizzesTaken: map['quizzesTaken'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      totalCorrect: map['totalCorrect'] ?? 0,
      totalAnswered: map['totalAnswered'] ?? 0,
    );
  }

  // 3. Helper to update local data (optional but recommended)
  AppUser copyWith({
    String? name,
    int? quizzesTaken,
    int? totalPoints,
    int? totalCorrect,
    int? totalAnswered,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      totalPoints: totalPoints ?? this.totalPoints,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAnswered: totalAnswered ?? this.totalAnswered,
    );
  }
}