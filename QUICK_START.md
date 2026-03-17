# Quick Start Guide

## Installation Steps

1. **Install Flutter Dependencies:**
```bash
flutter pub get
```

2. **Run the App:**
```bash
flutter run
```

## Project Structure Overview

```
lib/
├── core/                          # Core functionality
│   ├── constants/                # App constants
│   │   ├── app_colors.dart       # Color constants (light/dark mode)
│   │   ├── app_strings.dart      # String constants
│   │   ├── app_fonts.dart        # Font constants
│   │   ├── app_dimensions.dart   # Size/padding constants
│   │   └── app_routes.dart       # Route constants
│   ├── theme/                    # Theme configuration
│   │   └── app_theme.dart        # Light & dark themes
│   ├── widgets/                  # Reusable widgets
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_card.dart
│   │   ├── app_loading.dart
│   │   ├── app_error_widget.dart
│   │   ├── app_empty_widget.dart
│   │   └── theme_toggle_button.dart
│   ├── utils/                    # Utilities
│   │   ├── theme_cubit.dart      # Theme state management
│   │   └── theme_state.dart
│   ├── di/                       # Dependency Injection
│   │   └── injection_container.dart
│   └── base/                     # Base classes
│       ├── base_state.dart
│       └── base_cubit.dart
├── features/                     # Feature modules
│   └── auth/                     # Example: Auth feature
│       └── presentation/
│           ├── cubit/           # State management
│           │   ├── auth_cubit.dart
│           │   └── auth_state.dart
│           └── pages/           # UI pages
│               └── login_page_example.dart
└── main.dart                     # App entry point
```

## How to Use MVVM Pattern

### 1. Create a Feature

For each feature, create the following structure:

```
features/
└── [feature_name]/
    ├── data/
    │   ├── models/              # Data models
    │   ├── repositories/        # Repository implementations
    │   └── datasources/         # Remote & Local data sources
    ├── domain/
    │   ├── entities/            # Business entities
    │   ├── repositories/        # Repository interfaces
    │   └── usecases/            # Business logic
    └── presentation/
        ├── cubit/               # Cubit (ViewModel)
        │   ├── [feature]_cubit.dart
        │   └── [feature]_state.dart
        ├── pages/               # UI Pages (View)
        └── widgets/             # Feature-specific widgets
```

### 2. Create a Cubit (ViewModel)

```dart
// features/job/presentation/cubit/job_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'job_state.dart';

class JobCubit extends Cubit<JobState> {
  JobCubit() : super(JobInitial());
  
  void loadJobs() {
    emit(JobLoading());
    // Your business logic here
    // emit(JobLoaded(jobs));
  }
}
```

### 3. Create State

```dart
// features/job/presentation/cubit/job_state.dart
part of 'job_cubit.dart';

abstract class JobState extends Equatable {
  const JobState();
  
  @override
  List<Object> get props => [];
}

class JobInitial extends JobState {}
class JobLoading extends JobState {}
class JobLoaded extends JobState {
  final List<Job> jobs;
  const JobLoaded(this.jobs);
  
  @override
  List<Object> get props => [jobs];
}
class JobError extends JobState {
  final String message;
  const JobError(this.message);
  
  @override
  List<Object> get props => [message];
}
```

### 4. Create UI Page (View)

```dart
// features/job/presentation/pages/job_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/job_cubit.dart';
import '../cubit/job_state.dart';

class JobListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JobCubit()..loadJobs(),
      child: Scaffold(
        appBar: AppBar(title: Text('Jobs')),
        body: BlocBuilder<JobCubit, JobState>(
          builder: (context, state) {
            if (state is JobLoading) {
              return AppLoading();
            } else if (state is JobError) {
              return AppErrorWidget(message: state.message);
            } else if (state is JobLoaded) {
              return ListView.builder(
                itemCount: state.jobs.length,
                itemBuilder: (context, index) {
                  return JobCard(job: state.jobs[index]);
                },
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

## Using Constants

### Colors
```dart
import 'package:jobcrak/core/constants/app_colors.dart';

Container(
  color: AppColors.primaryGreen,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textWhite),
  ),
)
```

### Strings
```dart
import 'package:jobcrak/core/constants/app_strings.dart';

Text(AppStrings.login)
```

### Dimensions
```dart
import 'package:jobcrak/core/constants/app_dimensions.dart';

Padding(
  padding: EdgeInsets.all(AppDimensions.padding16),
  child: Text('Content'),
)
```

## Dark Mode

### Toggle Theme
```dart
// Using ThemeToggleButton widget
ThemeToggleButton()

// Or programmatically
context.read<ThemeCubit>().toggleTheme();
```

### Access Theme
```dart
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
```

## Using Reusable Widgets

### AppButton
```dart
AppButton(
  text: 'Login',
  onPressed: () {},
  isLoading: false,
)
```

### AppTextField
```dart
AppTextField(
  label: 'Email',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

### AppCard
```dart
AppCard(
  child: Text('Card Content'),
  onTap: () {},
)
```

## Dependency Injection

Register your dependencies in `lib/core/di/injection_container.dart`:

```dart
// Register Cubit
sl.registerFactory(() => JobCubit(sl()));

// Register Repository
sl.registerLazySingleton(() => JobRepository(sl()));

// Register Data Source
sl.registerLazySingleton(() => JobRemoteDataSource(sl()));
```

## Next Steps

1. Install dependencies: `flutter pub get`
2. Add your features following the MVVM pattern
3. Set up routing (using go_router)
4. Connect to your backend API
5. Add local storage for caching

## Notes

- All linting errors will be resolved after running `flutter pub get`
- The project uses `flutter_bloc` for state management
- Dark mode is fully supported
- All constants are centralized for easy maintenance

