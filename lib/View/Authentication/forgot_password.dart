import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/reset_password.dart';
import 'dart:convert';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/Controller/Theme/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  late AppLanguage appLanguage;
  final Color primaryBlue = Colors.blue;
  final Color darkmode = const Color(0xFF2F197D);
  final Color lightBlue = const Color(0xFF8A84FF);

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final response = await http.post(
          Uri.parse(ApiConfig.forgotPasswordUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': _emailController.text}),
        );
        
        if (response.statusCode == 200) {
          _showSuccessDialog(appLanguage.get('OTP_sent_to_your_email'));
          Navigator.push(
            context, 
            CupertinoPageRoute(
              builder: (context) => NewPasswordScreen(email: _emailController.text),
            ),
          );
        } else {
          final responseData = jsonDecode(response.body);
          String errorMessage = responseData['message'] ?? 
              appLanguage.get('invalid_email');
          _showErrorDialog(errorMessage);
        }
      } catch (e) {
        _showErrorDialog('Network error: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
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
            'Oops!',
            style: GoogleFonts.poppins(
              color: CupertinoColors.destructiveRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                appLanguage.get('ok'),
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
            appLanguage.get('success'),
            style: GoogleFonts.poppins(
              color: CupertinoColors.systemGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                appLanguage.get('ok'),
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
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
              // Background Container to fill the entire screen
              Container(
                height: MediaQuery.of(context).size.height,
                decoration: backgroundDecoration,
              ),
              // Scrollable content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back Button
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
                            const SizedBox(height: 100),
                            // Main Heading
                            Text(
                              appLanguage.get('forgot_password'),
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
                            // Subtitle
                            Text(
                              appLanguage.get('''Don't worry! It occurs. Please enter the email address linked with your account.'''),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: themeProvider.isDarkMode
                                    ? CupertinoColors.systemGrey2
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 48),
                            // Email Field
                            Container(
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
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.mail,
                                    size: 20,
                                    color: themeProvider.isDarkMode
                                        ? CupertinoColors.systemGrey2
                                        : CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CupertinoTextFormFieldRow(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      placeholder: appLanguage.get( 'please_enter_email'),
                                      placeholderStyle: GoogleFonts.poppins(
                                        color: themeProvider.isDarkMode
                                            ? CupertinoColors.systemGrey2
                                            : CupertinoColors.systemGrey,
                                        fontSize: 14,
                                      ),
                                      style: GoogleFonts.poppins(
                                        color: themeProvider.isDarkMode
                                            ? CupertinoColors.white
                                            : CupertinoColors.black,
                                        fontSize: 14,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 10,
                                      ),
                                      decoration: const BoxDecoration(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return appLanguage.get('please_enter_email');
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return appLanguage.get('please_enter_valid_email');
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Send Code Button
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
                                onPressed: _isLoading ? null : _sendOTP,
                                child: _isLoading
                                    ? const CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      )
                                    : Text(
                                        appLanguage.get('Send_Code'),
                                        style: GoogleFonts.poppins(
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Remember Password Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  appLanguage.get('Remember_Password?'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: themeProvider.isDarkMode
                                        ? CupertinoColors.systemGrey2
                                        : CupertinoColors.systemGrey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    appLanguage.get('Login'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
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
}