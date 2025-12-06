/// Internal logging service for technical errors
/// These logs should NOT be shown to users
class LogsService {
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    // Log to console for development
    print('🔴 [ERROR] $message');
    if (error != null) {
      print('   Error: $error');
    }
    if (stackTrace != null) {
      print('   StackTrace: $stackTrace');
    }
    
    // TODO: In production, you might want to send to crash reporting service
    // e.g., Firebase Crashlytics, Sentry, etc.
  }

  static void logWarning(String message) {
    print('⚠️ [WARNING] $message');
  }

  static void logInfo(String message) {
    print('ℹ️ [INFO] $message');
  }

  static void logAuthError(String context, Object error, {StackTrace? stackTrace}) {
    logError('Auth Error in $context', error: error, stackTrace: stackTrace);
  }
}

