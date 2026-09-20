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
import '../../../qa_module/models/chat_message.dart';

final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

final availableModelsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(simulationServiceProvider);
  return service.getAvailableModels();
});

class SelectedModelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? model) => state = model;
}

final selectedModelProvider = NotifierProvider<SelectedModelNotifier, String?>(() {
  return SelectedModelNotifier();
});

String _generateId() => 'sim_msg_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

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
        text: response['first_question'] ?? "Bienvenue dans cette simulation d'entretien. Commençons par votre parcours. Pouvez-vous vous présenter ?",
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
      final response = await _service.submitAnswer(state.sessionId!, answerText);
      
      final answerCount = (response['answer_count'] as num?)?.toInt() ?? state.answerCount + 1;
      final nextQ = response['next_question'] as String? ?? 'Félicitations, simulation terminée !';

      state = state.copyWith(
        answerCount: answerCount,
      );

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

  /// Démarre l'enregistrement audio après avoir vérifié la permission microphone.
  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      state = state.copyWith(isRecording: true);
    } else {
      throw Exception("Permission microphone refusée. Veuillez l'accorder dans les paramètres.");
    }
  }

  /// Arrête l'enregistrement, envoie le fichier audio au backend, puis supprime le fichier local.
  Future<void> stopAndSendRecording() async {
    final path = await _audioRecorder.stop();
    if (path == null || path.isEmpty) {
      state = state.copyWith(isRecording: false);
      return;
    }

    state = state.copyWith(isRecording: false, isLoading: true);

    try {
      if (state.sessionId == null) {
        throw Exception("Aucune session active pour envoyer la réponse audio.");
      }
      final response = await _service.submitAudioAnswer(state.sessionId!, path);

      final answerCount = (response['answer_count'] as num?)?.toInt() ?? state.answerCount + 1;
      final nextQ = response['next_question'] as String? ?? 'Félicitations, simulation terminée !';

      state = state.copyWith(
        answerCount: answerCount,
      );

      // Ajouter le message utilisateur avec indication "audio"
      final userMsg = ChatMessage(
        id: _generateId(),
        text: "🎤 Réponse vocale transmise",
        isUser: true,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, userMsg]);

      // Streamer la réponse du recruteur
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
    } finally {
      // Suppression systématique du fichier audio temporaire
      if (File(path).existsSync()) {
        try {
          File(path).deleteSync();
        } catch (_) {
          // Le fichier a déjà été nettoyé ou est inaccessible
        }
      }
    }
  }

  Future<void> finish() async {
    if (state.sessionId == null) return;
    _flutterTts.stop();
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
    _flutterTts.stop();
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
    double? clarity,
    String? sentiment,
    String? tip,
    Map<String, dynamic>? analysis,
  }) {
    final messages = [...state.messages];
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = ChatMessage(
        id: messages.last.id,
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
          id: _generateId(),
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

    // Lecture vocale automatique pour les messages du recruteur
    unawaited(_flutterTts.speak(text));
  }
}

final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
