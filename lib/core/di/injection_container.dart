import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import '../services/image_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/theme_cubit.dart';
import '../utils/onboarding_service.dart';
import '../../application/auth/auth_cubit.dart';
import '../../domain/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../features/community/data/datasources/group_remote_datasource.dart';
import '../../features/community/data/datasources/message_remote_datasource.dart';
import '../../features/community/data/datasources/notification_remote_datasource.dart';
import '../../features/community/data/datasources/broadcast_video_datasource.dart';
import '../../features/community/data/datasources/expense_remote_datasource.dart';
import '../../features/community/data/datasources/shared_gallery_datasource.dart';
import '../../features/community/data/repositories/group_repository_impl.dart';
import '../../features/community/data/repositories/message_repository_impl.dart';
import '../../domain/group_repository.dart';
import '../../domain/message_repository.dart';
import '../../application/group/group_cubit.dart';
import '../../application/message/message_cubit.dart';
import '../../application/addExpense/expense_cubit.dart';
import '../../application/sheredGallery/shared_gallery_cubit.dart';
import '../services/fcm_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  // Onboarding Service
  sl.registerLazySingleton(() => OnboardingService(sl<SharedPreferences>()));
  
  // Check if Firebase is initialized before registering Firebase services
  bool isFirebaseInitialized = false;
  try {
    Firebase.app(); // This will throw if Firebase is not initialized
    isFirebaseInitialized = true;
  } catch (e) {
    // Firebase is not initialized, skip Firebase service registration
    print('⚠️ Firebase not initialized, skipping Firebase services');
  }
  
  if (isFirebaseInitialized) {
    // Firebase Services
    sl.registerLazySingleton<firebase_auth.FirebaseAuth>(
      () => firebase_auth.FirebaseAuth.instance,
    );
    
    sl.registerLazySingleton<GoogleSignIn>(
      () => GoogleSignIn(),
    );
    
    // Data Sources
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
        googleSignIn: sl<GoogleSignIn>(),
      ),
    );
    
    // Repositories
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
        firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
        storage: sl<FirebaseStorage>(),
        firestore: sl<FirebaseFirestore>(),
      ),
    );
    
    // Firebase Storage
    sl.registerLazySingleton<FirebaseStorage>(
      () => FirebaseStorage.instance,
    );
    
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
    
    // Community Data Sources
    sl.registerLazySingleton<GroupRemoteDataSource>(
      () => GroupRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<firebase_auth.FirebaseAuth>(),
      ),
    );
    
    sl.registerLazySingleton<MessageRemoteDataSource>(
      () => MessageRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<firebase_auth.FirebaseAuth>(),
        storage: sl<FirebaseStorage>(),
      ),
    );
    
    sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<firebase_auth.FirebaseAuth>(),
      ),
    );
    
    sl.registerLazySingleton<BroadcastVideoDataSource>(
      () => BroadcastVideoDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<firebase_auth.FirebaseAuth>(),
        storage: sl<FirebaseStorage>(),
      ),
    );

    sl.registerLazySingleton<ExpenseRemoteDataSource>(
      () => ExpenseRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        auth: sl<firebase_auth.FirebaseAuth>(),
      ),
    );

    sl.registerLazySingleton<ImageUploadService>(
      () => ImgBBImageUploadService(),
    );
    sl.registerLazySingleton<SharedGalleryDataSource>(
      () => SharedGalleryDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        imageUpload: sl<ImageUploadService>(),
        auth: sl<firebase_auth.FirebaseAuth>(),
      ),
    );
    
    // Community Repositories
    sl.registerLazySingleton<GroupRepository>(
      () => GroupRepositoryImpl(
        remoteDataSource: sl<GroupRemoteDataSource>(),
      ),
    );
    
    sl.registerLazySingleton<MessageRepository>(
      () => MessageRepositoryImpl(
        messageDataSource: sl<MessageRemoteDataSource>(),
        broadcastDataSource: sl<BroadcastVideoDataSource>(),
      ),
    );
    
    // Cubits - Use registerFactory for Cubits (new instance each time)
    sl.registerFactory(() => ThemeCubit(sl<SharedPreferences>()));
    sl.registerFactory(
      () => AuthCubit(authRepository: sl<AuthRepository>()),
    );
    sl.registerFactory(
      () => GroupCubit(sl<GroupRemoteDataSource>(), sl<NotificationRemoteDataSource>()),
    );
    sl.registerFactory(
      () => MessageCubit(
        repository: sl<MessageRepository>(),
      ),
    );
    sl.registerFactory(() => ExpenseCubit(sl<ExpenseRemoteDataSource>()));
    sl.registerFactory(() => SharedGalleryCubit(sl<SharedGalleryDataSource>()));
    
    // FCM for push notifications
    sl.registerLazySingleton<FcmService>(() => FcmService());
  } else {
    // Register Cubits without Firebase dependencies
    sl.registerFactory(() => ThemeCubit(sl<SharedPreferences>()));
    // AuthCubit will not be available until Firebase is initialized
    print('⚠️ AuthCubit not registered - Firebase must be initialized first');
  }
}
