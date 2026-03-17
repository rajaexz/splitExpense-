# Repository Setup with Get_It

## How to Register Repositories in injection_container.dart

### Step 1: Register Data Sources

```dart
// Remote Data Source
sl.registerLazySingleton<JobRemoteDataSource>(
  () => JobRemoteDataSourceImpl(client: sl<Dio>()),
);

// Local Data Source
sl.registerLazySingleton<JobLocalDataSource>(
  () => JobLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
);
```

### Step 2: Register Repository

```dart
// Repository Implementation
sl.registerLazySingleton<JobRepository>(
  () => JobRepositoryImpl(
    remoteDataSource: sl<JobRemoteDataSource>(),
    localDataSource: sl<JobLocalDataSource>(),
  ),
);
```

### Step 3: Register Use Cases (Optional)

```dart
sl.registerLazySingleton(() => GetJobsUseCase(sl<JobRepository>()));
sl.registerLazySingleton(() => GetJobByIdUseCase(sl<JobRepository>()));
```

### Step 4: Register Cubit

```dart
sl.registerFactory(() => JobCubit(
  getJobsUseCase: sl<GetJobsUseCase>(),
));
```

## Complete Example

```dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../utils/theme_cubit.dart';
import '../../features/job/data/repositories/job_repository_impl.dart';
import '../../features/job/domain/repositories/job_repository.dart';
import '../../features/job/data/datasources/job_remote_datasource.dart';
import '../../features/job/data/datasources/job_local_datasource.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  // Network
  sl.registerLazySingleton(() => Dio());
  
  // Data Sources
  sl.registerLazySingleton<JobRemoteDataSource>(
    () => JobRemoteDataSourceImpl(client: sl<Dio>()),
  );
  
  sl.registerLazySingleton<JobLocalDataSource>(
    () => JobLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );
  
  // Repositories
  sl.registerLazySingleton<JobRepository>(
    () => JobRepositoryImpl(
      remoteDataSource: sl<JobRemoteDataSource>(),
      localDataSource: sl<JobLocalDataSource>(),
    ),
  );
  
  // Cubits
  sl.registerFactory(() => ThemeCubit(sl<SharedPreferences>()));
}
```

## Usage in Cubit

```dart
class JobCubit extends Cubit<JobState> {
  final JobRepository repository;
  
  JobCubit({required this.repository}) : super(JobInitial());
  
  Future<void> loadJobs() async {
    emit(JobLoading());
    try {
      final jobs = await repository.getJobs();
      emit(JobLoaded(jobs));
    } catch (e) {
      emit(JobError(e.toString()));
    }
  }
}
```

## Usage in UI

```dart
BlocProvider(
  create: (context) => sl<JobCubit>()..loadJobs(),
  child: JobListPage(),
)
```

## Important Notes

1. **registerFactory**: Use for Cubits (new instance each time)
2. **registerLazySingleton**: Use for Repositories, Data Sources, Use Cases (single instance, created on first access)
3. **registerSingleton**: Use for services that should be created immediately

