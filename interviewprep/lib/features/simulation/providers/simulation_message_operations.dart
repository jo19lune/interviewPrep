part of 'simulation_provider.dart';

mixin SimulationMessageOperations on Notifier<SimulationState> {
  FlutterTts get flutterTts;

  void _upsertRecruiterMessage(
    String text, {
    double? clarity,
    String? sentiment,
    String? tip,
    Map<String, dynamic>? analysis,
  }) {
    final messages = [...state.messages];
    final message = ChatMessage(
      id: messages.isNotEmpty && !messages.last.isUser
          ? messages.last.id
          : _generateId(),
      text: text,
      isUser: false,
      timestamp: messages.isNotEmpty && !messages.last.isUser
          ? messages.last.timestamp
          : DateTime.now(),
      scorePartiel: clarity,
      sentiment: sentiment,
      coachingTip: tip,
      analysis: analysis,
    );
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = message;
    } else {
      messages.add(message);
    }
    state = state.copyWith(messages: messages);
    unawaited(flutterTts.speak(text));
  }
}
