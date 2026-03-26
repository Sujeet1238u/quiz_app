// lib/screens/results_screen.dart
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_result.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  String _getGreeting(String name, double percentage) {
    if (percentage >= 90) return 'Amazing, $name! You crushed it! 🏆';
    if (percentage >= 80) return 'Great work, $name! Keep it up! 🎉';
    if (percentage >= 70) return 'Nice one, $name! Almost there! 👍';
    if (percentage >= 60) return 'Not bad, $name! Practice more! 💪';
    return 'Don\'t give up, $name! You\'ll get it! 📚';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final result = quizState.result;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name.split(' ').first ?? 'Champion';
    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Grade Circle ───────────────────────────────────────────────
              _GradeCircle(result: result)
                  .animate()
                  .scale(
                    delay: 200.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),

              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                _getGreeting(userName, result.percentage),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),
              Text(
                '${result.percentage.toStringAsFixed(0)}% score  •  ${result.pointsEarned} points earned',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ).animate(delay: 500.ms).fadeIn(),

              const SizedBox(height: 28),

              // ── Stats Row ──────────────────────────────────────────────────
              _ResultStats(result: result)
                  .animate(delay: 600.ms)
                  .fadeIn()
                  .slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Answer Review ──────────────────────────────────────────────
              Expanded(
                child: _AnswerReview(
                  questions: quizState.questions,
                  userAnswers: quizState.userAnswers,
                ),
              ),

              // ── Buttons ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final categoryId = result.categoryId;
                          ref.read(quizProvider.notifier).resetQuiz();
                          context.go('/quiz/$categoryId');
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(quizProvider.notifier).resetQuiz();
                          context.go('/dashboard');
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Home'),
                      ),
                    ),
                  ],
                ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle(double percentage) {
    if (percentage >= 90) return '🏆 Outstanding!';
    if (percentage >= 80) return '🎉 Excellent Work!';
    if (percentage >= 70) return '👍 Good Job!';
    if (percentage >= 60) return '💪 Not Bad!';
    return '📚 Keep Studying!';
  }
}

class _GradeCircle extends StatelessWidget {
  final QuizResult result;
  const _GradeCircle({required this.result});

  Color get _color {
    if (result.percentage >= 80) return AppTheme.success;
    if (result.percentage >= 60) return const Color(0xFFF57C00);
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.1),
        border: Border.all(color: _color, width: 3),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.grade,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: _color,
            ),
          ),
          Text(
            '${result.percentage.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 13, color: _color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  final QuizResult result;
  const _ResultStats({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _statBox(
          context,
          '${result.correctAnswers}',
          'Correct',
          AppTheme.success,
          Icons.check_circle_outline_rounded,
        ),
        const SizedBox(width: 12),
        _statBox(
          context,
          '${result.totalQuestions - result.correctAnswers}',
          'Wrong',
          AppTheme.error,
          Icons.cancel_outlined,
        ),
        const SizedBox(width: 12),
        _statBox(
          context,
          '${result.pointsEarned}',
          'Points',
          AppTheme.primary,
          Icons.stars_rounded,
        ),
      ],
    );
  }

  Widget _statBox(BuildContext context, String value, String label,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _AnswerReview extends StatelessWidget {
  final List questions;
  final List<int?> userAnswers;

  const _AnswerReview({required this.questions, required this.userAnswers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer Review',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final q = questions[i];
              final userIdx = userAnswers[i];
              final isCorrect = userIdx == q.correctIndex;
              final isUnanswered = userIdx == null;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnanswered
                        ? Colors.grey[300]!
                        : isCorrect
                            ? AppTheme.success.withOpacity(0.4)
                            : AppTheme.error.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isUnanswered
                            ? Colors.grey[200]
                            : isCorrect
                                ? AppTheme.success.withOpacity(0.15)
                                : AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isUnanswered
                                  ? Colors.grey[600]
                                  : isCorrect
                                      ? AppTheme.success
                                      : AppTheme.error)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            isUnanswered
                                ? '⏰ Time expired'
                                : isCorrect
                                    ? '✓ ${q.options[q.correctIndex]}'
                                    : '✗ Your: ${q.options[userIdx]}  •  Correct: ${q.options[q.correctIndex]}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnanswered
                                  ? Colors.grey
                                  : isCorrect
                                      ? AppTheme.success
                                      : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
