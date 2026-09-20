import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/activity_history.dart';
import '../services/activity_history_service.dart';

final activityHistoryServiceProvider = Provider<ActivityHistoryService>((ref) {
  return ActivityHistoryService();
});

final activityHistoryProvider = FutureProvider<List<ActivityHistory>>((ref) {
  return ref.watch(activityHistoryServiceProvider).list();
});
