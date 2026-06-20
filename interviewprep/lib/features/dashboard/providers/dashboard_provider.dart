import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/session_models.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final userProgressProvider = FutureProvider<ProgressMeResponse>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return await dashboardService.getUserProgress();
});

final sessionHistoryProvider = FutureProvider<List<SessionResponse>>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return await dashboardService.getSessionHistory();
});

final detailedStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return await dashboardService.getDetailedStats();
});
