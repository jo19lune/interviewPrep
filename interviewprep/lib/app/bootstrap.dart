import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'startup_splash.dart';

void bootstrap() {
  runApp(
    const ProviderScope(child: StartupSplashGate(child: InterviewPrepApp())),
  );
}
