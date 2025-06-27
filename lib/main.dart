// import 'dart:async';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:provider/provider.dart';
// import 'package:taskova_new/Controller/Theme/theme.dart';
// import 'package:taskova_new/Model/Notifications/notification_helper.dart';
// import 'package:taskova_new/View/Language/language_provider.dart';
// import 'package:taskova_new/View/splashscreen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await NotificationHelper.initialize();
//   await runZonedGuarded(() async {
//     try {
//       // Load environment variables
//       await dotenv.load(fileName: ".env").catchError((error) {
//         debugPrint("Error loading .env file: $error");
//         dotenv.env['BASE_URL'] ??= 'https://default-fallback-url.com';
//       });

//       // Initialize Firebase
//       await Firebase.initializeApp();

//       runApp(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => AppLanguage()),
//             ChangeNotifierProvider(create: (_) => ThemeProvider()), // Auto syncs theme
//           ],
//           child: const MyApp(),
//         ),
//       );
//     } catch (e, stack) {
//       debugPrint("App initialization failed: $e\n$stack");
//       runApp(
//         const CupertinoApp(
//           home: Scaffold(body: Center(child: Text('Initialization Error'))),
//         ),
//       );
//     }
//   }, (error, stack) => debugPrint("Zone error: $error\n$stack"));
// }

// // Main App Widget
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ThemeProvider>(
//       builder: (context, themeProvider, child) {
//         final brightness = MediaQuery.platformBrightnessOf(context);

//         return CupertinoApp(
//           debugShowCheckedModeBanner: false,
//           theme: CupertinoThemeData(
//             brightness: themeProvider.followSystemTheme
//                 ? brightness
//                 : (themeProvider.isDarkMode ? Brightness.dark : Brightness.light),
//           ),
//           home: const SplashScreen(),
//         );
//       },
//     );
//   }
// }
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print('📩 Handling a background message: ${message.messageId}');
// }

// Future<void> _requestNotificationPermission() async {
//   final status = await Permission.notification.status;

//   if (status.isGranted) {
//     debugPrint('✅ Notification permission already granted');
//   } else if (status.isDenied || status.isRestricted) {
//     final result = await Permission.notification.request();
//     if (result.isGranted) {
//       debugPrint('✅ Notification permission granted after request');
//     } else {
//       debugPrint('❌ Notification permission still not granted: $result');
//     }
//   } else if (status.isPermanentlyDenied) {
//     debugPrint('🚫 Notification permission permanently denied');
//     await openAppSettings();
//   }
// }

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taskova_new/Controller/Theme/theme.dart';
import 'package:taskova_new/Model/Notifications/notification_helper.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/splashscreen.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await runZonedGuarded(
    () async {
      try {
        // Load .env
        await dotenv.load(fileName: ".env").catchError((error) {
          debugPrint("⚠ Error loading .env: $error");
          dotenv.env['BASE_URL'] ??= 'https://default-fallback-url.com';
        });

        // Initialize Firebase
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        final app = Firebase.app();
        print("🔥 Firebase App name: ${app.name}");

        // Initialize Notifications
        await NotificationHelper.initialize();

        // ✅ Request notification permission
        await _requestNotificationPermission();

        // Run the app
        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AppLanguage()),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ],
            child: const MyApp(),
          ),
        );
      } catch (e, stackTrace) {
        debugPrint("🔥 App initialization failed: $e\n$stackTrace");
        runApp(
          const CupertinoApp(
            home: Scaffold(body: Center(child: Text('Initialization Error'))),
          ),
        );
      }
    },
    (error, stackTrace) {
      debugPrint("🔥 Uncaught Zone error: $error\n$stackTrace");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final brightness = MediaQuery.platformBrightnessOf(context);

        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness:
                themeProvider.followSystemTheme
                    ? brightness
                    : (themeProvider.isDarkMode
                        ? Brightness.dark
                        : Brightness.light),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Handling a background message: ${message.messageId}');
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;

  if (status.isGranted) {
    debugPrint('✅ Notification permission already granted');
  } else if (status.isDenied || status.isRestricted) {
    final result = await Permission.notification.request();
    if (result.isGranted) {
      debugPrint('✅ Notification permission granted after request');
    } else {
      debugPrint('❌ Notification permission still not granted: $result');
    }
  } else if (status.isPermanentlyDenied) {
    debugPrint('🚫 Notification permission permanently denied');
    await openAppSettings();
  }
}