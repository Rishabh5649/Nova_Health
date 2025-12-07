import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class Session {
final String token; final Map<String, dynamic> user; // expects id,email,role
const Session(this.token, this.user);
Map<String, dynamic> toJson() => {'token': token, 'user': user};
static Session fromJson(Map<String, dynamic> j) {
  try {
    final token = j['token'] as String?;
    final user = j['user'] as Map<String, dynamic>?;
    
    if (token == null || token.isEmpty) {
      throw Exception('Token is missing or empty');
    }
    if (user == null) {
      throw Exception('User data is missing');
    }
    
    return Session(token, user);
  } catch (e) {
    throw Exception('Failed to parse session: $e');
  }
}
}


class SessionStore {
static const _key = 'session_v1';
final _sec = const FlutterSecureStorage();


Future<Session?> read() async {
try {
  final raw = await _sec.read(key: _key);
  if (raw == null) return null;
  
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      if (kDebugMode) {
        debugPrint('[SessionStore] Invalid session format');
      }
      // Clear invalid data
      await _sec.delete(key: _key);
      return null;
    }
    
    return Session.fromJson(decoded);
  } catch (e) {
    // Clear corrupted data
    if (kDebugMode) {
      debugPrint('[SessionStore] Failed to decode session: $e');
    }
    try {
      await _sec.delete(key: _key);
    } catch (_) {
      // Ignore delete errors
    }
    return null;
  }
} catch (e) {
  // Return null on any error
  if (kDebugMode) {
    debugPrint('[SessionStore] Read failed: $e');
  }
  return null;
}
}


Future<void> write(Session s) async {
try {
  final json = jsonEncode(s.toJson());
  await _sec.write(key: _key, value: json);
} catch (e) {
  if (kDebugMode) {
    debugPrint('[SessionStore] Write failed: $e');
  }
  // Re-throw to let caller handle
  rethrow;
}
}

Future<void> clear() async {
try {
  await _sec.delete(key: _key);
} catch (e) {
  // Log but don't throw - clearing is best effort
  if (kDebugMode) {
    debugPrint('[SessionStore] Clear failed: $e');
  }
}
}
}