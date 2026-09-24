import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/qa_service.dart';
import '../models/chat_message.dart';

final qaServiceProvider = Provider<QAService>((ref) {
  return QAService();
});

class QAModuleState {
  final String? sessionId;
  final String? exerciseId;
  final String? exerciseTitle;
  final String? domaine;
  final String? difficulte;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isRecording;
  final QAFeedback? feedback;
  final String? lastLiveCoachingTip;
  final double? lastClarityScore;
  final String? lastSentiment;
  final String? subject;
  final int totalQuestions;
  final int answeredCount;
  final QASessionConfig? sessionConfig;

  const QAModuleState({
    this.sessionId,
    this.exerciseId,
    this.exerciseTitle,
    this.domaine,
    this.difficulte,
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.feedback,
    this.lastLiveCoachingTip,
    this.lastClarityScore,
    this.lastSentiment,
    this.subject,
    this.totalQuestions = 10,
    this.answeredCount = 0,
    this.sessionConfig,
  });

  QAModuleState copyWith({
    String? sessionId,
    String? exerciseId,
    String? exerciseTitle,
    String? domaine,
    String? difficulte,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isRecording,
    QAFeedback? feedback,
    String? lastLiveCoachingTip,
    double? lastClarityScore,
    String? lastSentiment,
    String? subject,
    int? totalQuestions,
    int? answeredCount,
    QASessionConfig? sessionConfig,
    bool clearFeedback = false,
    bool clearConfig = false,
  }) {
    return QAModuleState(
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseTitle: exerciseTitle ?? this.exerciseTitle,
      domaine: domaine ?? this.domaine,
      difficulte: difficulte ?? this.difficulte,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      lastLiveCoachingTip: lastLiveCoachingTip ?? this.lastLiveCoachingTip,
      lastClarityScore: lastClarityScore ?? this.lastClarityScore,
      lastSentiment: lastSentiment ?? this.lastSentiment,
      subject: subject ?? this.subject,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredCount: answeredCount ?? this.answeredCount,
      sessionConfig: clearConfig ? null : (sessionConfig ?? this.sessionConfig),
    );
  }
}

class QAModuleNotifier extends Notifier<QAModuleState> {
  late final QAService _service;

  @override
  QAModuleState build() {
    _service = ref.watch(qaServiceProvider);
    return const QAModuleState();
  }

  void reset() {
    state = const QAModuleState();
  }

  void configure({
    required String exerciseId,
    required String exerciseTitle,
    String? domaine,
    String? difficulte,
    String? subject,
    int totalQuestions = 10,
  }) {
    state = state.copyWith(
      exerciseId: exerciseId,
      exerciseTitle: exerciseTitle,
      domaine: domaine,
      difficulte: difficulte,
      subject: subject,
      totalQuestions: totalQuestions,
      answeredCount: 0,
      clearFeedback: true,
      messages: const [],
      sessionConfig: QASessionConfig(
        subject: subject,
        totalQuestions: totalQuestions,
      ),
    );
  }

  Future<void> startSession() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, messages: const []);
    try {
      final firstQuestion = await _service.generateNextQuestion(
        previousResponses: const [],
        domaine: state.domaine ?? 'COMPORTEMENTAL',
        difficulte: state.difficulte ?? 'INTERMEDIAIRE',
        sujet: state.subject,
        questionIndex: 0,
        totalQuestions: state.totalQuestions,
      );

      final botMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_bot',
        text: firstQuestion,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(messages: [botMessage], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendAnswer(String answerText) async {
    if (answerText.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      text: answerText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final previousResponses = state.messages
          .where((m) => m.isUser)
          .map((m) => m.text)
          .toList();

      final nextQuestion = await _service.generateNextQuestion(
        previousResponses: previousResponses,
        domaine: state.domaine ?? 'COMPORTEMENTAL',
        difficulte: state.difficulte ?? 'INTERMEDIAIRE',
        sujet: state.subject,
        questionIndex: state.answeredCount,
        totalQuestions: state.totalQuestions,
      );

      final botMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_bot',
        text: nextQuestion,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        answeredCount: state.answeredCount + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> endSession() async {
    if (state.messages.isEmpty) return;
    try {
      final feedback = await _service.generateFeedback(
        responses: state.messages,
        contexte: state.subject ?? 'Simulation d\'entretien',
        sujet: state.exerciseTitle,
      );
      state = state.copyWith(feedback: feedback, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final qaModuleProvider = NotifierProvider<QAModuleNotifier, QAModuleState>(() {
  return QAModuleNotifier();
});
