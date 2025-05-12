import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Language/language_selection.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Set up animation for logo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
    
    // Check authentication state after animation
    Future.delayed(const Duration(seconds: 4), () {
      checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final languageSelected = prefs.getString('language_code');

    if (languageSelected == null) {
      navigateToLanguageSelection();
    } else if (accessToken != null && accessToken.isNotEmpty) {
      navigateToHome();
    } else {
      navigateToLogin();
    }
  }

  void navigateToHome() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  void navigateToLogin() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void navigateToLanguageSelection() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBlue.withOpacity(0.1),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with animation
              ScaleTransition(
                scale: _animation,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/app_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(CupertinoIcons.car_detailed, size: 80, color: CupertinoColors.systemBlue.darkColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // App name with fade-in effect
              FadeTransition(
                opacity: _animation,
                child: Text(
                  appLanguage.get('app_name'),
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemBlue.darkColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline with fade-in effect
              FadeTransition(
                opacity: _animation,
                child: Text(
                  appLanguage.get('tagline'),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: CupertinoColors.systemBlue.darkColor.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const CupertinoActivityIndicator(
                radius: 12,
                color: CupertinoColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}