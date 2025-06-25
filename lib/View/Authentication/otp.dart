import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, BoxDecoration, BorderRadius, Colors, BoxShadow, Gradient, LinearGradient, Offset;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/Controller/Theme/theme.dart';

class OtpVerification extends StatefulWidget {
  final String email;

  const OtpVerification({super.key, required this.email});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  bool _isResending = false;
  String _errorMessage = '';
  String _successMessage = '';
  int _resendCountdown = 30;
  bool _showResendButton = false;
  late AppLanguage appLanguage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color primaryBlue = Colors.blue;
  final Color darkmode = const Color(0xFF2F197D);
  final Color lightBlue = const Color(0xFF8A84FF);

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _showResendButton = false;
    _resendCountdown = 30;
    const oneSec = Duration(seconds: 1);
    Timer.periodic(oneSec, (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
        setState(() {
          _showResendButton = true;
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpCode();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = appLanguage.get('otp_required');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"email": widget.email, "code": otp}),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog(appLanguage.get('email_verification_suc'));
        
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog(errorResponse['detail'] ?? 
            appLanguage.get('email_verification_fail'));
      }
    } catch (e) {
      _showErrorDialog(appLanguage.get('connection_error'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"email": widget.email}),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog(appLanguage.get('otp_sent'));
        _startResendTimer();
      } else {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog(errorResponse['detail'] ?? 
            appLanguage.get('otp_sent_fail'));
      }
    } catch (e) {
      _showErrorDialog(appLanguage.get('connection_error'));
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.light,
        ),
        child: CupertinoAlertDialog(
          title: Text(
            appLanguage.get('Incorrect_OTP'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: CupertinoColors.black,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.light,
        ),
        child: CupertinoAlertDialog(
          title: Text(
            'Success',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: CupertinoColors.black,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final backgroundDecoration = themeProvider.isDarkMode
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkmode,
                    const Color.fromARGB(255, 43, 33, 99),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : BoxDecoration(color: Colors.white);

        return CupertinoPageScaffold(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                decoration: backgroundDecoration,
              ),
              SafeArea(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Column(
                                // mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: themeProvider.isDarkMode
                                              ? CupertinoColors.darkBackgroundGray
                                              : CupertinoColors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: themeProvider.isDarkMode
                                                ? CupertinoColors.systemGrey4
                                                : CupertinoColors.systemGrey5,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.back,
                                          color: themeProvider.isDarkMode
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Text(
                                    appLanguage.get('verification_code'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                      color: themeProvider.isDarkMode
                                          ? CupertinoColors.white
                                          : CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: themeProvider.isDarkMode
                                            ? CupertinoColors.systemGrey2
                                            : CupertinoColors.systemGrey,
                                      ),
                                      children: [
                                        TextSpan(text: appLanguage.get('otp_snackbar')),
                                        TextSpan(
                                          text: " ${widget.email}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: themeProvider.isDarkMode
                                                ? CupertinoColors.white
                                                : CupertinoColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: List.generate(
                                        6,
                                        (index) => _buildOtpDigitField(index, themeProvider),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_errorMessage.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: themeProvider.isDarkMode
                                            ? Colors.red.shade900
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.isDarkMode
                                              ? Colors.red.shade700
                                              : Colors.red.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.exclamationmark_circle,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _errorMessage,
                                              style: GoogleFonts.poppins(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white
                                                    : Colors.red.shade700,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_successMessage.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: themeProvider.isDarkMode
                                            ? Colors.green.shade900
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.isDarkMode
                                              ? Colors.green.shade700
                                              : Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.checkmark_alt_circle,
                                            color: themeProvider.isDarkMode
                                                ? Colors.green.shade400
                                                : Colors.green.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _successMessage,
                                              style: GoogleFonts.poppins(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white
                                                    : Colors.green.shade700,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 40),
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryBlue, lightBlue],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryBlue.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      borderRadius: BorderRadius.circular(12),
                                      onPressed: _isLoading ? null : _verifyOtp,
                                      child: _isLoading
                                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                          : Text(
                                              appLanguage.get('verfy_code'),
                                              style: GoogleFonts.poppins(
                                                color: CupertinoColors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode
                                          ? CupertinoColors.darkBackgroundGray
                                          : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: themeProvider.isDarkMode
                                            ? CupertinoColors.systemGrey4
                                            : Colors.blue.shade100,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          appLanguage.get('didnt_receive_code'),
                                          style: GoogleFonts.poppins(
                                            color: themeProvider.isDarkMode
                                                ? CupertinoColors.white
                                                : CupertinoColors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _showResendButton
                                            ? CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                child: _isResending
                                                    ? CupertinoActivityIndicator(color: primaryBlue)
                                                    : Text(
                                                        appLanguage.get('resend_code'),
                                                        style: GoogleFonts.poppins(
                                                          color: primaryBlue,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                onPressed: _isResending ? null : _resendOtp,
                                              )
                                            : Text(
                                                "${appLanguage.get('Resend_in')} $_resendCountdown s",
                                                style: GoogleFonts.poppins(
                                                  color: primaryBlue,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtpDigitField(int index, ThemeProvider themeProvider) {
    return SizedBox(
      width: 48,
      height: 56,
      child: CupertinoTextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: themeProvider.isDarkMode
              ? CupertinoColors.white
              : CupertinoColors.black,
        ),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? CupertinoColors.systemGrey4
                : CupertinoColors.systemGrey5,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}