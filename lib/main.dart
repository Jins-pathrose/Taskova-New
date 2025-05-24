// import 'dart:async';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_new/Controller/Theme/theme.dart';
// import 'package:taskova_new/Model/Notifications/notification_helper.dart';
// import 'package:taskova_new/View/Authentication/otp.dart';
// import 'package:taskova_new/View/Language/language_provider.dart';
// import 'package:taskova_new/View/splashscreen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
// await NotificationHelper.initialize();
//   await runZonedGuarded(() async {
//     try {
//       // Load environment variables
//       await dotenv.load(fileName: ".env").catchError((error) {
//         debugPrint("Error loading .env file: $error");
//         dotenv.env['BASE_URL'] ??= 'https://default-fallback-url.com';
//       });

//       // Initialize Firebase
//       await Firebase.initializeApp();

//       // Initialize shared preferences
//       final prefs = await SharedPreferences.getInstance();

//       runApp(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => AppLanguage()),
//             // ChangeNotifierProvider(
//             //   create: (_) => ThemeProvider(),
//             // ), // Add theme provider
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

// // Theme Provider to manage theme state

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // return Consumer<ThemeProvider>(
//     //   builder: (context, themeProvider, child) {
//     //     // Get system brightness
//     //     final brightness = MediaQuery.platformBrightnessOf(context);
//     //     final isSystemDark = brightness == Brightness.dark;

//     //     // Update theme provider with system theme
//     //     WidgetsBinding.instance.addPostFrameCallback((_) {
//     //       themeProvider.updateSystemTheme(isSystemDark);
//     //     });

//         return CupertinoApp(
//           debugShowCheckedModeBanner: false,
//           // Set theme based on system or user preference
//           // theme: CupertinoThemeData(
//           //   brightness:
//           //       themeProvider.followSystemTheme
//           //           ? brightness
//           //           : (themeProvider.isDarkMode
//           //               ? Brightness.dark
//           //               : Brightness.light),
//           // ),
//           home: Builder(
//             builder: (context) {
//               final languageProvider = Provider.of<AppLanguage>(
//                 context,
//                 listen: false,
//               );
//               return const SplashScreen();
//             },
//           ),
//         );
//       }
//   }
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Controller/Theme/theme.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env").catchError((error) {
        debugPrint("Error loading .env file: $error");
        dotenv.env['BASE_URL'] ??= 'https://default-fallback-url.com';
      });

      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize shared preferences
      final prefs = await SharedPreferences.getInstance();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppLanguage()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()), // Auto syncs theme
          ],
          child: const MyApp(),
        ),
      );
    } catch (e, stack) {
      debugPrint("App initialization failed: $e\n$stack");
      runApp(
        const CupertinoApp(
          home: Scaffold(body: Center(child: Text('Initialization Error'))),
        ),
      );
    }
  }, (error, stack) => debugPrint("Zone error: $error\n$stack"));
}

// Main App Widget
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
            brightness: themeProvider.followSystemTheme
                ? brightness
                : (themeProvider.isDarkMode ? Brightness.dark : Brightness.light),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
