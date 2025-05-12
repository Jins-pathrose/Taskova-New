import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/driver_document.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Show success notification
  void showSuccessNotification(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Success"),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show error notification
  void showErrorNotification(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Logout function that calls the API
  Future<void> logout(BuildContext context) async {
    print('Starting logout process');
    try {
      // Show loading dialog
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 10),
                Text("Logging out..."),
              ],
            ),
          );
        },
      );

      // Get tokens from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? "";
      final refreshToken = prefs.getString('refresh_token') ?? "";

      // Call logout API
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      // Close the loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 205) {
        // Successfully logged out from server
        Map<String, dynamic> responseData = {};
        try {
          if (response.body.isNotEmpty) {
            responseData = jsonDecode(response.body);
          }
        } catch (e) {
          // If the response body isn't valid JSON, ignore the error
          print("Response body parsing error: $e");
        }

        String successMessage =
            responseData['message'] ?? "Logged out successfully";
        print("Logged out successfully from server: $successMessage");

        // Clear stored tokens
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');

        // Show success notification briefly
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            // Auto-dismiss after delay
            Future.delayed(Duration(milliseconds: 800), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                
                // Navigate to login page using root navigator
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            });
            
            return CupertinoAlertDialog(
              title: Text("Success"),
              content: Text(successMessage),
            );
          },
        );
      } else {
        print("Logout API error: ${response.statusCode} ${response.body}");

        // Show error message
        Map<String, dynamic> errorData = {};
        try {
          if (response.body.isNotEmpty) {
            errorData = jsonDecode(response.body);
          }
        } catch (e) {
          // If the response body isn't valid JSON, ignore the error
          print("Error response body parsing error: $e");
        }

        String errorMessage =
            errorData['detail'] ?? "Logout failed. Please try again.";
        
        // We'll still clear tokens and redirect to login page even if the API call fails
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');

        // Show error notification with auto-dismiss
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            // Auto-dismiss after delay
            Future.delayed(Duration(milliseconds: 800), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                
                // Navigate to login page using root navigator
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            });
            
            return CupertinoAlertDialog(
              title: Text("Error"),
              content: Text(errorMessage),
            );
          },
        );
      }
    } catch (e) {
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("Error during logout: $e");

      // Try to clear tokens locally anyway
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');
        
        // Show error notification with auto-dismiss
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            // Auto-dismiss after delay
            Future.delayed(Duration(milliseconds: 800), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                
                // Navigate to login page using root navigator
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            });
            
            return CupertinoAlertDialog(
              title: Text("Error"),
              content: Text("Logout failed. Please try again."),
            );
          },
        );
      } catch (e) {
        print("Error clearing SharedPreferences: $e");
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(

        middle: const Text("Home Page"),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome!", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 10),
              // Payment Gateway Button
             
              // Document Registration Button
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => DocumentRegistrationPage()
                      )
                    );
                  },
                  color: CupertinoColors.activeBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    "Document Registration",
                    style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white),
                  ),
                ),
              ),
              // Logout Button
              CupertinoButton(
                onPressed: () => logout(context),
                color: CupertinoColors.destructiveRed,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                borderRadius: BorderRadius.circular(8),
                child: Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}