import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/google_auth_models.dart';
import '../services/google_auth_service.dart';
import '../services/otp_service.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
);

final googleAuthProvider =
    AsyncNotifierProvider<GoogleAuthNotifier, GoogleLoginResult?>(
      GoogleAuthNotifier.new,
    );

class GoogleAuthNotifier extends AsyncNotifier<GoogleLoginResult?> {
  @override
  Future<GoogleLoginResult?> build() async => null;

  Future<GoogleLoginResult> login() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(googleAuthServiceProvider).login(),
    );
    state = result;
    return result.requireValue;
  }
}

final otpServiceProvider = Provider<OtpService>((ref) => OtpService());

final otpVerificationProvider =
    AsyncNotifierProvider<OtpVerificationNotifier, void>(
      OtpVerificationNotifier.new,
    );

class OtpVerificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> verify(String email, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(otpServiceProvider).verifyLoginCode(email, code),
    );
    if (state.hasError) throw state.error!;
  }
}
