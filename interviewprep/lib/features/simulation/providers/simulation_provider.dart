import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/simulation_service.dart';
import '../../../core/models/exercise.dart';

final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? scorePartiel;
  final String? sentiment;
  final String? coachingTip;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.scorePartiel,
    this.sentiment,
    this.coachingTip,
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
    );
  }
}

class SimulationNotifier extends StateNotifier<SimulationState> {
  final SimulationService _service;

  SimulationNotifier(this._service) : super(SimulationState());

  void reset() {
    state = SimulationState();
  }

  Future<void> start(String exerciseId) async {
    state = state.copyWith(isLoading: true, clearFeedback: true, messages: []);
    try {
      final response = await _service.startSimulation(exerciseId);
      
      final firstMsg = ChatMessage(
        text: response.firstQuestion ?? "Bienvenue dans cette simulation d'entretien. Commençons par votre parcours. Pouvez-vous vous présenter ?",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        sessionId: response.sessionId,
        exerciseTitle: response.exerciseTitle,
        messages: [firstMsg],
        isLoading: false,
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
      final nextQ = response['next_question'] as String? ?? 'Félicitations, simulation terminée !';

      state = state.copyWith(
        lastClarityScore: clarity,
        lastSentiment: sentiment,
        lastLiveCoachingTip: tip,
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
      
      final fbData = response['feedback'] as Map<String, dynamic>;
      final feedback = Feedback(
        id: fbData['id'] as String,
        sessionId: fbData['session_id'] as String,
        scoreGlobal: (fbData['score_global'] as num).toDouble(),
        pointsForts: fbData['points_forts'] as List<dynamic>?,
        ameliorations: fbData['ameliorations'] as List<dynamic>?,
        recommandations: (fbData['recommandations'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        genereLe: DateTime.parse(fbData['genere_le'] as String),
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

  void _upsertRecruiterMessage(
    String text, {
    required double clarity,
    required String sentiment,
    required String tip,
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
