import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/qa_module_provider.dart';
import '../providers/qa_ui_providers.dart';

class QaInputField extends ConsumerStatefulWidget {
  const QaInputField({super.key});

  @override
  ConsumerState<QaInputField> createState() => _QaInputFieldState();
}

class _QaInputFieldState extends ConsumerState<QaInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(qaModuleAnswerProvider.notifier).state = text;
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(qaModuleProvider).isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isLoading,
              decoration: const InputDecoration(
                hintText: 'Tapez votre réponse...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isLoading ? null : _handleSend,
            icon: const Icon(Icons.send_rounded),
            color: isLoading ? AppTheme.onSurfaceVariant : AppTheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}
