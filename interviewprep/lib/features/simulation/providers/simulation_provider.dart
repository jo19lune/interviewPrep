import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/simulation_service.dart';
import '../../../core/models/exercise.dart';

final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

final availableModelsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(simulationServiceProvider);
  return service.getAvailableModels();
});

final selectedModelProvider = StateProvider<String?>((ref) => null);

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? scorePartiel;
  final String? sentiment;
  final String? coachingTip;
  final Map<String, dynamic>? analysis;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.scorePartiel,
    this.sentiment,
    this.coachingTip,
    this.analysis,
  });
}

class SimulationState {
  final String? sessionId;
  final String? exerciseTitle;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isRecording;
  final Feedback? feedback;
  final String? lastLiveCoachingTip;
  final double? lastClarityScore;
  final String? lastSentiment;
  final String? subject;
  final int questionCount;
  final int answerCount;

  SimulationState({
    this.sessionId,
    this.exerciseTitle,
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.feedback,
    this.lastLiveCoachingTip,
    this.lastClarityScore,
    this.lastSentiment,
    this.subject,
    this.questionCount = 10,
    this.answerCount = 0,
  });

  SimulationState copyWith({
    String? sessionId,
    String? exerciseTitle,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isRecording,
    Feedback? feedback,
    String? lastLiveCoachingTip,
    double? lastClarityScore,
    String? lastSentiment,
    String? subject,
    int? questionCount,
    int? answerCount,
    bool clearFeedback = false,
  }) {
    return SimulationState(
      sessionId: sessionId ?? this.sessionId,
      exerciseTitle: exerciseTitle ?? this.exerciseTitle,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      lastLiveCoachingTip: lastLiveCoachingTip ?? this.lastLiveCoachingTip,
      lastClarityScore: lastClarityScore ?? this.lastClarityScore,
      lastSentiment: lastSentiment ?? this.lastSentiment,
      subject: subject ?? this.subject,
      questionCount: questionCount ?? this.questionCount,
      answerCount: answerCount ?? this.answerCount,
    );
  }
}

class SimulationNotifier extends StateNotifier<SimulationState> {
  final SimulationService _service;

  SimulationNotifier(this._service) : super(SimulationState());

  void reset() {
    state = SimulationState();
  }

  Future<void> start(
    String exerciseId, {
    String? subject,
    int questionCount = 10,
    String? model,
  }) async {
    state = state.copyWith(isLoading: true, clearFeedback: true, messages: []);
    try {
      final response = await _service.startSimulation(
        exerciseId,
        subject: subject,
        questionCount: questionCount,
        model: model,
      );
      
      final firstMsg = ChatMessage(
        text: "Bienvenue dans cette simulation d'entretien. Commençons par votre parcours. Pouvez-vous vous présenter ?",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        sessionId: response.id,
        exerciseTitle: 'Simulation', // We don't have it in SessionResponse directly
        messages: [firstMsg],
        isLoading: false,
        subject: subject,
        questionCount: questionCount,
        answerCount: 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendAnswer(String answerText) async {
    if (answerText.trim().isEmpty || state.sessionId == null) return;
    
    final userMsg = ChatMessage(
      text: answerText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final response = await _service.submitAnswer(state.sessionId!, answerText);
      
      // Mettre à jour les indicateurs en direct et afficher la question suivante
      final clarity = (response['clarity_score'] as num?)?.toDouble() ?? 80.0;
      final sentiment = response['sentiment'] as String? ?? 'Confident';
      final tip = response['coaching_tip'] as String? ?? '';
      final answerCount = (response['answer_count'] as num?)?.toInt() ?? state.answerCount + 1;
      final analysis = response['analysis'] is Map<String, dynamic>
          ? response['analysis'] as Map<String, dynamic>
          : null;
      final nextQ = response['next_question'] as String? ?? 'Félicitations, simulation terminée !';

      state = state.copyWith(
        lastClarityScore: clarity,
        lastSentiment: sentiment,
        lastLiveCoachingTip: tip,
        answerCount: answerCount,
      );

      var streamedText = '';
      var hasRecruiterMessage = false;
      try {
        await for (final token in _service.streamAIResponse(state.sessionId!)) {
          streamedText += token;
          hasRecruiterMessage = true;
          _upsertRecruiterMessage(
            streamedText,
            clarity: clarity,
            sentiment: sentiment,
            tip: tip,
            analysis: analysis,
          );
        }
      } catch (_) {
        streamedText = '';
      }

      if (!hasRecruiterMessage || streamedText.trim().isEmpty) {
        _upsertRecruiterMessage(
          nextQ,
          clarity: clarity,
          sentiment: sentiment,
          tip: tip,
          analysis: analysis,
        );
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void toggleRecording() {
    state = state.copyWith(isRecording: !state.isRecording);
  }

  Future<void> finish() async {
    if (state.sessionId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _service.finishSimulation(state.sessionId!);
      
      final feedback = Feedback(
        id: response.id,
        sessionId: response.sessionId,
        scoreGlobal: response.scoreGlobal,
        pointsForts: response.pointsForts,
        ameliorations: response.ameliorations,
        recommandations: response.recommandations,
        genereLe: response.genereLe ?? DateTime.now(),
      );

      state = state.copyWith(
        feedback: feedback,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> cancel() async {
    if (state.sessionId == null) {
      reset();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      await _service.cancelSimulation(state.sessionId!);
      state = SimulationState();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void _upsertRecruiterMessage(
    String text, {
    required double clarity,
    required String sentiment,
    required String tip,
    Map<String, dynamic>? analysis,
  }) {
    final messages = [...state.messages];
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = ChatMessage(
        text: text,
        isUser: false,
        timestamp: messages.last.timestamp,
        scorePartiel: clarity,
        sentiment: sentiment,
        coachingTip: tip,
        analysis: analysis,
      );
    } else {
      messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          scorePartiel: clarity,
          sentiment: sentiment,
          coachingTip: tip,
          analysis: analysis,
        ),
      );
    }
    state = state.copyWith(messages: messages);
  }
}

final simulationProvider = StateNotifierProvider<SimulationNotifier, SimulationState>((ref) {
  final service = ref.watch(simulationServiceProvider);
  return SimulationNotifier(service);
});
