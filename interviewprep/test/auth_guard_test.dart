import 'package:flutter_test/flutter_test.dart';
import 'package:interviewprep/app/router/app_auth_guard.dart';
import 'package:interviewprep/app/router/app_routes.dart';

void main() {
  late AuthStateNotifier notifier;

  setUp(() => notifier = AuthStateNotifier());

  test('applies no redirect before startup settles', () {
    for (final path in [AppRoutes.login, AppRoutes.dashboard, AppRoutes.about]) {
      expect(resolveAuthRedirect(notifier, path), isNull);
    }
  });

  test('blocks private routes when there is no session', () {
    notifier.setSession(hasSession: false, startupSettled: true);

    expect(resolveAuthRedirect(notifier, AppRoutes.dashboard), AppRoutes.login);
    expect(resolveAuthRedirect(notifier, AppRoutes.profile), AppRoutes.login);
    expect(resolveAuthRedirect(notifier, AppRoutes.about), AppRoutes.login);
    expect(
      resolveAuthRedirect(notifier, AppRoutes.simulationHistory),
      AppRoutes.login,
    );
  });

  test('keeps public routes reachable without a session', () {
    notifier.setSession(hasSession: false, startupSettled: true);

    for (final path in publicPaths) {
      expect(resolveAuthRedirect(notifier, path), isNull);
    }
  });

  test('allows private routes once a session exists', () {
    notifier.setSession(hasSession: true, startupSettled: true);

    expect(resolveAuthRedirect(notifier, AppRoutes.dashboard), isNull);
    expect(resolveAuthRedirect(notifier, AppRoutes.about), isNull);
  });

  test('bounces an authenticated user away from public routes', () {
    notifier.setSession(hasSession: true, startupSettled: true);

    expect(
      resolveAuthRedirect(notifier, AppRoutes.login),
      AppRoutes.dashboard,
    );
    expect(
      resolveAuthRedirect(notifier, AppRoutes.verifyOtp),
      AppRoutes.dashboard,
    );
  });

  test('notifies listeners only when the session state actually changes', () {
    var notifications = 0;
    notifier.addListener(() => notifications++);

    notifier.setSession(hasSession: true, startupSettled: true);
    notifier.setSession(hasSession: true, startupSettled: true);
    expect(notifications, 1);

    notifier.setSession(hasSession: false, startupSettled: true);
    expect(notifications, 2);
  });
}
