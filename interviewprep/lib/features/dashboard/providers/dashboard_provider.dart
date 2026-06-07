import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import '../../../core/models/exercise.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final userProgressProvider = FutureProvider<UserProgress>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return await dashboardService.getUserProgress();
});

final sessionHistoryProvider = FutureProvider<List<Session>>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return await dashboardService.getSessionHistory();
});

final detailedStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return await dashboardService.getDetailedStats();
});
