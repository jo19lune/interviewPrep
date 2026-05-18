import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:9000'; // Utiliser 10.0.2.2 pour l'émulateur Android, ou localhost / l'IP locale pour web/iOS
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Récupérer le token depuis le stockage sécurisé
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options); // Continuer la requête
        },
        onError: (DioException e, handler) async {
          // Gérer l'erreur 401 (Non autorisé)
          if (e.response?.statusCode == 401) {
            // Logique de déconnexion ou rafraîchissement du token
            await _storage.delete(key: 'jwt_token');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
