// lib/screens/quiz_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const QuizScreen({super.key, required this.categoryId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _isBookmarking = false;

  Future<void> _toggleBookmark(BuildContext context) async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      final question = ref.read(quizProvider).currentQuestion;
      final user = ref.read(authProvider).user;
      if (question == null || user == null) return;

      final bookmarksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('bookmarks');

      final existing = await bookmarksRef.doc(question.id).get();

      if (existing.exists) {
        await bookmarksRef.doc(question.id).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bookmark removed'),
                behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        await bookmarksRef.doc(question.id).set({
          'id': question.id,
          'text': question.text,
          'options': question.options,
          'correctIndex': question.correctIndex,
          'category': question.category,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Question bookmarked! 🔖'),
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).startQuiz(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    ref.listen<QuizState>(quizProvider, (prev, next) {
      if (next.status == QuizStatus.finished && next.result != null) {
        final result = next.result!;
        final currentUser = ref.read(authProvider).user;
        if (currentUser != null) {
          final cat = mockCategories.firstWhere(
                (c) => c.id == result.categoryId,
            orElse: () => mockCategories.first,
          );
          ref.read(authProvider.notifier).addQuizResult(
            correct: result.correctAnswers,
            total: result.totalQuestions,
            points: result.pointsEarned,
            categoryId: result.categoryId,
            categoryName: cat.name,
          );
        }
        context.pushReplacement('/results');
      }
    });

    final category = mockCategories.firstWhere(
          (c) => c.id == widget.categoryId,
      orElse: () => mockCategories.first,
    );

    if (quizState.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ── Header ──────────────────────────────────────────────────
              _QuizHeader(
                category: category.name,
                currentIndex: quizState.currentIndex,
                total: quizState.totalQuestions,
                onExit: () => _confirmExit(context),
                onBookmark: () => _toggleBookmark(context),
                isBookmarking: _isBookmarking,
              ),

              const SizedBox(height: 20),

              // ── Progress Bar ─────────────────────────────────────────────
              _ProgressBar(
                current: quizState.currentIndex + 1,
                total: quizState.totalQuestions,
              ),

              const SizedBox(height: 20),

              // ── Timer ────────────────────────────────────────────────────
              _TimerWidget(secondsLeft: quizState.secondsLeft),

              const SizedBox(height: 28),

              // ── Question ─────────────────────────────────────────────────
              if (quizState.currentQuestion != null)
                _QuestionCard(
                  key: ValueKey(quizState.currentIndex),
                  questionText: quizState.currentQuestion!.text,
                ),

              const SizedBox(height: 24),

              // ── Options ──────────────────────────────────────────────────
              if (quizState.currentQuestion != null)
                ...quizState.currentQuestion!.options.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      key: ValueKey('${quizState.currentIndex}_${e.key}'),
                      index: e.key,
                      text: e.value,
                      status: _getOptionStatus(
                        e.key,
                        quizState.selectedOptionIndex,
                        quizState.currentQuestion!.correctIndex,
                        quizState.status,
                      ),
                      onTap: quizState.status == QuizStatus.active
                          ? () =>
                          ref.read(quizProvider.notifier).selectOption(e.key)
                          : null,
                      animationDelay: 100 + e.key * 80,
                    ),
                  );
                }),

              const Spacer(),

              // ── Next Button ──────────────────────────────────────────────
              if (quizState.status == QuizStatus.reviewing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(quizProvider.notifier).nextQuestion(),
                    icon: Icon(quizState.isLastQuestion
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(
                        quizState.isLastQuestion ? 'See Results' : 'Next'),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _OptionStatus _getOptionStatus(
      int index,
      int? selectedIndex,
      int correctIndex,
      QuizStatus status,
      ) {
    if (status == QuizStatus.active) return _OptionStatus.normal;
    if (index == correctIndex) return _OptionStatus.correct;
    if (index == selectedIndex && index != correctIndex) {
      return _OptionStatus.wrong;
    }
    return _OptionStatus.normal;
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(quizProvider.notifier).resetQuiz();
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _QuizHeader extends StatelessWidget {
  final String category;
  final int currentIndex;
  final int total;
  final VoidCallback onExit;
  final VoidCallback onBookmark;
  final bool isBookmarking;

  const _QuizHeader({
    required this.category,
    required this.currentIndex,
    required this.total,
    required this.onExit,
    required this.onBookmark,
    required this.isBookmarking,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: onExit,
          icon: const Icon(Icons.close_rounded, size: 20),
          style: IconButton.styleFrom(
            foregroundColor: Colors.grey[600],
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Question ${currentIndex + 1} of $total',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
        isBookmarking
            ? Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(10),
          child: const CircularProgressIndicator(strokeWidth: 2),
        )
            : IconButton.outlined(
          onPressed: onBookmark,
          icon: const Icon(Icons.bookmark_border_rounded, size: 20),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side:
            BorderSide(color: AppTheme.primary.withOpacity(0.3)),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int secondsLeft;
  const _TimerWidget({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsLeft <= 5;
    final timerColor = isUrgent ? AppTheme.error : AppTheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: timerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: timerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_rounded, color: timerColor, size: 18),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: timerColor,
                  fontWeight: FontWeight.w800,
                  fontSize: isUrgent ? 20 : 17,
                ),
                child: Text('$secondsLeft s'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String questionText;
  const _QuestionCard({super.key, required this.questionText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        questionText,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: Color(0xFF1A1A2E),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }
}

enum _OptionStatus { normal, correct, wrong }

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final _OptionStatus status;
  final VoidCallback? onTap;
  final int animationDelay;

  const _OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.status,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['A', 'B', 'C', 'D'];

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE8E0F5);
    Color labelBg = AppTheme.primaryLight;
    Color labelFg = AppTheme.primary;
    Color textColor = const Color(0xFF1A1A2E);
    IconData? trailingIcon;

    if (status == _OptionStatus.correct) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = AppTheme.success;
      labelBg = AppTheme.success;
      labelFg = Colors.white;
      textColor = AppTheme.success;
      trailingIcon = Icons.check_circle_rounded;
    } else if (status == _OptionStatus.wrong) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = AppTheme.error;
      labelBg = AppTheme.error;
      labelFg = Colors.white;
      textColor = AppTheme.error;
      trailingIcon = Icons.cancel_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[index],
                style: TextStyle(
                  color: labelFg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: textColor, size: 20),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1);
  }
}