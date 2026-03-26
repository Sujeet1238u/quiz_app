class QuizHistory {
  final String id;
  final String categoryId;
  final String categoryName;
  final int correctAnswers;
  final int totalQuestions;
  final int pointsEarned;
  final DateTime playedAt;

  QuizHistory({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.pointsEarned,
    required this.playedAt,
  });

  double get percentage => totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'pointsEarned': pointsEarned,
    'playedAt': playedAt.toIso8601String(),
  };

  factory QuizHistory.fromMap(Map<String, dynamic> map) => QuizHistory(
    id: map['id'] ?? '',
    categoryId: map['categoryId'] ?? '',
    categoryName: map['categoryName'] ?? '',
    correctAnswers: map['correctAnswers'] ?? 0,
    totalQuestions: map['totalQuestions'] ?? 0,
    pointsEarned: map['pointsEarned'] ?? 0,
    playedAt: DateTime.parse(map['playedAt']),
  );
}