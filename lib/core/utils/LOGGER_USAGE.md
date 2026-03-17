# App Logger Usage Guide

## Overview
`AppLogger` is a comprehensive logging utility with colored output for different log levels. It helps you debug and monitor your app with beautiful, color-coded logs.

## Features
- ✅ Multiple log levels (Debug, Info, Success, Warning, Error)
- ✅ Color-coded output for easy identification
- ✅ Timestamp for each log
- ✅ Tag support for filtering logs
- ✅ Emoji indicators for visual clarity
- ✅ Special methods for API, Navigation, and User Actions

## Log Levels

### 1. Debug (Cyan 🐛)
Use for detailed debugging information.

```dart
AppLogger.debug('User clicked button', tag: 'UI');
AppLogger.debug('State updated: $state', tag: 'STATE');
```

### 2. Info (Blue ℹ️)
Use for general informational messages.

```dart
AppLogger.info('App started successfully', tag: 'APP');
AppLogger.info('Loading user data...', tag: 'DATA');
```

### 3. Success (Green ✅)
Use for successful operations.

```dart
AppLogger.success('User logged in successfully', tag: 'AUTH');
AppLogger.success('Data saved to database', tag: 'DB');
```

### 4. Warning (Yellow ⚠️)
Use for warnings that don't stop execution.

```dart
AppLogger.warning('Network request took longer than expected', tag: 'NETWORK');
AppLogger.warning('Cache is getting full', tag: 'CACHE');
```

### 5. Error (Red ❌)
Use for errors and exceptions.

```dart
AppLogger.error('Failed to load data', tag: 'API', error: exception);
AppLogger.error('Login failed', tag: 'AUTH', error: error, stackTrace: stackTrace);
```

## Special Methods

### API Logging

```dart
// Log API Request
AppLogger.apiRequest('POST', '/api/login', body: {'email': 'user@example.com'});

// Log API Response
AppLogger.apiResponse('POST', '/api/login', 200, data: responseData);
AppLogger.apiResponse('POST', '/api/login', 401); // Error response
```

### Navigation Logging

```dart
AppLogger.navigation('/login', '/home');
```

### User Action Logging

```dart
AppLogger.userAction('Button clicked', data: {'button_id': 'login_btn'});
AppLogger.userAction('Form submitted', data: {'form_type': 'registration'});
```

## Configuration

### Enable/Disable Logging

```dart
// Disable all logs (useful for production)
AppLogger.setEnabled(false);

// Enable logs
AppLogger.setEnabled(true);
```

### Set Minimum Log Level

```dart
// Only show warnings and errors
AppLogger.setMinLogLevel(LogLevel.warning);

// Only show errors
AppLogger.setMinLogLevel(LogLevel.error);

// Show all logs (default)
AppLogger.setMinLogLevel(LogLevel.debug);
```

## Examples

### In Cubits/Blocs

```dart
class AuthCubit extends Cubit<AuthState> {
  Future<void> login(String email, String password) async {
    AppLogger.info('Login attempt started', tag: 'AUTH');
    emit(AuthLoading());
    
    try {
      final user = await authRepository.login(email, password);
      AppLogger.success('Login successful: ${user.email}', tag: 'AUTH');
      emit(AuthSuccess(user));
    } catch (e, stackTrace) {
      AppLogger.error('Login failed', tag: 'AUTH', error: e, stackTrace: stackTrace);
      emit(AuthError(e.toString()));
    }
  }
}
```

### In Repositories

```dart
class AuthRepository {
  Future<User> login(String email, String password) async {
    AppLogger.apiRequest('POST', '/auth/login', body: {'email': email});
    
    try {
      final response = await dio.post('/auth/login', data: {'email': email, 'password': password});
      AppLogger.apiResponse('POST', '/auth/login', response.statusCode, data: response.data);
      return User.fromJson(response.data);
    } catch (e) {
      AppLogger.apiResponse('POST', '/auth/login', 500);
      rethrow;
    }
  }
}
```

### In Widgets

```dart
class LoginPage extends StatelessWidget {
  void _handleLogin() {
    AppLogger.userAction('Login button clicked', tag: 'UI');
    // ... login logic
  }
  
  @override
  Widget build(BuildContext context) {
    AppLogger.debug('LoginPage built', tag: 'UI');
    // ... widget code
  }
}
```

## Production Setup

For production, you might want to disable debug logs:

```dart
void main() {
  // In production, only show warnings and errors
  if (kReleaseMode) {
    AppLogger.setMinLogLevel(LogLevel.warning);
  }
  
  runApp(MyApp());
}
```

## Color Reference

- 🐛 **Debug**: Cyan - For detailed debugging
- ℹ️ **Info**: Blue - For general information
- ✅ **Success**: Green - For successful operations
- ⚠️ **Warning**: Yellow - For warnings
- ❌ **Error**: Red - For errors

## Tips

1. **Use tags** to filter logs by feature/module
2. **Include context** in your log messages
3. **Use appropriate log levels** - don't log everything as error
4. **Disable debug logs in production** for better performance
5. **Use special methods** (apiRequest, navigation, etc.) for consistency

