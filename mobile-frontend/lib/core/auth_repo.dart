import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'session_store.dart';

class AuthRepo {
  final ApiClient api;
  final SessionStore store;

  AuthRepo(this.api, this.store);

  Future<Session> login(String email, String password) async {
    try {
      final res =
          await api.dio.post('/auth/login', data: {'email': email, 'password': password});

      if (res.data == null) {
        throw Exception('Invalid response from server');
      }

      final token = res.data['token'] ?? res.data['access_token'];
      if (token == null || token.toString().isEmpty) {
        throw Exception('No token received from server');
      }

      final userData = res.data['user'];
      if (userData == null || userData is! Map) {
        throw Exception('Invalid user data received');
      }

      final user = Map<String, dynamic>.from(userData as Map);
      final s = Session(token.toString(), user);

      api.setToken(s.token);

      try {
        await store.write(s);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AuthRepo] Failed to write session to storage: $e');
        }
      }

      return s;
    } catch (e) {
      // Let DioException (and others) bubble up so higher layers
      // can show friendly error messages based on status/message.
      rethrow;
    }
  }

  Future<Session?> hydrate() async {
    try {
      final s = await store.read();
      if (s != null) {
        try {
          api.setToken(s.token);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[AuthRepo] Failed to set token during hydrate: $e');
          }
        }
      }
      return s;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepo] Hydrate failed: $e');
      }
      return null;
    }
  }

  Future<void> logout() async {
    try {
      api.setToken(null);
    } catch (_) {}

    try {
      await store.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepo] Failed to clear session storage: $e');
      }
    }
  }

  Future<void> register(
      String name, String email, String password, String role) async {
    try {
      await api.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
}