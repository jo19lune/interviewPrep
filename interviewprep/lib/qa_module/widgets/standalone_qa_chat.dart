import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../providers/qa_module_provider.dart';
import '../widgets/qa_input_field.dart';
import '../widgets/qa_message_list.dart';
import '../widgets/qa_module_container.dart';

class StandaloneQAChat extends StatelessWidget {
  const StandaloneQAChat({
    super.key,
    required this.state,
    required this.scrollController,
  });
  final QAModuleState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => Column(
    children: [
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                      Text(
                        '${state.answeredCount}/${state.totalQuestions}',
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
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
      Expanded(
        child: QaModuleContainer(
          title: 'Session Q&A',
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) =>
                      QaMessageList(messages: [state.messages[index]]),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'L\'IA formule la prochaine question...',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
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
