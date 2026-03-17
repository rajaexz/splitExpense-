# Go Router Setup

This project uses `go_router` for navigation management.

## Usage

### Basic Navigation

```dart
import 'package:go_router/go_router.dart';

// Navigate to a route
context.go('/login');

// Push a route (keeps previous route in stack)
context.push('/register');

// Pop current route
context.pop();
```

### Using Navigation Helper Extension

```dart
import 'package:jobcrak/core/routing/navigation_helper.dart';

// Easy navigation methods
context.goToLogin();
context.goToHome();
context.goToOnboarding();
```

### Using Route Names

```dart
import 'package:jobcrak/core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';

context.go(AppRoutes.login);
context.push(AppRoutes.register);
```

## Available Routes

- `/` - Splash Screen
- `/onboarding` - Onboarding Pages
- `/login` - Login Page
- `/register` - Register Page
- `/home` - Home Screen (Placeholder)

## Adding New Routes

1. Add route constant in `lib/core/constants/app_routes.dart`:
```dart
static const String newRoute = '/new-route';
```

2. Add route in `lib/core/routing/app_router.dart`:
```dart
GoRoute(
  path: AppRoutes.newRoute,
  name: 'new-route',
  builder: (context, state) => const NewPage(),
),
```

3. Use navigation:
```dart
context.go(AppRoutes.newRoute);
```

## Route Parameters

For routes with parameters:

```dart
GoRoute(
  path: '/job/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return JobDetailsPage(jobId: id);
  },
),

// Navigate with parameter
context.go('/job/123');
```

## Query Parameters

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'];
    return SearchPage(query: query);
  },
),

// Navigate with query
context.go('/search?q=flutter');
```

## Navigation Guards

You can add redirect logic in `app_router.dart`:

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = // check auth state
    final isGoingToLogin = state.matchedLocation == '/login';
    
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }
    return null; // No redirect
  },
  routes: [...],
)
```

