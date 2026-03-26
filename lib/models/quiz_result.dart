// lib/models/quiz_result.dart

class QuizResult {
  final String categoryId;
  final int totalQuestions;
  final int correctAnswers;
  final int pointsEarned;
  final List<bool> answerResults;

  const QuizResult({
    required this.categoryId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.pointsEarned,
    required this.answerResults,
  });

  double get percentage =>
      totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;

  String get grade {
    final p = percentage;
    if (p >= 90) return 'S';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    return 'D';
  }
}
