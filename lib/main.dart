import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'core/di/injection_container.dart' as di;
import 'core/services/fcm_service.dart';
import 'core/services/firebase_messaging_background.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/theme_cubit.dart';
import 'core/utils/app_logger.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (skip if already initialized - e.g. hot reload)
  bool firebaseInitialized = false;
  try {
    if (Firebase.apps.isEmpty) {
      AppLogger.info('Initializing Firebase...', tag: 'FIREBASE');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    firebaseInitialized = true;
    AppLogger.success('Firebase initialized successfully', tag: 'FIREBASE');
  } catch (e) {
    AppLogger.error(
      'Firebase initialization error',
      tag: 'FIREBASE',
      error: e,
    );
    AppLogger.info('SOLUTION FOR iOS FIREBASE ERROR:', tag: 'FIREBASE');
    AppLogger.info('1. Go to: https://console.firebase.google.com/', tag: 'FIREBASE');
    AppLogger.info('2. Select project: chatter-dc034', tag: 'FIREBASE');
    AppLogger.info('3. Click ⚙️ → Project Settings', tag: 'FIREBASE');
    AppLogger.info('4. Scroll to "Your apps" → Find iOS app (or add one)', tag: 'FIREBASE');
    AppLogger.info('5. Copy the App ID and update lib/firebase_options.dart line 77', tag: 'FIREBASE');
    AppLogger.info('OR run: flutterfire configure (easiest method)', tag: 'FIREBASE');
    AppLogger.warning('App will continue but Firebase features (auth) won\'t work', tag: 'FIREBASE');
  }
  
  AppLogger.debug('Initializing dependency injection...', tag: 'DI');
  await di.init();
  AppLogger.success('Dependency injection initialized', tag: 'DI');

  if (firebaseInitialized) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  if (firebaseInitialized && di.sl.isRegistered<FcmService>()) {
    await di.sl<FcmService>().initialize();
  }
  
  if (!firebaseInitialized) {
    AppLogger.warning('Firebase is not initialized. Authentication features will not work.', tag: 'FIREBASE');
    AppLogger.info('Please configure Firebase before using login/register features.', tag: 'FIREBASE');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'JobCrak',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

