import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import '../services/simulation_service.dart';
import '../../../core/models/exercise.dart';
import '../../qa/models/chat_message.dart';

part 'simulation_audio_operations.dart';
part 'simulation_message_operations.dart';
part 'simulation_provider_definitions.dart';

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

class SimulationNotifier extends Notifier<SimulationState> {
  late final SimulationService _service;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  SimulationState build() {
    _service = ref.watch(simulationServiceProvider);
    _initTts();
    return SimulationState();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void dispose() {
    _flutterTts.stop();
    _audioRecorder.dispose();
  }

  void reset() {
    _flutterTts.stop();
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
        id: _generateId(),
        text:
            response['first_question'] ??
            "Bienvenue dans cette simulation d'entretien. Commençons par votre parcours. Pouvez-vous vous présenter ?",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        sessionId: response['session_id'],
        exerciseTitle: response['exercise_title'] ?? 'Simulation',
        messages: [firstMsg],
        isLoading: false,
        subject: subject,
        questionCount: questionCount,
        answerCount: 0,
      );

      // Lecture vocale automatique de la première question
      unawaited(_flutterTts.speak(firstMsg.text));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendAnswer(String answerText) async {
    if (answerText.trim().isEmpty || state.sessionId == null) return;

    // Interrompre la synthèse vocale en cours
    await _flutterTts.stop();

    final userMsg = ChatMessage(
      id: _generateId(),
      text: answerText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final response = await _service.submitAnswer(
        state.sessionId!,
        answerText,
      );

      final answerCount =
          (response['answer_count'] as num?)?.toInt() ?? state.answerCount + 1;
      final nextQ =
          response['next_question'] as String? ??
          'Félicitations, simulation terminée !';

      state = state.copyWith(answerCount: answerCount);

      var streamedText = '';
      var hasRecruiterMessage = false;
      try {
        await for (final token in _service.streamAIResponse(state.sessionId!)) {
          streamedText += token;
          hasRecruiterMessage = true;
          _upsertRecruiterMessage(streamedText);
        }
      } catch (_) {
        streamedText = '';
      }

      if (!hasRecruiterMessage || streamedText.trim().isEmpty) {
        _upsertRecruiterMessage(nextQ);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}
