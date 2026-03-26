import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../models/quiz_history.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Quiz History', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('history')
            .orderBy('playedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No quiz history yet!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Play a quiz to see your results here.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final history = QuizHistory.fromMap(
                  docs[index].data() as Map<String, dynamic>);
              return _HistoryCard(
                history: history,
                docId: docs[index].id,
                userId: user.id,
              ).animate(delay: Duration(milliseconds: index * 60))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final QuizHistory history;
  final String docId;
  final String userId;

  const _HistoryCard({
    required this.history,
    required this.docId,
    required this.userId,
  });

  Color get _color {
    if (history.percentage >= 80) return AppTheme.success;
    if (history.percentage >= 60) return const Color(0xFFF57C00);
    return AppTheme.error;
  }

  void _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Record?'),
        content: const Text('This history entry will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('history')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = '${history.playedAt.day}/${history.playedAt.month}/${history.playedAt.year}';
    final time = '${history.playedAt.hour.toString().padLeft(2, '0')}:${history.playedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _color, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '${history.percentage.toStringAsFixed(0)}%',
              style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${history.correctAnswers}/${history.totalQuestions} correct  •  ${history.pointsEarned} pts',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text('$date at $time',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.grey[400],
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}