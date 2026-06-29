import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: InterviewPrepApp(),
    ),
  );
}

class InterviewPrepApp extends ConsumerWidget {
  const InterviewPrepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupAsync = ref.watch(startupLoadingProvider);

    return MaterialApp.router(
      title: 'InterviewPrep',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: (startupAsync is AsyncLoading<void>)
                  ? const ColoredBox(
                      key: ValueKey('startup_loading'),
                      color: Color(0xCCFFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryContainer),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('startup_done')),
            ),
          ],
        );
      },
    );
  }
}
