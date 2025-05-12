import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Icons; // Only for icons not available in Cupertino
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/apple_sign_in.dart';
import 'package:taskova_new/View/Authentication/forgot_password.dart';
import 'package:taskova_new/View/Authentication/otp.dart';
import 'package:taskova_new/View/Authentication/signup.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AppLanguage appLanguage;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Define blue theme colors
  final Color primaryBlue = const Color(0xFF1E88E5);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFF64B5F6);

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    checkTokenAndNavigate();
  }

  Future<void> checkTokenAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String email,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
  }

  

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showInfoDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Info'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

 Future<void> _handleGoogleLogin() async {
  try {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return;

    final response = await http.post(
      Uri.parse(ApiConfig.googleLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': account.email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Extract tokens and name from response
      String accessToken = data['tokens']['access'] ?? "";
      String refreshToken = data['tokens']['refresh'] ?? "";
      String name = data['name'] ?? "User";
      String email = account.email;
      print("Access Token: $accessToken");
      print("Refresh Token: $refreshToken");
      print("Name: $name");
      print("Email: $email");
      // Save to SharedPreferences
      await saveTokens(accessToken, refreshToken, email, name);

      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => const MainWrapper()),
      );
    } else {
      _showErrorDialog(data['error'] ?? 'Google login failed');
    }
  } catch (e) {
    _showErrorDialog('Something went wrong during Google Sign-In');
  }
}


  Future<void> loginUser() async {
    if (_formkey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse(ApiConfig.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseData = jsonDecode(response.body);
          String accessToken = responseData['access'] ?? "";
          String refreshToken = responseData['refresh'] ?? "";
          String name = responseData['name'] ?? "User";

          await saveTokens(
            accessToken,
            refreshToken,
            _emailController.text,
            name,
          );

          final profileResponse = await http.get(
            Uri.parse(ApiConfig.profileStatusUrl),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (profileResponse.statusCode == 200) {
            final profileData = jsonDecode(profileResponse.body);
            bool isProfileComplete =
                profileData['is_profile_complete'] ?? false;
            bool isEmailVerified = profileData['is_email_verified'] ?? false;

            if (!isEmailVerified) {
              _showInfoDialog("Please verify your email");
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder:
                      (context) =>
                          OtpVerification(email: _emailController.text),
                ),
              );
            } else {
              _showSuccessDialog("Login successful!");
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder:
                      (context) =>
                          isProfileComplete
                              ? MainWrapper()
                              : ProfileRegistrationPage(),
                ),
              );
            }
          } else {
            _showErrorDialog("Could not verify profile status");
          }
        } else {
          final responseData = jsonDecode(response.body);

          // First, check for error message (e.g., incorrect credentials)
          if (response.statusCode != 200) {
            String errorMessage =
                responseData['detail'] ??
                "Login failed. Please check your credentials.";
            _showErrorDialog(errorMessage);
            return;
          }

          // If login is successful but email not verified
          bool isEmailVerified = responseData['is_email_verified'] ?? false;

          if (!isEmailVerified) {
            _showInfoDialog("Please verify your email");
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder:
                    (context) => OtpVerification(email: _emailController.text),
              ),
            );
          }
        }
      } catch (e) {
        _showErrorDialog(
          "Connection error. Please check your internet connection.",
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          appLanguage.get('login'),
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        border: Border(
          bottom: BorderSide(color: lightBlue.withOpacity(0.2), width: 1.0),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Form(
            key: _formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Animation
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        width: 180,
                        child: Lottie.asset(
                          'assets/Animation - 1746459409971.json',
                        ),
                      ),
                      Text(
                        appLanguage.get('app_name'),
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLanguage.get('tagline'),
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: lightBlue.withOpacity(0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: lightBlue.withOpacity(0.1),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoFormRow(
                      child: CupertinoTextFormFieldRow(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        placeholder: appLanguage.get('email_hint'),
                        placeholderStyle: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16.0,
                        ),
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16.0,
                        ),
                        prefix: Container(
                          padding: EdgeInsets.only(right: 12.0, left: 8.0),
                          child: Icon(
                            CupertinoIcons.mail,
                            color: primaryBlue,
                            size: 22,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return appLanguage.get('enter_email');
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return appLanguage.get('email_required');
                          }
                          return null;
                        },
                        decoration: BoxDecoration(border: null),
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Password Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: lightBlue.withOpacity(0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: lightBlue.withOpacity(0.1),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoFormRow(
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            placeholder: appLanguage.get('password_hint'),
                            placeholderStyle: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16.0,
                            ),
                            style: TextStyle(
                              color: CupertinoColors.black,
                              fontSize: 16.0,
                            ),
                            prefix: Container(
                              padding: EdgeInsets.only(right: 12.0, left: 8.0),
                              child: Icon(
                                CupertinoIcons.lock,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return appLanguage.get('enter_password');
                              }
                              if (value.length < 6) {
                                return appLanguage.get('password_required');
                              }
                              return null;
                            },
                            decoration: BoxDecoration(border: null),
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      appLanguage.get('forgot_password'),
                      style: TextStyle(color: primaryBlue),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Login Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _isLoading ? null : loginUser,
                    child:
                        _isLoading
                            ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                            : Text(
                              appLanguage.get('login'),
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        appLanguage.get('Or'),
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CupertinoButton(
                    onPressed: () async => _handleGoogleLogin(),
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.systemGrey5,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/th.jpeg', height: 24, width: 24),
                          const SizedBox(width: 12),
                          Text(
                            appLanguage.get('continue_with_google'),
                            style: TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Apple Sign In Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CupertinoButton(
                    onPressed: () => handleAppleSignIn(context),
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.systemGrey5,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.apple,
                            color: CupertinoColors.black,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            appLanguage.get('continue_with_apple'),
                            style: TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appLanguage.get('dont_have_account'),
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        appLanguage.get('sign_up'),
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const Registration(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
