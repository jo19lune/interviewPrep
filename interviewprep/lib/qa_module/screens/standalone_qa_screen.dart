import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/qa_module_provider.dart';
import '../widgets/qa_message_list.dart';
import '../widgets/qa_input_field.dart';
import '../widgets/qa_module_container.dart';
import '../services/qa_service.dart';

class StandaloneQAScreen extends ConsumerStatefulWidget {
  const StandaloneQAScreen({
    super.key,
    this.exerciseId,
    this.exerciseTitle,
    this.domaine,
    this.difficulte,
  });

  final String? exerciseId;
  final String? exerciseTitle;
  final String? domaine;
  final String? difficulte;

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
    // Configurer l'exercice si des paramètres sont fournis
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startSession() async {
    setState(() => _isStarting = true);
    try {
      // Reconfigurer avec les options choisies sur l'écran d'intro
      ref.read(qaModuleProvider.notifier).configure(
        exerciseId: widget.exerciseId ?? 'default',
        exerciseTitle: widget.exerciseTitle ?? 'Session Q&A',
        domaine: widget.domaine,
        difficulte: widget.difficulte,
        subject: _subjectController.text.trim().isNotEmpty
            ? _subjectController.text.trim()
            : null,
        totalQuestions: _questionCount,
      );
      await ref.read(qaModuleProvider.notifier).startSession();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur au démarrage: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaModuleProvider);
    final messages = qaState.messages;

    // Scroll automatique à chaque nouveau message
    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.exerciseTitle ?? 'Module Q&A',
              style: const TextStyle(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            if (messages.isNotEmpty && qaState.feedback == null)
              Text(
                '${qaState.answeredCount}/${qaState.totalQuestions} questions',
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.normal),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () {
            if (messages.isNotEmpty && qaState.feedback == null) {
              _confirmExit(context);
            } else {
              ref.read(qaModuleProvider.notifier).reset();
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (messages.isNotEmpty && qaState.feedback == null)
            TextButton.icon(
              onPressed: qaState.isLoading
                  ? null
                  : () async {
                      await ref.read(qaModuleProvider.notifier).endSession();
                    },
              icon: const Icon(Icons.stop_circle_outlined, size: 18, color: AppTheme.error),
              label: const Text('Terminer',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: qaState.feedback != null
          ? _buildFeedbackScreen(context, qaState.feedback!)
          : messages.isEmpty
              ? _buildIntroScreen(context, qaState)
              : _buildChatScreen(context, qaState),
    );
  }

  // ─────────────── ÉCRAN D'INTRODUCTION ───────────────
  Widget _buildIntroScreen(BuildContext context, QAModuleState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero banner
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.secondaryContainer, AppTheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryContainer.withAlpha((0.15 * 255).round()),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_note, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text(
                  widget.exerciseTitle ?? 'Mode Questions-Réponses',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Entraînez-vous avec un assistant IA qui vous posera des questions et évaluera vos réponses en temps réel.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (widget.domaine != null)
                      _IntroChip(label: 'Domaine', value: widget.domaine!),
                    if (widget.difficulte != null)
                      _IntroChip(label: 'Difficulté', value: widget.difficulte!),
                    const _IntroChip(label: 'Mode', value: 'Écrit'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Paramètres de la session
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paramétrer la session',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Sujet ou domaine cible (optionnel)',
                    hintText: 'Ex: Flutter, data science, marketing...',
                    prefixIcon: const Icon(Icons.topic_outlined),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nombre de questions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primaryContainer,
                          ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_questionCount questions',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _questionCount.toDouble(),
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: '$_questionCount',
                  activeColor: AppTheme.secondaryColor,
                  onChanged: (value) =>
                      setState(() => _questionCount = value.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Infobox
          Container(
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.secondaryContainer.withAlpha((0.4 * 255).round())),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'L\'IA vous posera des questions adaptées, évaluera chaque réponse et générera un bilan détaillé à la fin de la session.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bouton Démarrer
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isStarting ? null : _startSession,
              icon: _isStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                _isStarting ? 'Démarrage...' : 'Démarrer la session',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── ÉCRAN DE CHAT ───────────────
  Widget _buildChatScreen(BuildContext context, QAModuleState state) {
    return Column(
      children: [
        // Barre de progression
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTheme.primaryContainer),
                        ),
                        Text(
                          '${state.answeredCount}/${state.totalQuestions}',
                          style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.totalQuestions == 0
                            ? 0
                            : (state.answeredCount / state.totalQuestions)
                                .clamp(0, 1)
                                .toDouble(),
                        backgroundColor: AppTheme.surfaceContainerLow,
                        color: AppTheme.secondaryColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: QaModuleContainer(
            title: 'Session Q&A',
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return QaMessageList(
                          messages: [state.messages[index]]);
                    },
                  ),
                ),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('L\'IA formule la prochaine question...',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: QaInputField(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── RAPPORT DE BILAN FINAL ───────────────
  Widget _buildFeedbackScreen(BuildContext context, QAFeedback feedback) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score global
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'VOTRE SCORE GLOBAL',
                  style: TextStyle(
                    color: AppTheme.primaryFixedVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: feedback.scoreGlobal / 100,
                        strokeWidth: 12,
                        backgroundColor:
                            Colors.white.withAlpha((0.15 * 255).round()),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.tertiaryFixed),
                      ),
                    ),
                    Text(
                      '${feedback.scoreGlobal.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  feedback.scoreGlobal >= 70
                      ? '🎉 Excellent travail !'
                      : feedback.scoreGlobal >= 50
                          ? '👍 Bonne progression'
                          : '💪 Continuez vos efforts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Points forts
          if (feedback.pointsForts.isNotEmpty) ...[
            _buildSectionTitle(
                context, Icons.check_circle, 'Points Forts', Colors.green),
            const SizedBox(height: 12),
            ...feedback.pointsForts.map((pf) => _buildDetailCard(
                  context,
                  title: pf.domaine,
                  description: pf.note,
                  borderColor: Colors.green,
                )),
            const SizedBox(height: 24),
          ],

          // Axes d'amélioration
          if (feedback.ameliorations.isNotEmpty) ...[
            _buildSectionTitle(
                context, Icons.trending_up, "Axes d'Amélioration", Colors.orange),
            const SizedBox(height: 12),
            ...feedback.ameliorations.map((am) => _buildDetailCard(
                  context,
                  title: am.domaine,
                  description: am.note,
                  borderColor: Colors.orange,
                )),
            const SizedBox(height: 24),
          ],

          // Recommandations
          if (feedback.recommandations.isNotEmpty) ...[
            _buildSectionTitle(context, Icons.assignment,
                "Recommandations de l'IA", AppTheme.secondaryColor),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: feedback.recommandations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star,
                            color: AppTheme.secondaryColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(qaModuleProvider.notifier).reset();
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recommencer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(qaModuleProvider.notifier).reset();
                    context.go('/dashboard');
                  },
                  icon: const Icon(Icons.dashboard, color: Colors.white),
                  label: const Text('Tableau de bord'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryContainer),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: const Text('Quitter la session ?'),
        content: const Text(
            'La session en cours sera abandonnée. Voulez-vous continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Continuer la session'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(qaModuleProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ──────────────── Widget auxiliaire pour les chips d'intro ────────────────
class _IntroChip extends StatelessWidget {
  final String label;
  final String value;

  const _IntroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha((0.3 * 255).round())),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
