import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // static const _devUrl = 'http://10.0.2.2:3000';
  static const _devUrl = 'https://tunely-backend-gf1k.onrender.com';
  static const _prodUrl = 'https://tunely-backend-gf1k.onrender.com';

  static String get backendUrl => kDebugMode ? _devUrl : _prodUrl;
}
