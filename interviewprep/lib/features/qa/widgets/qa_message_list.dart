import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/qa_module_provider.dart';
import 'qa_chat_bubble.dart';

class QaMessageList extends ConsumerWidget {
  final List<dynamic> messages;

  const QaMessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qaModuleProvider);
    final isLoading = state.isLoading;

    return Expanded(
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return QaChatBubble(
                messageId: msg.id,
                text: msg.text,
                isUser: msg.isUser,
                timestamp: msg.timestamp,
                scorePartiel: msg.scorePartiel,
                sentiment: msg.sentiment,
                coachingTip: msg.coachingTip,
                analysis: msg.analysis,
              );
            },
          ),
          if (isLoading)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
