import 'dart:async';
import 'dart:math' as math;

import 'package:circular_progress_with_logo/circular_progress_with_logo.dart';
import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:flutter/material.dart';

import '../core/network/backend_warmup.dart';
import 'theme/app_theme.dart';

class StartupSplashGate extends StatefulWidget {
  const StartupSplashGate({required this.child, super.key});

  final Widget child;

  @override
  State<StartupSplashGate> createState() => _StartupSplashGateState();
}

class _StartupSplashGateState extends State<StartupSplashGate> {
  static const _minimumDuration = Duration(seconds: 3);

  late final Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _waitForStartup();
  }

  Future<void> _waitForStartup() async {
    await Future.wait<void>([
      Future<void>.delayed(_minimumDuration),
      BackendWarmupService().waitUntilReady(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.child;
        }
        return const _StartupSplash();
      },
    );
  }
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash();

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  late final FlameSplashController _flameController;

  @override
  void initState() {
    super.initState();
    final durations = <Duration>[
      const Duration(seconds: 6),
      const Duration(seconds: 3),
      const Duration(seconds: 2),
      const Duration(milliseconds: 1500),
      const Duration(seconds: 1),
    ];
    _controllers = [
      for (final duration in durations)
        AnimationController(vsync: this, duration: duration)..repeat(),
    ];
    _animations = [
      for (final controller in _controllers)
        Tween<double>(begin: -math.pi, end: math.pi).animate(controller),
    ];
    _flameController = FlameSplashController(
      fadeInDuration: const Duration(milliseconds: 750),
      waitDuration: const Duration(milliseconds: 1500),
      fadeOutDuration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppTheme.primaryContainer),
        AnimatedBuilder(
          animation: Listenable.merge(_controllers),
          builder: (context, child) {
            return CustomPaint(
              painter: _StartupArcsPainter(
                angles: [for (final animation in _animations) animation.value],
              ),
            );
          },
        ),
        Center(
          child: CustomLoader(
            size: 112,
            color: AppTheme.secondaryContainer,
            strokeWidth: 4,
            style: LoaderStyle.spinningArcs,
            logo: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icon/logo.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        FlameSplashScreen(
          controller: _flameController,
          theme: FlameSplashTheme(
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            logoBuilder: (_) => const SizedBox.shrink(),
          ),
          onFinish: (_) {},
        ),
      ],
    );
  }
}

class _StartupArcsPainter extends CustomPainter {
  const _StartupArcsPainter({required this.angles});

  final List<double> angles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height) * 0.28;
    final paint = Paint()
      ..color = AppTheme.secondaryContainer.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < angles.length; index++) {
      final radius = maxRadius * (1 + index * 0.13);
      paint.strokeWidth = 2.5 - index * 0.2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angles[index],
        1.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StartupArcsPainter oldDelegate) {
    return oldDelegate.angles.length != angles.length ||
        oldDelegate.angles.asMap().entries.any(
          (entry) => entry.value != angles[entry.key],
        );
  }
}
