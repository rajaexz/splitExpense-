# JobCrak - Professional Job Search App

A professional Flutter mobile application built with MVVM architecture using Cubit for state management.

## Architecture

This project follows **MVVM (Model-View-ViewModel)** pattern with **Cubit** for state management:

```
lib/
├── core/
│   ├── constants/          # App constants (colors, strings, fonts, dimensions)
│   ├── theme/              # Theme configuration (light & dark mode)
│   ├── widgets/            # Reusable UI components
│   ├── utils/              # Utilities (ThemeCubit, etc.)
│   ├── di/                 # Dependency Injection setup
│   └── base/               # Base classes (BaseState, BaseCubit)
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── models/     # Data models
│       │   ├── repositories/ # Repository implementations
│       │   └── datasources/  # Remote & Local data sources
│       ├── domain/
│       │   ├── entities/   # Business entities
│       │   ├── repositories/ # Repository interfaces
│       │   └── usecases/   # Business logic use cases
│       └── presentation/
│           ├── cubit/      # State management (Cubits)
│           ├── pages/      # UI Pages/Screens
│           └── widgets/    # Feature-specific widgets
└── main.dart               # App entry point
```

## Features

- ✅ MVVM Architecture with Cubit
- ✅ Dark Mode Support
- ✅ Professional UI Components
- ✅ Dependency Injection (GetIt)
- ✅ Theme Management
- ✅ Constants Management (Colors, Strings, Fonts, Dimensions)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

### Constants

- **AppColors**: All color constants with light/dark mode support
- **AppStrings**: All string constants
- **AppFonts**: Font family and size constants
- **AppDimensions**: Padding, margin, radius, and size constants

### Theme

- **AppTheme**: Light and dark theme configurations
- **ThemeCubit**: Manages theme state (light/dark mode toggle)

### Widgets

Reusable components:
- `AppButton`: Custom button with loading state
- `AppTextField`: Custom text input field
- `AppCard`: Custom card widget
- `AppLoading`: Loading indicator
- `AppErrorWidget`: Error display widget
- `AppEmptyWidget`: Empty state widget
- `ThemeToggleButton`: Theme switcher button

## Adding a New Feature

1. Create feature folder structure:
```
features/
└── auth/
    ├── data/
    ├── domain/
    └── presentation/
```

2. Create Cubit for state management
3. Create Repository interface in domain
4. Implement Repository in data
5. Create UI pages in presentation
6. Register dependencies in `injection_container.dart`

## Dark Mode

Dark mode is fully supported and can be toggled using `ThemeToggleButton` or programmatically:

```dart
context.read<ThemeCubit>().toggleTheme();
```

## Dependencies

- `flutter_bloc`: State management
- `get_it`: Dependency injection
- `go_router`: Navigation
- `shared_preferences`: Local storage
- `dio`: HTTP client
- `equatable`: Value equality

## License

This project is licensed under the MIT License.

