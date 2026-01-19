import 'package:flutter/foundation.dart';

class Env {
  // Use localhost for Web, otherwise use Android emulator loopback or LAN IP
  static const baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
}