class AppConfig {
  // For mobile APK testing on same WiFi network:
  // static const bool isOnlineMode = false; // Set to false for local testing

  // For mobile APK to work from anywhere (production):
  static const bool isOnlineMode = true; // Set to true for online server

  // Local development server (same WiFi network)
  static const String localServerUrl = 'http://localhost:3000';

  // Online server (Railway deployment) - works from anywhere
  static const String onlineServerUrl =
      'https://afp-dental-app-production.up.railway.app';

  static String get serverUrl {
    return isOnlineMode ? onlineServerUrl : localServerUrl;
  }

  static String get apiBaseUrl {
    return '$serverUrl/api';
  }

  static String get healthCheckUrl {
    return '$serverUrl/health';
  }

  static const int connectionTimeoutSeconds = 10;

  // App Configuration
  static const String appName = 'Dental Case App';
  static const String appVersion = '1.0.0';

  // Timeout Configuration
  static const int requestTimeoutSeconds = 30;

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  // Debug Configuration
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
}
