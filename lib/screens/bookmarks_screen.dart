import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Bookmarks', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('bookmarks')
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
                  Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No bookmarks yet!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap the bookmark icon during a quiz to save questions.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _BookmarkCard(
                data: data,
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

class _BookmarkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _BookmarkCard({required this.data, required this.docId, required this.userId});

  void _delete(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(data['options'] ?? []);
    final correctIndex = data['correctIndex'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(data['text'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              IconButton(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.bookmark_remove_rounded),
                color: AppTheme.primary,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...options.asMap().entries.map((e) {
            final isCorrect = e.key == correctIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCorrect ? AppTheme.success.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrect ? AppTheme.success.withOpacity(0.4) : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  if (isCorrect)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 14),
                  if (isCorrect) const SizedBox(width: 6),
                  Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCorrect ? AppTheme.success : Colors.grey[700],
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text('Category: ${data['category'] ?? ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }
}