import 'package:flutter/foundation.dart';

/// App Logger with multiple colors for different log levels
/// 
/// Usage:
/// ```dart
/// AppLogger.debug('Debug message');
/// AppLogger.info('Info message');
/// AppLogger.success('Success message');
/// AppLogger.warning('Warning message');
/// AppLogger.error('Error message');
/// ```
class AppLogger {
  // ANSI Color Codes
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  
  // Colors
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';
  
  // Log Level Colors
  static const String _debugColor = _cyan;
  static const String _infoColor = _blue;
  static const String _successColor = _green;
  static const String _warningColor = _yellow;
  static const String _errorColor = _red;
  
  // Enable/Disable logging (useful for production)
  static bool _enabled = true;
  static LogLevel _minLogLevel = LogLevel.debug;
  
  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  /// Set minimum log level (logs below this level will be ignored)
  static void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }
  
  /// Get current timestamp
  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
           '${now.minute.toString().padLeft(2, '0')}:'
           '${now.second.toString().padLeft(2, '0')}.'
           '${now.millisecond.toString().padLeft(3, '0')}';
  }
  
  /// Format log message with colors
  static String _formatLog(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled || level.index < _minLogLevel.index) {
      return '';
    }
    
    final timestamp = _getTimestamp();
    final levelName = level.name.toUpperCase().padRight(7);
    final color = _getColorForLevel(level);
    final emoji = _getEmojiForLevel(level);
    
    var logMessage = '$color$_bold[$levelName]$_reset $color$timestamp$_reset';
    
    if (tag != null) {
      logMessage += ' $color$_bold[$tag]$_reset';
    }
    
    logMessage += ' $color$emoji $message$_reset';
    
    if (error != null) {
      logMessage += '\n$color$_bold Error: $_reset$error';
    }
    
    if (stackTrace != null) {
      logMessage += '\n$color$_bold StackTrace:$_reset\n$stackTrace';
    }
    
    return logMessage;
  }
  
  /// Get color for log level
  static String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _debugColor;
      case LogLevel.info:
        return _infoColor;
      case LogLevel.success:
        return _successColor;
      case LogLevel.warning:
        return _warningColor;
      case LogLevel.error:
        return _errorColor;
    }
  }
  
  /// Get emoji for log level
  static String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
  
  /// Debug log (cyan color)
  static void debug(String message, {String? tag}) {
    final formatted = _formatLog(LogLevel.debug, message, tag: tag);
    if (formatted.isNotEmpty) {
      debugPrint(formatted);
    }
  }
  
  /// Info log (blue color)
  static void info(String message, {String? tag}) {
    final formatted = _formatLog(LogLevel.info, message, tag: tag);
    if (formatted.isNotEmpty) {
      debugPrint(formatted);
    }
  }
  
  /// Success log (green color)
  static void success(String message, {String? tag}) {
    final formatted = _formatLog(LogLevel.success, message, tag: tag);
    if (formatted.isNotEmpty) {
      debugPrint(formatted);
    }
  }
  
  /// Warning log (yellow color)
  static void warning(String message, {String? tag}) {
    final formatted = _formatLog(LogLevel.warning, message, tag: tag);
    if (formatted.isNotEmpty) {
      debugPrint(formatted);
    }
  }
  
  /// Error log (red color)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formatted = _formatLog(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
    if (formatted.isNotEmpty) {
      debugPrint(formatted);
    }
  }
  
  /// Log API request
  static void apiRequest(String method, String url, {Map<String, dynamic>? body}) {
    var message = '$method $url';
    if (body != null) {
      message += '\n${_cyan}Request Body:$_reset $body';
    }
    debug(message, tag: 'API');
  }
  
  /// Log API response
  static void apiResponse(String method, String url, int statusCode, {dynamic data}) {
    final responseColor = statusCode >= 200 && statusCode < 300 ? _successColor : _errorColor;
    var message = '$method $url - Status: $statusCode';
    if (data != null) {
      message += '\n$responseColor Response:$_reset $data';
    }
    if (statusCode >= 200 && statusCode < 300) {
      success(message, tag: 'API');
    } else {
      error(message, tag: 'API');
    }
  }
  
  /// Log navigation
  static void navigation(String from, String to) {
    info('Navigating from $from to $to', tag: 'NAVIGATION');
  }
  
  /// Log user action
  static void userAction(String action, {Map<String, dynamic>? data}) {
    var message = action;
    if (data != null) {
      message += ' - Data: $data';
    }
    info(message, tag: 'USER_ACTION');
  }
}

/// Log levels enum
enum LogLevel {
  debug,
  info,
  success,
  warning,
  error,
}

