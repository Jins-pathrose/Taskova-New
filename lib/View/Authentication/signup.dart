import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Icons, BoxDecoration, BorderRadius, Colors, BoxShadow, Gradient, LinearGradient, Offset;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/otp.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

import 'login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();
  bool _visiblePassword = false;
  bool _visibleConfirmPassword = false;
  bool _isLoading = false;
  String _errorMessage = '';
  late AppLanguage appLanguage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Define the blue and white theme colors
  final Color primaryBlue = const Color(0xFF2D6CDF);
  final Color lightBlue = const Color(0xFF5B9DF5);
  final Color accentBlue = const Color(0xFF1A4AAF);
  final Color backgroundWhite = const Color(0xFFF9FBFF);
  final Color cardWhite = Colors.white;
  final Color textDarkBlue = const Color(0xFF0A2463);
  final Color textLightGrey = const Color(0xFF8D9AB3);

  @override
  void initState() {
    super.initState();
    _visiblePassword = false;
    _visibleConfirmPassword = false;
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print("Starting API call...");
    try {
      print("Sending request to http://192.168.20.7:8000/api/register/");
      var response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
          "role": "DRIVER"
        }),
      ).timeout(const Duration(seconds: 10));
      
      print("Response received with status: ${response.statusCode}");
      print("Response body: ${response.body}");
      
      if (response.statusCode == 201) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => OtpVerification(email: _emailController.text),
          ),
        );
      } else {
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              responseBody['detail'] ?? appLanguage.get('registration_failed');
        });
      }
    } catch (e) {
      print("Error occurred: $e");
      setState(() {
        _errorMessage = appLanguage.get('connection_error');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscureText = false,
    bool showVisibilityToggle = false,
    bool visibilityState = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    String? label,
  }) {
    return Padding(
  padding: const EdgeInsets.only(bottom: 16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textDarkBlue,
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.blue.shade100,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.25),
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: CupertinoFormRow(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextFormFieldRow(
                    controller: controller,
                    obscureText: obscureText && !visibilityState,
                    keyboardType: keyboardType,
                    placeholder: placeholder,
                    placeholderStyle: TextStyle(
                      color: textLightGrey,
                      fontSize: 16.0,
                    ),
                    style: TextStyle(
                      color: textDarkBlue,
                      fontSize: 16.0,
                    ),
                    prefix: Container(
                      padding: EdgeInsets.only(right: 12.0, left: 8.0),
                      child: Icon(
                        icon,
                        color: primaryBlue,
                        size: 22,
                      ),
                    ),
                    validator: validator,
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(border: null),
                  ),
                ),
                if (showVisibilityToggle)
                  CupertinoButton(
                    padding: EdgeInsets.only(right: 12.0),
                    minSize: 0,
                    onPressed: onVisibilityToggle,
                    child: Icon(
                      visibilityState
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: lightBlue,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: cardWhite,
        border: Border(
          bottom: BorderSide(
            color: Colors.blue.shade50,
            width: 0.5,
          ),
        ),
        middle: Text(
          appLanguage.get('create_account'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textDarkBlue,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: primaryBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryBlue,
                              lightBlue,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.person_add,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // App name
                      Text(
                        appLanguage.get('app_name'),
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: textDarkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tagline
                      Text(
                        appLanguage.get('tagline_signup'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: textLightGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Input Fields Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Registration form title
                            Text(
                              appLanguage.get('signup_title'),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textDarkBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              appLanguage.get('signup_subtitle') ?? "Please fill in your details",
                              style: TextStyle(
                                fontSize: 14,
                                color: textLightGrey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildInputField(
                              controller: _emailController,
                              placeholder: appLanguage.get('email_hint'),
                              icon: CupertinoIcons.mail,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return appLanguage.get('enter_email');
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return appLanguage.get('email_required');
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                              label: appLanguage.get('email'),
                            ),
                            
                            _buildInputField(
                              controller: _passwordController,
                              placeholder: appLanguage.get('password_hint'),
                              icon: CupertinoIcons.lock,
                              obscureText: true,
                              showVisibilityToggle: true,
                              visibilityState: _visiblePassword,
                              onVisibilityToggle: () {
                                setState(() {
                                  _visiblePassword = !_visiblePassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return appLanguage.get('enter_password');
                                }
                                if (value.length < 6) {
                                  return appLanguage.get('password_length_error');
                                }
                                return null;
                              },
                              label: appLanguage.get('password'),
                            ),
                            
                            _buildInputField(
                              controller: _confirmPass,
                              placeholder: appLanguage.get('confirm_password'),
                              icon: CupertinoIcons.lock_shield,
                              obscureText: true,
                              showVisibilityToggle: true,
                              visibilityState: _visibleConfirmPassword,
                              onVisibilityToggle: () {
                                setState(() {
                                  _visibleConfirmPassword = !_visibleConfirmPassword;
                                });
                              },
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return appLanguage.get('signup_confrm_password');
                                if (val != _passwordController.text)
                                  return appLanguage.get('passwords_do_not_match');
                                return null;
                              },
                              label: appLanguage.get('confirm_password'),
                            ),
                          ],
                        ),
                      ),

                      // Error message display
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_triangle_fill,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                      // Register button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue,
                              lightBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(16),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    registerUser();
                                  }
                                },
                          child: _isLoading
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : Text(
                                  appLanguage.get('create_account').toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider with text
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.blue.shade100,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              appLanguage.get('or') ?? "OR",
                              style: TextStyle(
                                color: textLightGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.blue.shade100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Login link
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade100,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appLanguage.get('already_have_account'),
                              style: TextStyle(
                                color: textDarkBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                appLanguage.get('login'),
                                style: GoogleFonts.poppins(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}