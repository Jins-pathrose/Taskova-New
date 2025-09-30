// import 'dart:convert';

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_new/Model/Notifications/notification_service.dart';
// import 'package:taskova_new/View/BusinessReq/businessreq.dart';
// import 'package:taskova_new/View/Community/community_page.dart';
// import 'package:taskova_new/View/Homepage/homepage.dart';
// import 'package:taskova_new/View/Language/language_provider.dart';
// import 'package:taskova_new/View/Profile/profilepage.dart';
// import 'package:taskova_new/View/appliedjobs.dart';

// class MainWrapper extends StatefulWidget {
//   const MainWrapper({Key? key}) : super(key: key);

//   @override
//   State<MainWrapper> createState() => _MainWrapperState();
// }

// class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
//   final NotificationService _notificationService = NotificationService();
//   int _currentIndex = 0;
//   late AppLanguage appLanguage;
//   String? _fcmToken;
//   String _fcmStatus = '🔄 Sending FCM token...';

//   // Navigator keys for each tab to manage their navigation stacks
//   final List<GlobalKey<NavigatorState>> _navigatorKeys = [
//     GlobalKey<NavigatorState>(), // For HomePage
//     GlobalKey<NavigatorState>(), // For CommunityPage
//     GlobalKey<NavigatorState>(), // For ProfilePage
//     GlobalKey<NavigatorState>(), // For BusinessReq
//   ];

//   final List<Widget> _pages = [
//     const HomePage(),
//     const AppliedJobsPage(),
//     const CommunityPage(),
//     const ProfilePage(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     appLanguage = Provider.of<AppLanguage>(context, listen: false);
//     WidgetsBinding.instance.addObserver(this);
//     _notificationService.startNotificationService();
//     _initFCM();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         _notificationService.startNotificationService();
//         break;
//       case AppLifecycleState.paused:
//       case AppLifecycleState.inactive:
//         break;
//       default:
//         break;
//     }
//   }

//   // Handle tab tap and reset Home tab stack if Home is selected
//   void _onTabTapped(int index) {
//     if (_currentIndex == index && index == 0) {
//       _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
//     } else if (_currentIndex == index && index == 2) {
//       // Optional: add behavior for 3rd tab
//       _navigatorKeys[2].currentState?.popUntil((route) => route.isFirst);
//     } else {
//       setState(() {
//         _currentIndex = index;
//       });
//     }
//   }

//   Future<void> _initFCM() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('access_token');
//       final baseUrl = dotenv.env['BASE_URL'];

//       if (accessToken == null) {
//         debugPrint('❌ Access token not found');
//         setState(() {
//           _fcmStatus = '❌ Access token missing';
//         });
//         return;
//       }

//       if (baseUrl == null) {
//         debugPrint('❌ BASE_URL missing in .env');
//         setState(() {
//           _fcmStatus = '❌ BASE_URL missing';
//         });
//         return;
//       }

//       final token = await FirebaseMessaging.instance.getToken();
//       debugPrint('📲 FCM Token: $token');

//       if (token != null) {
//         setState(() {
//           _fcmToken = token;
//         });
//         await _sendFcmTokenToBackend(token, accessToken, baseUrl);
//       } else {
//         debugPrint('❌ FCM token is null');
//         setState(() {
//           _fcmStatus = '❌ Failed to get FCM token';
//         });
//       }
//     } catch (e) {
//       debugPrint('🔥 Error initializing FCM: $e');
//       setState(() {
//         _fcmStatus = '🔥 Error: $e';
//       });
//     }
//   }

//   Future<void> _sendFcmTokenToBackend(
//     String token,
//     String accessToken,
//     String baseUrl,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/save-fcm-token/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//         },
//         body: jsonEncode({'fcm_token': token}),
//       );

