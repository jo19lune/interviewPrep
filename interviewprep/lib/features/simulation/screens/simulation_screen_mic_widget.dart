/// Bouton microphone interactif avec animation de pulse.
/// Utilise l'enregistrement audio rÃ©el et l'envoie au backend pour transcription.
class _MicButton extends ConsumerStatefulWidget {
  const _MicButton();

  @override
  ConsumerState<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends ConsumerState<_MicButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final notifier = ref.read(simulationProvider.notifier);
    if (_isRecording) {
      try {
        await notifier.stopAndSendRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mic_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Transcription terminÃ©e'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.primaryContainer,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de transcription: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
      if (mounted) setState(() => _isRecording = false);
    } else {
      try {
        await notifier.startRecording();
        setState(() => _isRecording = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Enregistrement en cours...'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.secondaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecording ? _pulseAnimation.value : 1.0,
          child: IconButton(
            icon: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: _isRecording ? AppTheme.error : AppTheme.outline,
            ),
            tooltip: _isRecording
                ? 'ArrÃªter l\'enregistrement'
                : 'Enregistrer une rÃ©ponse vocale',
            style: IconButton.styleFrom(
              backgroundColor: _isRecording
                  ? AppTheme.error.withAlpha((0.12 * 255).round())
                  : Colors.transparent,
            ),
            onPressed: _toggleRecording,
          ),
        );
      },
    );
  }
}
