import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/View/ChatPage/chatpage.dart';
import 'package:taskova_new/View/Community/community_page.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Profile/profilepage.dart';


class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late AppLanguage appLanguage;

  final List<Widget> _pages = [
    const HomePage(),
     Chatpage(),
    const CommunityPage(),
     ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                  ? CupertinoIcons.bubble_left_fill 
                  : CupertinoIcons.bubble_left),
              label: appLanguage.get('Chat'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 
                  ? CupertinoIcons.person_2_fill 
                  : CupertinoIcons.person_2),
              label: appLanguage.get('Community'),
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 3 
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