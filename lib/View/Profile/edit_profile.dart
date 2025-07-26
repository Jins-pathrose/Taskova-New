import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/postcode.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _drivingDurationController = TextEditingController();
  
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  late AppLanguage appLanguage;
  // Add your color constants here
  final Color primaryBlue = Color(0xFF1A5DC1);
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
        appLanguage = Provider.of<AppLanguage>(context, listen: false);

  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      final accessToken = prefs.getString('access_token');

      setState(() {
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });

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
          _phoneController.text = data['phone_number'] ?? '';
          _selectedAddress = data['preferred_working_address'] ?? '';
          _addressController.text = _selectedAddress ?? '';
          _drivingDurationController.text = data['driving_duration'] ?? '';
          if (data.containsKey('latitude') && data.containsKey('longitude')) {
            _latitude = double.tryParse(data['latitude'].toString());
            _longitude = double.tryParse(data['longitude'].toString());
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data, but email is loaded from local storage.';
        });
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
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      print('Validation failed');
      return;
    }

    if (_selectedAddress == null || _latitude == null || _longitude == null) {
      _showErrorDialog(appLanguage.get('select_working_area'));
      print('Address or coordinates missing');
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

      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone_number'] = _phoneController.text;
      request.fields['preferred_working_address'] = _selectedAddress!;
      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();
      request.fields['driving_duration'] = _drivingDurationController.text;

      print('Sending profile update request: ${request.fields}');
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Request timed out. Please check your connection.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await _loadProfileData();
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
      print('Error during save: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
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
  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(appLanguage.get('edit_profile')),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Personal Information Section
              _buildModernFormField(
                controller: _nameController,
                placeholder: appLanguage.get('name'),
                icon: CupertinoIcons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLanguage.get('please_enter_name');
                  }
                  return null;
                },
              ),
              
              _buildModernFormField(
                controller: _emailController,
                placeholder: appLanguage.get('email'),
                icon: CupertinoIcons.mail,
                readOnly: true,
              ),
              
              _buildModernFormField(
                controller: _phoneController,
                placeholder: appLanguage.get('phone_number'),
                icon: CupertinoIcons.phone_fill,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLanguage.get('please_enter_phone_number');
                  }
                  return null;
                },
              ),
              
              // Preferred Working Address Section
              PostcodeSearchWidget(
                postcodeController: _postcodeController,
                placeholderText: appLanguage.get('enter_postcode'),
                onAddressSelected: (lat, lng, address) {
                  setState(() {
                    _selectedAddress = address;
                    _latitude = lat;
                    _longitude = lng;
                  });
                },
              ),
              
              // Save Button
              CupertinoButton(
                onPressed: _isSaving ? null : _saveProfile,
                color: primaryBlue,
                child: _isSaving 
                    ? CupertinoActivityIndicator()
                    : Text(appLanguage.get('save')),)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFormField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool isFirst = false,
    bool isLast = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: CupertinoTextFormFieldRow(
        controller: controller,
        placeholder: placeholder,
        prefix: Icon(icon, color: CupertinoColors.systemGrey),
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: validator,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        style: TextStyle(fontSize: 16),
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }
  
}