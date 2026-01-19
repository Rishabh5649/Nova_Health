import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'env.dart';

typedef OnUnauthorized = void Function();

class ApiClient {
  final Dio dio;
  String? _token;
  final OnUnauthorized onUnauthorized;

  ApiClient({required this.onUnauthorized})
      : dio = Dio(
          BaseOptions(
            baseUrl: Env.baseUrl, // e.g. http://localhost:3000
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Request/response logging for dev - completely suppress logs to reduce terminal noise
    // Only enable if you need to debug API issues
    if (kDebugMode && false) { // Set to true only when debugging API
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: false, // Suppress error logs too
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Attach bearer only when token is present and non-empty.
          final t = _token?.trim();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (e, handler) {
          // Centralized 401 handling
          final status = e.response?.statusCode;
          if (status == 401) {
            try {
              onUnauthorized();
            } catch (err) {
              // Log but don't break the chain
              if (kDebugMode) {
                debugPrint('[API] Error in onUnauthorized callback: $err');
              }
            }
          }
          // Suppress error logging to reduce terminal noise
          // Only log critical errors if needed
          if (kDebugMode && false && status != 401 && status != null && status! >= 500) {
            debugPrint('[API] Server error: ${e.requestOptions.uri} - Status: $status');
          }
          handler.next(e);
        },
      ),
    );
  }

  /// Set or clear the bearer token.
  void setToken(String? token) {
    final t = token?.trim();
    _token = (t == null || t.isEmpty) ? null : t;
  }

  /// Convenience: whether a token is currently set.
  bool get isAuthenticated => _token != null;

  /// Explicitly clear token (same as setToken(null)).
  void clearToken() => setToken(null);
}
