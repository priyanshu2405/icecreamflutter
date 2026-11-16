/// ---------------------------------------------------------------------------
/// BACKEND ADDRESS - the ONLY place the server URL lives.
///
/// Going live? Change [_defaultBaseUrl] below to your production API address
/// (it must end in /api/v1 and use https://), or pass it at build time and
/// leave this file alone:
///
///   flutter build apk --release --dart-define=API_BASE_URL=https://app.yourdomain.com/api/v1
///   flutter build ipa --release --dart-define=API_BASE_URL=https://app.yourdomain.com/api/v1
///
/// Local development defaults:
///   Android emulator -> http://10.0.2.2:8000/api/v1   (10.0.2.2 = your computer)
///   iOS simulator    -> http://127.0.0.1:8000/api/v1
///   Real phone       -> http://<your computer's LAN IP>:8000/api/v1
/// ---------------------------------------------------------------------------
class ApiConfig {
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  /// How long to wait for the server before showing "can't reach the server".
  static const Duration timeout = Duration(seconds: 20);
}
