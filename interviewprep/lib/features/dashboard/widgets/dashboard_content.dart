import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/session_models.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_hero.dart';
import 'dashboard_sections.dart';
import 'dashboard_sessions.dart';

class DashboardContent extends ConsumerWidget {
  const DashboardContent({required this.onSettings, super.key});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final progress = ref.watch(userProgressProvider);
    final history = ref.watch(sessionHistoryProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _appBar(context, profile),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProgressProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(sessionHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              profile.when(
                data: (user) => DashboardHero(user: user, progress: progress),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => DashboardHero(
                  user: User(
                    id: '',
                    courriel: '',
                    estActif: true,
                    creeLe: DateTime(1970),
                  ),
                  progress: progress,
                ),
              ),
              const SizedBox(height: 32),
              progress.when(
                data: (value) => DashboardRecommendations(progress: value),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 32),
              history.when(
                data: (sessions) => DashboardSessions(sessions: sessions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur historique: $e')),
              ),
              const SizedBox(height: 32),
              const DashboardMotivation(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, AsyncValue<User> profile) =>
      AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryContainer,
                backgroundImage: profile.value?.avatarUrl == null
                    ? null
                    : NetworkImage(profile.value!.avatarUrl!),
                child: profile.value?.avatarUrl == null
                    ? Text(
                        profile.value?.initials ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'InterviewPrep',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppTheme.primaryContainer),
            onPressed: () => context.go('/dashboard/statistics'),
            tooltip: 'Insights',
          ),
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.primaryContainer),
            onPressed: () => context.push('/activities/history'),
            tooltip: 'Historique des activités',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.primaryContainer),
            onPressed: onSettings,
            tooltip: 'Paramètres',
          ),
          const SizedBox(width: 8),
        ],
      );
}
