// lib/core/providers.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'api_client.dart';
import 'session_store.dart';
import 'auth_repo.dart';
import '../services/doctors_service.dart';

/// Global navigator key (optional)
final navKeyProvider =
    Provider<GlobalKey<NavigatorState>>((_) => GlobalKey<NavigatorState>());

/// Secure session storage
final sessionStoreProvider = Provider<SessionStore>((_) => SessionStore());

/// Tiny session "atom" that anyone can read/write without Riverpod State* types
final sessionAtomProvider =
    Provider<ValueNotifier<Session?>>((_) => ValueNotifier<Session?>(null));

/// Internal auth events stream (used to refresh router / UI)
final _authEventsControllerProvider =
    Provider<StreamController<void>>((_) => StreamController<void>.broadcast());

/// Public stream of auth events
final authEventsProvider =
    Provider<Stream<void>>((ref) => ref.read(_authEventsControllerProvider).stream);

/// Api client with global 401 handler -> clears token + session + storage, emits event
final apiClientProvider = Provider<ApiClient>((ref) {
  final sessionStore = ref.read(sessionStoreProvider);
  final sessionAtom = ref.read(sessionAtomProvider);
  final events = ref.read(_authEventsControllerProvider);

  late final ApiClient client;

  void on401() {
    // 1) stop sending stale token immediately
    client.setToken(null);

    // 2) clear in-memory session
    sessionAtom.value = null;

    // 3) clear secure storage (fire-and-forget)
    unawaited(sessionStore.clear());

    // 4) notify listeners (e.g., router / UI)
    events.add(null);
  }

  client = ApiClient(onUnauthorized: on401);
  return client;
});

/// Auth repo
final authRepoProvider = Provider<AuthRepo>(
  (ref) => AuthRepo(ref.read(apiClientProvider), ref.read(sessionStoreProvider)),
);

/// --- helpers ---------------------------------------------------------------

/// Try to read a token from Session regardless of its field name.
/// Supports: `token` or `accessToken`. Returns null if neither exists.
String? _extractToken(Session? s) {
  if (s == null) return null;
  try {
    final dyn = s as dynamic;
    final t1 = dyn.token as String?;
    if (t1 != null && t1.isNotEmpty) return t1;
  } catch (_) {}
  try {
    final dyn = s as dynamic;
    final t2 = dyn.accessToken as String?;
    if (t2 != null && t2.isNotEmpty) return t2;
  } catch (_) {}
  return null;
}

/// Simple auth controller that mutates sessionAtom, keeps ApiClient token in sync,
/// and emits auth events for UI/router to react.
class AuthController {
  final Ref ref;
  final AuthRepo repo;

  AuthController(this.ref, this.repo);

  ValueNotifier<Session?> get _atom => ref.read(sessionAtomProvider);
  StreamController<void> get _events => ref.read(_authEventsControllerProvider);
  ApiClient get _api => ref.read(apiClientProvider);
  SessionStore get _store => ref.read(sessionStoreProvider);

  Session? get session => _atom.value;

  Future<void> hydrate() async {
    try {
      final s = await repo.hydrate();
      _atom.value = s;

      // Set token on ApiClient from the hydrated session (works for token/accessToken)
      _api.setToken(_extractToken(s));

      _events.add(null);
    } catch (e) {
      // Handle hydration errors gracefully
      _atom.value = null;
      _api.setToken(null);
      // Don't emit event on error to avoid unnecessary UI updates
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final s = await repo.login(email, password);
      _atom.value = s;

      // Set token on ApiClient from the new session
      _api.setToken(_extractToken(s));

      _events.add(null);
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      // Backend often sends { message: '...' }
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.response?.statusCode == 401) {
        return 'Invalid email or password';
      }
      return 'Unable to sign in. Please try again.';
    } catch (_) {
      return 'Unable to sign in. Please try again.';
    }
  }

  Future<String?> register(String name, String email, String password, String role) async {
    try {
      await repo.register(name, email, password, role);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    try {
      await repo.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      _atom.value = null;
      _api.setToken(null);
      _events.add(null);
    }
  }

  void forceLogout() {
    try {
      repo.logout();
    } catch (e) {
      // Ignore errors in force logout
    } finally {
      _atom.value = null;
      _api.setToken(null);
      _events.add(null);
    }
  }
}

/// Provide the controller
final authControllerProvider =
    Provider<AuthController>((ref) => AuthController(ref, ref.read(authRepoProvider)));

final doctorsServiceProvider = Provider<DoctorsService>((ref) {
  return DoctorsService(ref.read(apiClientProvider).dio);
});
