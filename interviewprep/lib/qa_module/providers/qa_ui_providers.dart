import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/qa_module_provider.dart';

final qaModuleAnswerProvider = StateProvider<String>((ref) => '');

final qaModuleCanSendProvider = Provider<bool>((ref) {
  final answer = ref.watch(qaModuleAnswerProvider);
  final isLoading = ref.watch(qaModuleProvider).isLoading;
  return answer.trim().isNotEmpty && !isLoading;
});
