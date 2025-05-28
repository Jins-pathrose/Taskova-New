// import 'package:flutter/cupertino.dart';
// import 'package:provider/provider.dart';
// import 'package:taskova_new/Model/Notifications/notification_service.dart';
// import 'package:taskova_new/View/ChatPage/chatpage.dart';
// import 'package:taskova_new/View/Community/community_page.dart';
// import 'package:taskova_new/View/Homepage/admin_approval.dart';
// import 'package:taskova_new/View/Homepage/homepage.dart';
// import 'package:taskova_new/View/Language/language_provider.dart';
// import 'package:taskova_new/View/Profile/profilepage.dart';


// class MainWrapper extends StatefulWidget {
//   const MainWrapper({Key? key}) : super(key: key);

//   @override
//   State<MainWrapper> createState() => _MainWrapperState();
// }

// class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
//   final NotificationService _notificationService = NotificationService();

//   int _currentIndex = 0;
//   late AppLanguage appLanguage;

//   final List<Widget> _pages = [
//     const HomePage(),
//     const CommunityPage(),
//      ProfilePage(),

//   ];

//   @override
//   void initState() {
//     super.initState();
//     appLanguage = Provider.of<AppLanguage>(context, listen: false);
//     WidgetsBinding.instance.addObserver(this);
    
//     // Start notification service when user enters the app
//     _notificationService.startNotificationService();
//   }
//     @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
    
//     // Stop notification service when leaving the app
//     // _notificationService.stopNotificationService();
//     super.dispose();
//   }
  
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         // App came to foreground, start notifications
//         _notificationService.startNotificationService();
//         break;
//       case AppLifecycleState.paused:
//       case AppLifecycleState.inactive:
//         // App went to background, stop notifications
//         // _notificationService.stopNotificationService();
//         break;
//       default:
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       backgroundColor: CupertinoColors.systemBackground,
//       child: CupertinoTabScaffold(
//         tabBar: CupertinoTabBar(
//           currentIndex: _currentIndex,
//           onTap: (index) {
//             setState(() {
//               _currentIndex = index;
//             });
//           },
//           backgroundColor: CupertinoColors.systemBackground,
//           activeColor: CupertinoColors.systemBlue,
//           inactiveColor: CupertinoColors.systemGrey,
//           items: [
//             BottomNavigationBarItem(
//               icon: Icon(_currentIndex == 0 
//                   ? CupertinoIcons.house_fill 
//                   : CupertinoIcons.house),
//               label: appLanguage.get('Home'),
//             ),
            
//             BottomNavigationBarItem(
//               icon: Icon(_currentIndex == 1 
//                   ? CupertinoIcons.person_2_fill 
//                   : CupertinoIcons.person_2),
//               label: appLanguage.get('Community'),
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(_currentIndex == 2 
//                   ? CupertinoIcons.person_fill 
//                   : CupertinoIcons.person),
//               label: appLanguage.get('Profile'),
//             ),
//           ],
//         ),
//         tabBuilder: (context, index) {
//           return CupertinoTabView(
//             builder: (context) {
//               return _pages[index];
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/Model/Notifications/notification_service.dart';
import 'package:taskova_new/View/Community/community_page.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Profile/profilepage.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  int _currentIndex = 0;
  late AppLanguage appLanguage;

  final List<Widget> _pages = [
    const HomePage(),
    const CommunityPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _notificationService.startNotificationService();
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Prevent the scaffold from resizing when the keyboard appears
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: CupertinoColors.systemBackground,
          activeColor: CupertinoColors.systemBlue,
          inactiveColor: CupertinoColors.systemGrey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0
                  ? CupertinoIcons.house_fill
                  : CupertinoIcons.house),
              label: appLanguage.get('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1
                  ? CupertinoIcons.person_2_fill
                  : CupertinoIcons.person_2),
              label: appLanguage.get('Community'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2
                  ? CupertinoIcons.person_fill
                  : CupertinoIcons.person),
              label: appLanguage.get('Profile'),
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) {
              return _pages[index];
            },
          );
        },
      ),
    );
  }
}