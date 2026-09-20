import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/qa_module_provider.dart';
import '../widgets/standalone_qa_chat.dart';
import '../widgets/standalone_qa_feedback.dart';
import '../widgets/standalone_qa_intro.dart';
import '../widgets/standalone_qa_exit_dialog.dart';

class StandaloneQAScreen extends ConsumerStatefulWidget {
  const StandaloneQAScreen({
    super.key,
    this.exerciseId,
    this.exerciseTitle,
    this.domaine,
    this.difficulte,
  });
  final String? exerciseId, exerciseTitle, domaine, difficulte;
  @override
  ConsumerState<StandaloneQAScreen> createState() => _StandaloneQAScreenState();
}

class _StandaloneQAScreenState extends ConsumerState<StandaloneQAScreen> {
  final _scrollController = ScrollController();
  final _subjectController = TextEditingController();
  int _questionCount = 10;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(qaModuleProvider.notifier);
      final state = ref.read(qaModuleProvider);
      if (widget.exerciseId != null && state.exerciseId != widget.exerciseId) {
        notifier.configure(
          exerciseId: widget.exerciseId!,
          exerciseTitle: widget.exerciseTitle ?? 'Exercice',
          domaine: widget.domaine,
          difficulte: widget.difficulte,
          subject: state.subject,
          totalQuestions: state.totalQuestions,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _startSession() async {
    setState(() => _isStarting = true);
    try {
      ref
          .read(qaModuleProvider.notifier)
          .configure(
            exerciseId: widget.exerciseId ?? 'default',
            exerciseTitle: widget.exerciseTitle ?? 'Session Q&A',
            domaine: widget.domaine,
            difficulte: widget.difficulte,
            subject: _subjectController.text.trim().isEmpty
                ? null
                : _subjectController.text.trim(),
            totalQuestions: _questionCount,
          );
      await ref.read(qaModuleProvider.notifier).startSession();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur au démarrage: $e')));
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qaModuleProvider);
    if (state.messages.isNotEmpty) _scrollToBottom();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exerciseTitle ?? 'Module Q&A',
              style: const TextStyle(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (state.messages.isNotEmpty && state.feedback == null)
              Text(
                '${state.answeredCount}/${state.totalQuestions} questions',
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () {
            if (state.messages.isNotEmpty && state.feedback == null) {
              showStandaloneQAExitDialog(context, () {
                ref.read(qaModuleProvider.notifier).reset();
                Navigator.of(context).pop();
              });
            } else {
              ref.read(qaModuleProvider.notifier).reset();
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (state.messages.isNotEmpty && state.feedback == null)
            TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () async =>
                        ref.read(qaModuleProvider.notifier).endSession(),
              icon: const Icon(
                Icons.stop_circle_outlined,
                size: 18,
                color: AppTheme.error,
              ),
              label: const Text(
                'Terminer',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: state.feedback != null
          ? StandaloneQAFeedback(
              feedback: state.feedback!,
              onRestart: () {
                ref.read(qaModuleProvider.notifier).reset();
                setState(() {});
              },
              onDashboard: () {
                ref.read(qaModuleProvider.notifier).reset();
                context.go('/dashboard');
              },
            )
          : state.messages.isEmpty
          ? StandaloneQAIntro(
              title: widget.exerciseTitle,
              domaine: widget.domaine,
              difficulte: widget.difficulte,
              subjectController: _subjectController,
              questionCount: _questionCount,
              isStarting: _isStarting,
              onQuestionCountChanged: (value) =>
                  setState(() => _questionCount = value),
              onStart: _startSession,
            )
          : StandaloneQAChat(state: state, scrollController: _scrollController),
    );
  }
}
