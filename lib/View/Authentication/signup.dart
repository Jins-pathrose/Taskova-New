// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart'
//     show
//         Icons,
//         BoxDecoration,
//         BorderRadius,
//         Colors,
//         BoxShadow,
//         Gradient,
//         LinearGradient,
//         Offset;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:taskova_new/Model/api_config.dart';
// import 'package:taskova_new/View/Authentication/otp.dart';
// import 'package:taskova_new/View/Language/language_provider.dart';

// import 'login.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:ui';

// class Registration extends StatefulWidget {
//   const Registration({super.key});

//   @override
//   State<Registration> createState() => _RegistrationState();
// }

// class _RegistrationState extends State<Registration>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final TextEditingController _confirmPass = TextEditingController();
//   bool _visiblePassword = false;
//   bool _visibleConfirmPassword = false;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   late AppLanguage appLanguage;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   // Define the blue and white theme colors
//   final Color primaryBlue = const Color(0xFF2D6CDF);
//   final Color lightBlue = const Color(0xFF5B9DF5);
//   final Color accentBlue = const Color(0xFF1A4AAF);
//   final Color backgroundWhite = const Color(0xFFF9FBFF);
//   final Color cardWhite = Colors.white;
//   final Color textDarkBlue = const Color(0xFF0A2463);
//   final Color textLightGrey = const Color(0xFF8D9AB3);

//   @override
//   void initState() {
//     super.initState();
//     _visiblePassword = false;
//     _visibleConfirmPassword = false;
//     appLanguage = Provider.of<AppLanguage>(context, listen: false);

//     // Initialize animations
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.2),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );

//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPass.dispose();
//     super.dispose();
//   }

//   Future<void> registerUser() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     print("Starting API call...");
//     try {
//       var response = await http
//           .post(
//             Uri.parse(ApiConfig.registerUrl),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({
//               "email": _emailController.text,
//               "password": _passwordController.text,
//               "role": "DRIVER",
//             }),
//           )
//           .timeout(const Duration(seconds: 10));

//       print("Response received with status: ${response.statusCode}");
//       print("Response body: ${response.body}");

