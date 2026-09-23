part of 'simulation_provider.dart';

mixin SimulationAudioOperations on Notifier<SimulationState> {
  SimulationService get service;
  AudioRecorder get audioRecorder;
  FlutterTts get flutterTts;
  void reset();
  void _upsertRecruiterMessage(String text);

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception(
        'Permission microphone refusée. Veuillez l\'accorder dans les paramètres.',
      );
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await audioRecorder.start(const RecordConfig(), path: path);
    state = state.copyWith(isRecording: true);
  }

  Future<void> stopAndSendRecording() async {
    final path = await audioRecorder.stop();
    if (path == null || path.isEmpty) {
      state = state.copyWith(isRecording: false);
      return;
    }
    state = state.copyWith(isRecording: false, isLoading: true);
    try {
      if (state.sessionId == null) {
        throw Exception('Aucune session active pour envoyer la réponse audio.');
      }
      final response = await service.submitAudioAnswer(state.sessionId!, path);
      final count =
          (response['answer_count'] as num?)?.toInt() ?? state.answerCount + 1;
      final next =
          response['next_question'] as String? ??
          'Félicitations, simulation terminée !';
      state = state.copyWith(answerCount: count);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: _generateId(),
            text: '🎤 Réponse vocale transmise',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
      );
      await _streamRecruiterResponse(next);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false);
      rethrow;
    } finally {
      final file = File(path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
  }

  Future<void> finish() async {
    if (state.sessionId == null) return;
    flutterTts.stop();
    state = state.copyWith(isLoading: true);
    try {
      final response = await service.finishSimulation(state.sessionId!);
      state = state.copyWith(
        feedback: Feedback(
          id: response.id,
          sessionId: response.sessionId,
          scoreGlobal: response.scoreGlobal,
          pointsForts: response.pointsForts,
          ameliorations: response.ameliorations,
          recommandations: response.recommandations,
          genereLe: response.genereLe ?? DateTime.now(),
        ),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> cancel() async {
    if (state.sessionId == null) {
      reset();
      return;
    }
    flutterTts.stop();
    state = state.copyWith(isLoading: true);
    try {
      await service.cancelSimulation(state.sessionId!);
      state = SimulationState();
    } catch (error) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> _streamRecruiterResponse(String fallback) async {
    var text = '';
    try {
      await for (final token in service.streamAIResponse(state.sessionId!)) {
        text += token;
        _upsertRecruiterMessage(text);
      }
    } catch (_) {
      text = '';
    }
    if (text.trim().isEmpty) _upsertRecruiterMessage(fallback);
  }
}
