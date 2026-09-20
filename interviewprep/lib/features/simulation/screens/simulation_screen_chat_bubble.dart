part of 'simulation_screen.dart';

extension _ChatBubble on _SimulationScreenState {
  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.secondaryContainer,
              child: Icon(
                Icons.psychology,
                size: 20,
                color: AppTheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryContainer
                    : Colors.white,
                border: message.isUser
                    ? null
                    : Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : AppTheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundColor: AppTheme.outline,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
