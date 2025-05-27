import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/postcode.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/appliedjobs.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Define controllers for the editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Other profile data
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isSearching = false;

  // UI States
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Color scheme
  final Color primaryBlue = Color(0xFF1A5DC1);
  final Color lightBlue = Color(0xFFE6F0FF);
  final Color accentBlue = Color(0xFF0E4DA4);
  final Color whiteColor = CupertinoColors.white;

  late AppLanguage appLanguage;

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _loadProfileData();
  }

  // Load profile data from API/storage
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse(ApiConfig.driverProfileUrl);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _selectedAddress = data['preferred_working_address'] ?? '';
          _addressController.text = _selectedAddress ?? '';

          // Extract latitude and longitude if available
          if (data.containsKey('latitude') && data.containsKey('longitude')) {
            _latitude = double.tryParse(data['latitude'].toString());
            _longitude = double.tryParse(data['longitude'].toString());
          }
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null || _latitude == null || _longitude == null) {
      _showErrorDialog(appLanguage.get('select_working_area'));
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse(ApiConfig.driverProfileUrl);
      final request = http.MultipartRequest('PUT', url);

      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      });

      // Add form fields
      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone_number'] = _phoneController.text;
      request.fields['preferred_working_address'] = _selectedAddress!;
      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Request timed out. Please check your connection.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Refresh profile data
        _loadProfileData();
        setState(() {
          _isEditing = false;
        });
        _showSuccessDialog(appLanguage.get('profile_updated_successfully'));
      } else {
        setState(() {
          try {
            final responseData = json.decode(response.body);
            if (responseData is Map<String, dynamic>) {
              if (responseData.containsKey('detail')) {
                _errorMessage = responseData['detail'];
              } else {
                final List<String> errors = [];
                responseData.forEach((key, value) {
                  if (value is List && value.isNotEmpty) {
                    errors.add('$key: ${value.join(', ')}');
                  } else if (value is String) {
                    errors.add('$key: $value');
                  }
                });
                _errorMessage =
                    errors.isNotEmpty
                        ? errors.join('\n')
                        : 'Unknown error occurred';
              }
            } else {
              _errorMessage = 'Server returned an unexpected response format';
            }
          } catch (e) {
            _errorMessage = 'Failed to parse server response: ${e.toString()}';
          }
        });
      }
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Error updating profile: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Logout function
  Future<void> logout(BuildContext context) async {
    try {
      await _googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: Text("Error"),
              content: Text("Logout failed"),
              actions: [
                CupertinoDialogAction(
                  child: Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
    }
  }

  // Show confirmation dialog for logout
  void _showLogoutConfirmation() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoTheme(
            data: CupertinoThemeData(brightness: Brightness.light),
            child: CupertinoAlertDialog(
              title: Text(
                appLanguage.get('logout_confirmation'),
                style: TextStyle(color: primaryBlue),
              ),
              content: Text(appLanguage.get('are_you_sure_you_want_to_logout')),
              actions: [
                CupertinoDialogAction(
                  child: Text(
                    appLanguage.get('cancel'),
                    style: TextStyle(color: primaryBlue),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text(appLanguage.get('logout')),
                  onPressed: () {
                    Navigator.pop(context);
                    logout(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoTheme(
            data: CupertinoThemeData(brightness: Brightness.light),
            child: CupertinoAlertDialog(
              title: Text(
                appLanguage.get('error'),
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              content: Text(message),
              actions: [
                CupertinoDialogAction(
                  child: Text(
                    appLanguage.get('ok'),
                    style: TextStyle(color: primaryBlue),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  bool _isValidUKPhoneNumber(String phone) {
    // Remove spaces and country code for validation
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('+44', '');

    // UK phone numbers are typically 10-11 digits after country code
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return false;
    }

    // Check if it contains only digits
    return RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(
              appLanguage.get('success'),
              style: TextStyle(color: primaryBlue),
            ),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: Text(
                  appLanguage.get('ok'),
                  style: TextStyle(color: primaryBlue),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  // Helper widget for creating consistent form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? lightBlue.withOpacity(0.5) : lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
      ),
      child: CupertinoFormRow(
        child: CupertinoTextFormFieldRow(
          controller: controller,
          placeholder: placeholder,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          prefix: Icon(icon, color: primaryBlue),
          keyboardType: keyboardType,
          style: TextStyle(color: primaryBlue),
          placeholderStyle: TextStyle(color: primaryBlue.withOpacity(0.7)),
          decoration: BoxDecoration(color: Colors.transparent),
          readOnly: !_isEditing || readOnly,
          validator: validator,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // backgroundColor: whiteColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: primaryBlue,
        middle: Text(
          appLanguage.get('profile'),
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        trailing:
            _isLoading
                ? null
                : GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_isEditing) {
                        // Save changes
                        _saveProfile();
                      } else {
                        // Enter edit mode
                        _isEditing = true;
                      }
                    });
                  },
                  child:
                      _isSaving
                          ? CupertinoActivityIndicator(color: whiteColor)
                          : Icon(
                            _isEditing
                                ? CupertinoIcons.check_mark
                                : CupertinoIcons.pencil,
                            color: whiteColor,
                          ),
                ),
      ),
      child:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(color: primaryBlue, radius: 15),
                    SizedBox(height: 16),
                    Text(
                      appLanguage.get('loading_profile'),
                      style: TextStyle(color: primaryBlue, fontSize: 16),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message display
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: CupertinoColors.destructiveRed.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appLanguage.get('error'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryBlue, accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: whiteColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.person_badge_plus,
                                    color: whiteColor,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appLanguage.get('driver_status'),
                                        style: TextStyle(
                                          color: whiteColor.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        appLanguage.get('active'),
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    appLanguage.get('verified'),
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Profile Information Section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  appLanguage.get('personal_information'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                                if (!_isEditing && !_isLoading)
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      appLanguage.get('Edit'),
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            _buildFormField(
                              controller: _nameController,
                              placeholder: appLanguage.get('name'),
                              icon: CupertinoIcons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return appLanguage.get('please_enter_name');
                                }
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return appLanguage.get(
                                    'name_must_contain_only_alphabets',
                                  );
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildFormField(
                              controller: _emailController,
                              placeholder: appLanguage.get('email'),
                              icon: CupertinoIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true, // Always read-only
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return appLanguage.get('please_enter_email');
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return appLanguage.get(
                                    'please_enter_valid_email',
                                  );
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildFormField(
                              controller: _phoneController,
                              placeholder: appLanguage.get('phone_number'),
                              icon: CupertinoIcons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return appLanguage.get(
                                    'please_enter_phone_number',
                                  );
                                }
                                if (!_isValidUKPhoneNumber(value)) {
                                  return appLanguage.get(
                                    'please_enter_valid_uk_phone_number',
                                  );
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Preferred Working Area Section with Postcode Search
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguage.get('preferred_working_address'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Show PostcodeSearchWidget only in edit mode
                            if (_isEditing) ...[
                              // Using only the PostcodeSearchWidget for search functionality
                              PostcodeSearchWidget(
                                postcodeController: _postcodeController,
                                placeholderText: appLanguage.get(
                                  'enter_postcode',
                                ),
                                onAddressSelected: (
                                  latitude,
                                  longitude,
                                  address,
                                ) {
                                  setState(() {
                                    _selectedAddress = address;
                                    _latitude = latitude;
                                    _longitude = longitude;
                                    _addressController.text = address;
                                  });
                                },
                              ),

                              SizedBox(height: 16),
                            ],

                            // Display the selected/current address
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    _isEditing
                                        ? lightBlue.withOpacity(0.5)
                                        : whiteColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryBlue.withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing
                                        ? appLanguage.get(
                                          'selected_working_area',
                                        )
                                        : appLanguage.get(
                                          'current_working_area',
                                        ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _selectedAddress ??
                                        appLanguage.get('no_address_selected'),
                                    style: TextStyle(color: accentBlue),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Account Settings Section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguage.get('account_settings'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildSettingsItem(
                              icon: CupertinoIcons.bell,
                              title: appLanguage.get('Applied_Jobs'),
                              onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => AppliedJobsPage()));
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              icon: CupertinoIcons.lock,
                              title: appLanguage.get('change_password'),
                              onTap: () {
                                // Navigate to change password screen
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              icon: CupertinoIcons.globe,
                              title: appLanguage.get('language'),
                              onTap: () {
                                // Navigate to language settings
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsItem(
                              icon: CupertinoIcons.square_arrow_right,
                              title: appLanguage.get('logout'),
                              isDestructive: true,
                              onTap: _showLogoutConfirmation,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Bottom buttons
                      if (_isEditing)
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(12),
                                child: Text(
                                  appLanguage.get('cancel'),
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    // Reset controllers to original values
                                    _loadProfileData();
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    _isSaving
                                        ? CupertinoActivityIndicator(
                                          color: whiteColor,
                                        )
                                        : Text(
                                          appLanguage.get('save').toUpperCase(),
                                          style: TextStyle(
                                            color: whiteColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                onPressed: _isSaving ? null : _saveProfile,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(vertical: 8),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? CupertinoColors.destructiveRed : primaryBlue,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color:
                    isDestructive
                        ? CupertinoColors.destructiveRed
                        : primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color:
                isDestructive
                    ? CupertinoColors.destructiveRed
                    : primaryBlue.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: primaryBlue.withOpacity(0.2), height: 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class TimeoutException implements Exception {
  final String? message;
  TimeoutException(this.message);

  @override
  String toString() {
    return message ?? 'Request timed out';
  }
}