//       if (response.statusCode == 201) {
//         Navigator.push(
//           context,
//           CupertinoPageRoute(
//             builder: (context) => OtpVerification(email: _emailController.text),
//           ),
//         );
//       } else {
//         Map<String, dynamic> responseBody = jsonDecode(response.body);
//         setState(() {
//           _errorMessage =
//               responseBody['detail'] ?? appLanguage.get('registration_failed');
//         });
//       }
//     } catch (e) {
//       print("Error occurred: $e");
//       setState(() {
//         _errorMessage = appLanguage.get('connection_error');
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Widget _buildInputField({
//     required TextEditingController controller,
//     required String placeholder,
//     required IconData icon,
//     bool obscureText = false,
//     bool showVisibilityToggle = false,
//     bool visibilityState = false,
//     VoidCallback? onVisibilityToggle,
//     String? Function(String?)? validator,
//     TextInputType keyboardType = TextInputType.text,
//     String? label,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (label != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
//               child: Text(
//                 label,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: textDarkBlue,
//                 ),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 0.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: cardWhite,
//                 borderRadius: BorderRadius.circular(16.0),
//                 border: Border.all(color: Colors.blue.shade100, width: 1.0),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.blue.shade100.withOpacity(0.25),
//                     blurRadius: 8.0,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: CupertinoFormRow(
//                 padding: EdgeInsets.zero,
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: CupertinoTextFormFieldRow(
//                         controller: controller,
//                         obscureText: obscureText && !visibilityState,
//                         keyboardType: keyboardType,
//                         placeholder: placeholder,
//                         placeholderStyle: TextStyle(
//                           color: textLightGrey,
//                           fontSize: 16.0,
//                         ),
//                         style: TextStyle(color: textDarkBlue, fontSize: 16.0),
//                         prefix: Container(
//                           padding: EdgeInsets.only(right: 12.0, left: 8.0),
//                           child: Icon(icon, color: primaryBlue, size: 22),
//                         ),
//                         validator: validator,
//                         padding: EdgeInsets.symmetric(vertical: 12.0),
//                         decoration: BoxDecoration(border: null),
//                       ),
//                     ),
//                     if (showVisibilityToggle)
//                       CupertinoButton(
//                         padding: EdgeInsets.only(right: 12.0),
//                         minSize: 0,
//                         onPressed: onVisibilityToggle,
//                         child: Icon(
//                           visibilityState
//                               ? CupertinoIcons.eye_slash
//                               : CupertinoIcons.eye,
//                           color: lightBlue,
//                           size: 22,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       // backgroundColor: backgroundWhite,
//       navigationBar: CupertinoNavigationBar(
//         backgroundColor: cardWhite,
//         border: Border(
//           bottom: BorderSide(color: Colors.blue.shade50, width: 0.5),
//         ),
//         middle: Text(
//           appLanguage.get('create_account'),
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: textDarkBlue,
//           ),
//         ),
//         leading: CupertinoButton(
//           padding: EdgeInsets.zero,
//           child: Icon(CupertinoIcons.chevron_back, color: primaryBlue),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       child: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: SlideTransition(
//               position: _slideAnimation,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const SizedBox(height: 30),
//                       // Logo
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [primaryBlue, lightBlue],
//                           ),
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: primaryBlue.withOpacity(0.3),
//                               blurRadius: 15,
//                               spreadRadius: 5,
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Icon(
//                             CupertinoIcons.person_add,
//                             color: Colors.white,
//                             size: 40,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       // App name
//                       Text(
//                         appLanguage.get('app_name'),
//                         style: GoogleFonts.poppins(
//                           fontSize: 30,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 1.2,
//                           color: textDarkBlue,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       // Tagline
//                       Text(
//                         appLanguage.get('tagline_signup'),
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           color: textLightGrey,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 40),

//                       // Input Fields Container
//                       Container(
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           color: cardWhite,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.blue.shade200.withOpacity(0.2),
//                               spreadRadius: 2,
//                               blurRadius: 10,
//                               offset: const Offset(0, 5),
//                             ),
//                           ],
//                           border: Border.all(
//                             color: Colors.blue.shade100,
//                             width: 1.0,
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Registration form title
//                             Text(
//                               appLanguage.get('signup_title'),
//                               style: GoogleFonts.poppins(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w600,
//                                 color: textDarkBlue,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               appLanguage.get('signup_subtitle') ??
//                                   "Please fill in your details",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: textLightGrey,
//                               ),
//                             ),
//                             const SizedBox(height: 24),

//                             _buildInputField(
//                               controller: _emailController,
//                               placeholder: appLanguage.get('email_hint'),
//                               icon: CupertinoIcons.mail,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return appLanguage.get('enter_email');
//                                 }
//                                 if (!RegExp(
//                                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                                 ).hasMatch(value)) {
//                                   return appLanguage.get('email_required');
//                                 }
//                                 return null;
//                               },
//                               keyboardType: TextInputType.emailAddress,
//                               label: appLanguage.get('email'),
//                             ),

//                             _buildInputField(
//                               controller: _passwordController,
//                               placeholder: appLanguage.get('password_hint'),
//                               icon: CupertinoIcons.lock,
//                               obscureText: true,
//                               showVisibilityToggle: true,
//                               visibilityState: _visiblePassword,
//                               onVisibilityToggle: () {
//                                 setState(() {
//                                   _visiblePassword = !_visiblePassword;
//                                 });
//                               },
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return appLanguage.get('enter_password');
//                                 }
//                                 if (value.length < 6) {
//                                   return appLanguage.get(
//                                     'password_length_error',
//                                   );
//                                 }
//                                 return null;
//                               },
//                               label: appLanguage.get('password'),
//                             ),

//                             _buildInputField(
//                               controller: _confirmPass,
//                               placeholder: appLanguage.get('confirm_password'),
//                               icon: CupertinoIcons.lock_shield,
//                               obscureText: true,
//                               showVisibilityToggle: true,
//                               visibilityState: _visibleConfirmPassword,
//                               onVisibilityToggle: () {
//                                 setState(() {
//                                   _visibleConfirmPassword =
//                                       !_visibleConfirmPassword;
//                                 });
//                               },
//                               validator: (val) {
//                                 if (val == null || val.isEmpty)
//                                   return appLanguage.get(
//                                     'signup_confrm_password',
//                                   );
//                                 if (val != _passwordController.text)
//                                   return appLanguage.get(
//                                     'passwords_do_not_match',
//                                   );
//                                 return null;
//                               },
//                               label: appLanguage.get('confirm_password'),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Error message display
//                       if (_errorMessage.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 16.0),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.red.shade50,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.red.shade200),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   CupertinoIcons.exclamationmark_triangle_fill,
//                                   color: Colors.red,
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Text(
//                                     _errorMessage,
//                                     style: TextStyle(
//                                       color: Colors.red.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                       const SizedBox(height: 30),
//                       // Register button
//                       Container(
//                         width: double.infinity,
//                         height: 56,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           gradient: LinearGradient(
//                             colors: [primaryBlue, lightBlue],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: primaryBlue.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: CupertinoButton(
//                           padding: EdgeInsets.zero,
//                           borderRadius: BorderRadius.circular(16),
//                           onPressed:
//                               _isLoading
//                                   ? null
//                                   : () {
//                                     if (_formKey.currentState!.validate()) {
//                                       registerUser();
//                                     }
//                                   },
//                           child:
//                               _isLoading
//                                   ? const CupertinoActivityIndicator(
//                                     color: Colors.white,
//                                   )
//                                   : Text(
//                                     appLanguage
//                                         .get('create_account')
//                                         .toUpperCase(),
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                       letterSpacing: 1.0,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       // Divider with text
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               height: 1,
//                               color: Colors.blue.shade100,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: Text(
//                               appLanguage.get('or') ?? "OR",
//                               style: TextStyle(
//                                 color: textLightGrey,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Container(
//                               height: 1,
//                               color: Colors.blue.shade100,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//                       // Login link
//                       Container(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: Colors.blue.shade100),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               appLanguage.get('already_have_account'),
//                               style: TextStyle(
//                                 color: textDarkBlue,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             CupertinoButton(
//                               padding: const EdgeInsets.only(left: 4),
//                               child: Text(
//                                 appLanguage.get('login'),
//                                 style: GoogleFonts.poppins(
//                                   color: primaryBlue,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               onPressed: () {
//                                 Navigator.pushAndRemoveUntil(
//                                   context,
//                                   CupertinoPageRoute(
//                                     builder: (context) => const LoginPage(),
//                                   ),
//                                   (Route<dynamic> route) => false,
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show BoxDecoration, BorderRadius, Colors, BoxShadow, LinearGradient, Offset;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/Controller/Theme/theme.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/otp.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:lottie/lottie.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  late final AppLanguage _appLanguage;

  static const Color _darkmode = Color.fromARGB(255, 46, 15, 149);
  static const Color _darkGradientEnd = Color.fromARGB(255, 43, 33, 99);

  @override
  void initState() {
    super.initState();
    _appLanguage = context.read<AppLanguage>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearFormState();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _clearFormState() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPassController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _errorMessage = '';
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  Future<void> _registerUser() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "email": _emailController.text.trim(),
              "password": _passwordController.text,
              "role": "DRIVER",
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 201) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder:
                  (context) =>
                      OtpVerification(email: _emailController.text.trim()),
            ),
          );
        } else {
          final responseBody =
              jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _errorMessage =
                responseBody['detail']?.toString() ??
                _appLanguage.get('registration_failed');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _appLanguage.get('connection_error');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _navigateToLogin() {
    _clearFormState();
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (context) => const LoginPage(),
        settings: const RouteSettings(name: '/login'),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _appLanguage.get('enter_email');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return _appLanguage.get('email_required');
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _appLanguage.get('enter_password');
    }
    if (value.length < 6) {
      return _appLanguage.get('password_length_error');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return _appLanguage.get('signup_confrm_password');
    }
    if (value != _passwordController.text) {
      return _appLanguage.get('passwords_do_not_match');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            key: const ValueKey('registration_container'),
            decoration:
                themeProvider.isDarkMode
                    ? const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_darkmode, _darkGradientEnd],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    )
                    : const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: SingleChildScrollView(
                key: const ValueKey('registration_scroll'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        20,
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LogoSection(isDarkMode: themeProvider.isDarkMode),
                        const SizedBox(height: 40),
                        _TitleSection(
                          appLanguage: _appLanguage,
                          isDarkMode: themeProvider.isDarkMode,
                          onLoginTap: _navigateToLogin,
                        ),
                        const SizedBox(height: 24),
                        _InputField(
                          key: const ValueKey('registration_email_field'),
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          placeholder: _appLanguage.get('Email address'),
                          icon: CupertinoIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          isDarkMode: themeProvider.isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          key: const ValueKey('registration_password_field'),
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          placeholder: _appLanguage.get('Create password'),
                          icon: CupertinoIcons.lock,
                          obscureText: _obscurePassword,
                          showVisibilityToggle: true,
                          onVisibilityToggle: _togglePasswordVisibility,
                          validator: _validatePassword,
                          isDarkMode: themeProvider.isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          key: const ValueKey(
                            'registration_confirm_password_field',
                          ),
                          controller: _confirmPassController,
                          focusNode: _confirmPasswordFocusNode,
                          placeholder: _appLanguage.get('confirm_password'),
                          icon: CupertinoIcons.lock_shield,
                          obscureText: _obscureConfirmPassword,
                          showVisibilityToggle: true,
                          onVisibilityToggle: _toggleConfirmPasswordVisibility,
                          validator: _validateConfirmPassword,
                          isDarkMode: themeProvider.isDarkMode,
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ErrorMessage(message: _errorMessage),
                        ],
                        const SizedBox(height: 24),
                        _RegisterButton(
                          isLoading: _isLoading,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _registerUser();
                            }
                          },
                          appLanguage: _appLanguage,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final bool isDarkMode;

  const _LogoSection({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 180,
        width: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 140,
              child: Lottie.asset(
                'assets/lottietaskova.json',
                fit: BoxFit.contain,
                repeat: true,
                frameRate: FrameRate(30),
              ),
            ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                height: 40,
                width: 80,
                child: Image.asset(
                  isDarkMode
                      ? 'assets/white-logo.png'
                      : 'assets/taskova-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final AppLanguage appLanguage;
  final bool isDarkMode;
  final VoidCallback onLoginTap;

  const _TitleSection({
    required this.appLanguage,
    required this.isDarkMode,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          appLanguage.get('Join Taskova'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appLanguage.get('already_have_account'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    isDarkMode
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onLoginTap,
              child: Text(
                appLanguage.get('login'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final bool showVisibilityToggle;
  final VoidCallback? onVisibilityToggle;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isDarkMode;

  const _InputField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.icon,
    required this.isDarkMode,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.onVisibilityToggle,
    this.validator,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _hasError
                  ? Colors.red
                  : _isFocused
                  ? Colors.blue
                  : widget.isDarkMode
                  ? CupertinoColors.systemGrey4
                  : CupertinoColors.systemGrey5,
          width: _isFocused ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _isFocused
                    ? Colors.blue.withOpacity(0.1)
                    : CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: _isFocused ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              widget.icon,
              size: 18, // Reduced icon size to match smaller text
              color:
                  _isFocused
                      ? Colors.blue
                      : widget.isDarkMode
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.systemGrey,
            ),
          ),
          Expanded(
            child: CupertinoTextFormFieldRow(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              placeholder: widget.placeholder,
              placeholderStyle: GoogleFonts.poppins(
                color:
                    widget.isDarkMode
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                fontSize: 12, // Reduced font size
              ),
              style: GoogleFonts.poppins(
                color:
                    widget.isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                fontSize: 12, // Reduced font size
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ), // Adjusted padding
              decoration: const BoxDecoration(),
              validator: (value) {
                final result = widget.validator?.call(value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hasError = result != null;
                    });
                  }
                });
                return result;
              },
            ),
          ),
          if (widget.showVisibilityToggle)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: widget.onVisibilityToggle,
                child: Icon(
                  widget.obscureText
                      ? CupertinoIcons.eye_slash
                      : CupertinoIcons.eye,
                  color:
                      widget.isDarkMode
                          ? CupertinoColors.systemGrey2
                          : CupertinoColors.systemGrey,
                  size: 16, // Reduced visibility toggle icon size
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Colors.red,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final AppLanguage appLanguage;

  const _RegisterButton({
    required this.isLoading,
    required this.onPressed,
    required this.appLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44, // Reduced button height to match smaller font
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Color(0xFF8A84FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(12),
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(
                  appLanguage.get('create_account').toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Reduced font size
                  ),
                ),
      ),
    );
  }
}
