import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/statistics_content.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedPeriod = '7D';
  static const _periods = ['7D', '1M', '3M', 'All'];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 1,
      title: const Text(
        'Insights',
        style: TextStyle(
          color: AppTheme.primaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
        onPressed: () => context.go('/dashboard'),
      ),
    ),
    body: StatisticsContent(
      selectedPeriod: _selectedPeriod,
      periods: _periods,
      onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
    ),
  );
}
