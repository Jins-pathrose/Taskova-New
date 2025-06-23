import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Language/language_selection.dart';
import 'package:taskova_new/View/profile.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set up fade animation for quote
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Set up shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    Future.delayed(const Duration(milliseconds: 500), () {
      _animationController.forward();
      // Run shimmer only once
      _shimmerController.forward();
    });
    
    // Check authentication state after delay
    Future.delayed(const Duration(seconds: 3), () {
      checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final languageSelected = prefs.getString('language_code');

    if (languageSelected == null) {
      navigateToLanguageSelection();
    } else if (accessToken != null && accessToken.isNotEmpty) {
      // Check profile completion status
      final isProfileComplete = await checkProfileStatus(accessToken);
      if (isProfileComplete) {
        navigateToHome();
      } else {
        navigateToProfileRegistration();
      }
    } else {
      navigateToLogin();
    }
  }

  Future<bool> checkProfileStatus(String accessToken) async {
    try {
      final profileResponse = await http.get(
        Uri.parse(ApiConfig.profileStatusUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final responseData = jsonDecode(profileResponse.body);
        return responseData['is_profile_complete'] == true;
      } else {
        // Handle API error by assuming profile is incomplete
        return false;
      }
    } catch (e) {
      // Handle network or other errors by assuming profile is incomplete
      return false;
    }
  }

  void navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const MainWrapper()),
      (Route<dynamic> route) => false,
    );
  }

  void navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void navigateToLanguageSelection() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const LanguageSelectionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void navigateToProfileRegistration() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => ProfileRegistrationPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Main content area with centered logo
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          height: 300,
                          width: 300,
                          child: Image.asset(
                            'assets/taskova-logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                              Icon(
                                CupertinoIcons.car_detailed, 
                                size: 80, 
                                color: CupertinoColors.systemGrey,
                              ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Full screen shimmer overlay
              Positioned.fill(
                child: ClipRect(
                  child: Transform.translate(
                    offset: Offset(
                      _shimmerAnimation.value * MediaQuery.of(context).size.width,
                      _shimmerAnimation.value * MediaQuery.of(context).size.height,
                    ),
                    child: Transform.rotate(
                      angle: 0.785398, // 45 degrees in radians
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.height * 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.35, 0.5, 0.65, 0.8, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}