import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/forgot_password_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final forgotPasswordServiceProvider = Provider<ForgotPasswordService>((ref) {
  return ForgotPasswordService();
});

final forgotPasswordProvider = AsyncNotifierProvider<ForgotPasswordNotifier, void>(() {
  return ForgotPasswordNotifier();
});

class ForgotPasswordNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> requestCode(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(forgotPasswordServiceProvider);
      await service.requestResetCode(email);
    });
    if (state.hasError) throw state.error!;
  }

  Future<bool> verifyCode(String email, String code) async {
    final service = ref.read(forgotPasswordServiceProvider);
    return service.verifyResetCode(email, code);
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(forgotPasswordServiceProvider);
      await service.resetPassword(email, code, newPassword);
    });
    if (state.hasError) throw state.error!;
  }
}

final userProfileProvider = FutureProvider<User>((ref) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/auth/me');
  return User.fromJson(response.data);
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

final startupLoadingProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.login(email, password);
    });
    
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.register(fullName, email, password);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
    });
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
    });
    
    if (state.hasError) {
      throw state.error!;
    }
  }
}