//       if (response.statusCode == 200) {
//         debugPrint('✅ FCM token sent to backend.');
//         setState(() {
//           _fcmStatus = '✅ Token updated successfully.';
//         });
//       } else {
//         debugPrint(
//           '❌ Failed to send FCM token. Status: ${response.statusCode}',
//         );
//         debugPrint('📦 Response: ${response.body}');
//         setState(() {
//           _fcmStatus = '❌ Failed to update token (${response.statusCode})';
//         });
//       }
//     } catch (e) {
//       debugPrint('🚫 Error sending token to backend: $e');
//       setState(() {
//         _fcmStatus = '🚫 Network error: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: CupertinoColors.systemBackground,
//       child: CupertinoTabScaffold(
//         tabBar: CupertinoTabBar(
//           currentIndex: _currentIndex,
//           onTap: _onTabTapped,
//           backgroundColor: CupertinoColors.systemBackground,
//           activeColor: CupertinoColors.systemBlue,
//           inactiveColor: CupertinoColors.systemGrey,
//           items: [
//             BottomNavigationBarItem(
//               icon: Icon(
//                 _currentIndex == 0
//                     ? CupertinoIcons.house_fill
//                     : CupertinoIcons.house,
//               ),
//               label: appLanguage.get('home'),
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(
//                 _currentIndex == 1
//                     ? CupertinoIcons.doc_checkmark
//                     : CupertinoIcons.doc,
//               ),
//               label: appLanguage.get('My Jobs'),
//             ),
//             // BottomNavigationBarItem(
//             //   icon: Icon(_currentIndex == 1
//             //       ? CupertinoIcons.tray_arrow_down_fill
//             //       : CupertinoIcons.tray_arrow_down),
//             //   label: appLanguage.get('Job_Request')
//             // ),
//             BottomNavigationBarItem(
//               icon: Icon(
//                 _currentIndex == 2
//                     ? CupertinoIcons.person_2_fill
//                     : CupertinoIcons.person_2,
//               ),
//               label: appLanguage.get('community'),
//             ),

//             BottomNavigationBarItem(
//               icon: Icon(
//                 _currentIndex == 3
//                     ? CupertinoIcons.person_fill
//                     : CupertinoIcons.person,
//               ),
//               label: appLanguage.get('profile'),
//             ),
//           ],
//         ),
//         tabBuilder: (context, index) {
//           return CupertinoTabView(
//             navigatorKey: _navigatorKeys[index],
//             builder: (context) {
//               return _pages[index];
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/Notifications/notification_service.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/BusinessReq/businessreq.dart';
import 'package:taskova_new/View/Community/community_page.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Profile/profilepage.dart';
import 'package:taskova_new/View/appliedjobs.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  int _currentIndex = 0;
  late AppLanguage appLanguage;
  String? _fcmToken;
  String _fcmStatus = '🔄 Sending FCM token...';
  bool _isRefreshing = false; // Prevent concurrent refresh calls

  // Navigator keys for each tab to manage their navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // For HomePage
    GlobalKey<NavigatorState>(), // For CommunityPage
    GlobalKey<NavigatorState>(), // For ProfilePage
    GlobalKey<NavigatorState>(), // For BusinessReq
  ];

  final List<Widget> _pages = [
    const HomePage(),
    const AppliedJobsPage(),
    const CommunityPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _notificationService.startNotificationService();
    _initFCM();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _notificationService.startNotificationService();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        break;
      default:
        break;
    }
  }

  // Handle tab tap and reset Home tab stack if Home is selected
  void _onTabTapped(int index) {
    if (_currentIndex == index && index == 0) {
      _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
    } else if (_currentIndex == index && index == 2) {
      // Optional: add behavior for 3rd tab
      _navigatorKeys[2].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _initFCM() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      final baseUrl = dotenv.env['BASE_URL'];

      if (accessToken == null) {
        await _refreshAccessToken(); // Try to refresh if no access token
        accessToken = prefs.getString('access_token');
        if (accessToken == null) {
          debugPrint('❌ Access token still missing after refresh');
          setState(() {
            _fcmStatus = '❌ Access token missing';
          });
          return;
        }
      }

      if (baseUrl == null) {
        debugPrint('❌ BASE_URL missing in .env');
        setState(() {
          _fcmStatus = '❌ BASE_URL missing';
        });
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('📲 FCM Token: $token');

      if (token != null) {
        setState(() {
          _fcmToken = token;
        });
        await _sendFcmTokenToBackend(token, accessToken, baseUrl);
      } else {
        debugPrint('❌ FCM token is null');
        setState(() {
          _fcmStatus = '❌ Failed to get FCM token';
        });
      }
    } catch (e) {
      debugPrint('🔥 Error initializing FCM: $e');
      setState(() {
        _fcmStatus = '🔥 Error: $e';
      });
    }
  }

  Future<void> _refreshAccessToken() async {
    if (_isRefreshing) return; // Avoid concurrent refreshes
    setState(() {
      _isRefreshing = true;
      _fcmStatus = '🔄 Refreshing token...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        debugPrint('❌ Refresh token not found');
        setState(() {
          _fcmStatus = '❌ Refresh token missing';
        });
        return;
      }

      final response = await http.post(
        Uri.parse('https://taskova.co.uk/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        final newRefreshToken =
            data['refresh'] ??
            refreshToken; // Update if backend provides new refresh token

        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);
        debugPrint('✅ Access token refreshed');
        setState(() {
          _fcmStatus = '✅ Token refreshed successfully';
        });
      } else {
        debugPrint('❌ Failed to refresh token. Status: ${response.statusCode}');
        debugPrint('📦 Response: ${response.body}');
        setState(() {
          _fcmStatus = '❌ Token refresh failed (${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('🚫 Error refreshing token: $e');
      setState(() {
        _fcmStatus = '🚫 Refresh error: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _sendFcmTokenToBackend(
    String token,
    String accessToken,
    String baseUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/save-fcm-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to backend.');
        setState(() {
          _fcmStatus = '✅ Token updated successfully.';
        });
      } else if (response.statusCode == 401) {
        debugPrint('🔄 Token expired, refreshing...');
        await _refreshAccessToken();
        final newAccessToken = await SharedPreferences.getInstance().then(
          (prefs) => prefs.getString('access_token'),
        );
        if (newAccessToken != null) {
          await _sendFcmTokenToBackend(
            token,
            newAccessToken,
            baseUrl,
          ); // Retry with new token
        } else {
          debugPrint('❌ No new access token after refresh');
          setState(() {
            _fcmStatus = '❌ Refresh failed, no new token';
          });
        }
       
      } else {
        debugPrint(
          '❌ Failed to send FCM token. Status: ${response.statusCode}',
        );
        debugPrint('📦 Response: ${response.body}');
        setState(() {
          _fcmStatus = '❌ Failed to update token (${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('🚫 Error sending token to backend: $e');
      setState(() {
        _fcmStatus = '🚫 Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: CupertinoColors.systemBackground,
          activeColor: CupertinoColors.systemBlue,
          inactiveColor: CupertinoColors.systemGrey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 0
                    ? CupertinoIcons.house_fill
                    : CupertinoIcons.house,
              ),
              label: appLanguage.get('home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 1
                    ? CupertinoIcons.doc_checkmark
                    : CupertinoIcons.doc,
              ),
              label: appLanguage.get('My Jobs'),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 2
                    ? CupertinoIcons.person_2_fill
                    : CupertinoIcons.person_2,
              ),
              label: appLanguage.get('community'),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 3
                    ? CupertinoIcons.person_fill
                    : CupertinoIcons.person,
              ),
              label: appLanguage.get('profile'),
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            navigatorKey: _navigatorKeys[index],
            builder: (context) {
              return _pages[index];
            },
          );
        },
      ),
    );
  }
}
