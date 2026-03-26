// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Avatar + Name ─────────────────────────────────────────────
            _ProfileHero(user: user)
                .animate()
                .fadeIn(delay: 100.ms)
                .scale(curve: Curves.easeOutBack),

            const SizedBox(height: 28),

            // ── Stats Cards ───────────────────────────────────────────────
            _buildStatCards(context, user),

            const SizedBox(height: 24),

            // ── Accuracy Meter ─────────────────────────────────────────────
            _AccuracyMeter(accuracy: user.accuracy)
                .animate(delay: 400.ms)
                .fadeIn()
                .slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Achievement Badges ─────────────────────────────────────────
            _AchievementBadges(user: user)
                .animate(delay: 500.ms)
                .fadeIn()
                .slideY(begin: 0.1),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, dynamic user) {
    return Row(
      children: [
        _StatCard(
          label: 'Quizzes Taken',
          value: '${user.quizzesTaken}',
          icon: Icons.quiz_rounded,
          color: AppTheme.primary,
          delay: 200,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label: 'Total Points',
          value: '${user.totalPoints}',
          icon: Icons.stars_rounded,
          color: const Color(0xFFF57C00),
          delay: 280,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label: 'Accuracy',
          value: '${user.accuracy.toStringAsFixed(1)}%',
          icon: Icons.track_changes_rounded,
          color: AppTheme.success,
          delay: 360,
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final dynamic user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppTheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                _getRank(user.totalPoints),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRank(int points) {
    if (points >= 5000) return 'Grandmaster';
    if (points >= 2000) return 'Expert';
    if (points >= 1000) return 'Intermediate';
    if (points >= 500) return 'Apprentice';
    return 'Novice';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: color,
                )),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1),
    );
  }
}

class _AccuracyMeter extends StatelessWidget {
  final double accuracy;
  const _AccuracyMeter({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final color = accuracy >= 70
        ? AppTheme.success
        : accuracy >= 50
            ? const Color(0xFFF57C00)
            : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Accuracy',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: accuracy / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _getMessage(accuracy),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getMessage(double acc) {
    if (acc >= 90) return 'Phenomenal! You\'re in the top tier 🌟';
    if (acc >= 80) return 'Excellent performance! Keep it up 🎯';
    if (acc >= 70) return 'Good work! Room to grow 💪';
    if (acc >= 50) return 'Halfway there, keep practising 📚';
    return 'Don\'t give up! Every attempt counts ❤️';
  }
}

class _AchievementBadges extends StatelessWidget {
  final dynamic user;
  const _AchievementBadges({required this.user});

  @override
  Widget build(BuildContext context) {
    final badges = _getBadges(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Achievements',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badges.map((b) => _BadgeTile(badge: b)).toList(),
        ),
      ],
    );
  }

  List<_Badge> _getBadges(dynamic user) {
    return [
      _Badge(
        label: 'First Quiz',
        icon: Icons.star_rounded,
        color: const Color(0xFFF57C00),
        unlocked: user.quizzesTaken >= 1,
      ),
      _Badge(
        label: '5 Quizzes',
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.error,
        unlocked: user.quizzesTaken >= 5,
      ),
      _Badge(
        label: '10 Quizzes',
        icon: Icons.military_tech_rounded,
        color: AppTheme.primary,
        unlocked: user.quizzesTaken >= 10,
      ),
      _Badge(
        label: '500 Points',
        icon: Icons.monetization_on_rounded,
        color: const Color(0xFF43A047),
        unlocked: user.totalPoints >= 500,
      ),
      _Badge(
        label: '1000 Points',
        icon: Icons.diamond_rounded,
        color: const Color(0xFF1E88E5),
        unlocked: user.totalPoints >= 1000,
      ),
      _Badge(
        label: '80% Accuracy',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF9C27B0),
        unlocked: user.accuracy >= 80,
      ),
    ];
  }
}

class _Badge {
  final String label;
  final IconData icon;
  final Color color;
  final bool unlocked;
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.unlocked ? badge.color : Colors.grey[400]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(badge.unlocked ? 0.4 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            badge.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (!badge.unlocked) ...[
            const SizedBox(width: 4),
            Icon(Icons.lock_rounded, color: color, size: 12),
          ],
        ],
      ),
    );
  }
}
