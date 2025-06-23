import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:http/http.dart' as http;
import 'package:taskova_new/View/Onboarding/onboarding_screens.dart';
import 'package:taskova_new/View/profile.dart';
import 'dart:convert';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String selectedLanguage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    selectedLanguage = appLanguage.currentLanguage;
  }

  Future<void> saveLanguageAndNavigate() async {
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    // Save the selected language
    await appLanguage.changeLanguage(selectedLanguage);
    await prefs.setString('language_code', selectedLanguage);

    if (accessToken != null && accessToken.isNotEmpty) {
      // Check profile completion status
      final isProfileComplete = await checkProfileStatus(accessToken);
      if (isProfileComplete) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const MainWrapper()),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => ProfileRegistrationPage()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const OnboardingScreen()),
      );
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
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get flag emoji based on language code
  String getFlagEmoji(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ar':
        return '🇸🇦';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'ru':
        return '🇷🇺';
      case 'hi':
        return '🇮🇳';
      case 'ko':
        return '🇰🇷';
      case 'pl':
        return '🇵🇱';
      case 'bn':
        return '🇧🇩';
      case 'ro':
        return '🇷🇴';
      default:
        return '🌐';
    }
  }

  // Get native language name
  String getNativeLanguageName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'hi':
        return 'हिन्दी';
      case 'ko':
        return '한국어';
      case 'pl':
        return 'Polski';
      case 'bn':
        return 'বাংলা';
      case 'ro':
        return 'Română';
      default:
        return 'Language';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);
    final screenSize = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Step 2 of 4',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title and subtitle
              Text(
                appLanguage.get('Choose Language'),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLanguage.get('Select your preferred language for Taskova'),
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 40),
              
              // Language grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: appLanguage.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = appLanguage.supportedLanguages[index];
                    final isSelected = language['code'] == selectedLanguage;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLanguage = language['code']!;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF4285F4)
                                : CupertinoColors.systemGrey5,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Flag container
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.systemGrey6,
                              ),
                              child: Center(
                                child: Text(
                                  getFlagEmoji(language['code']!),
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Language name in English
                            Text(
                              language['name']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            
                            // Native language name
                            Text(
                              getNativeLanguageName(language['code']!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.systemGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            // Selection indicator
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4285F4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              Container(
                width: double.infinity,
                height: 56,
                child: CupertinoButton(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: isLoading ? null : () async {
                    setState(() {
                      isLoading = true;
                    });
                    await saveLanguageAndNavigate();
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                  child: isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text(
                          appLanguage.get('Continue'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}