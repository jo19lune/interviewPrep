import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

import '../../../core/network/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/auth/me');
  return response.data;
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is null/void
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.login(email, password);
    });
    
    // If state has an error, we throw it to allow UI to catch it
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
