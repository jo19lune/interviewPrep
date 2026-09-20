import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/qa_module_provider.dart';

class QAModuleAnswerNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
  void clear() => state = '';
}

final qaModuleAnswerProvider = NotifierProvider<QAModuleAnswerNotifier, String>(() {
  return QAModuleAnswerNotifier();
});

final qaModuleCanSendProvider = Provider<bool>((ref) {
  final answer = ref.watch(qaModuleAnswerProvider);
  final isLoading = ref.watch(qaModuleProvider).isLoading;
  return answer.trim().isNotEmpty && !isLoading;
});
