import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/postcode.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
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
  final TextEditingController _manualAddressController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _townController = TextEditingController();

  bool _useManualAddress = false;
  bool _isGeocodingPostcode = false;
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AppLanguage appLanguage;
  String? _selectedDrivingDuration;

  // Driving duration options matching Django model
  final List<Map<String, String>> _drivingDurationOptions = [
    {'value': '0-1', 'label': 'Less than 1 year'},
    {'value': '1-2', 'label': '1–2 years'},
    {'value': '3-5', 'label': '3–5 years'},
    {'value': '5+', 'label': '5+ years'},
  ];

  // Color scheme consistent with ProfileRegistrationPage
  final Color primaryBlue = Color(0xFF1565C0);
  final Color lightBlue = Color(0xFFE3F2FD);
  final Color whiteColor = Colors.white;
  final Color accentBlue = Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _loadProfileData();
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
          _phoneController.text = data['phone_number'] ?? '+44 ';
          _selectedAddress = data['preferred_working_address'] ?? '';
          _manualAddressController.text = data['address'] ?? '';
          _addressLine1Controller.text = data['address_line1'] ?? '';
          _addressLine2Controller.text = data['address_line2'] ?? '';
          _townController.text = data['town'] ?? '';
          _selectedDrivingDuration = data['driving_duration'] ?? '1-2';
          if (data.containsKey('latitude') && data.containsKey('longitude')) {
            _latitude = double.tryParse(data['latitude'].toString());
            _longitude = double.tryParse(data['longitude'].toString());
          }
        });
      } else if (response.statusCode == 401) {
        await _clearAccessToken();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = appLanguage.get('failed_to_load_profile_data');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = appLanguage.get('error_loading_profile') + ': ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidUKPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('+44', '');
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return false;
    }
    return RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
  }

  Future<bool> _geocodePostcode(String postcode) async {
  if (postcode.trim().isEmpty) {
    print('Postcode is empty');
    return false;
  }

  setState(() {
    _isGeocodingPostcode = true;
  });

  try {
    String cleanedPostcode = postcode.trim().toUpperCase();
    final url = Uri.parse(
      'https://api.postcodes.io/postcodes/${Uri.encodeComponent(cleanedPostcode)}',
    );

    final response = await http.get(url).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Geocoding request timed out');
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 200 && data['result'] != null) {
        final result = data['result'];
        final lat = result['latitude'];
        final lng = result['longitude'];
        if (lat != null && lng != null) {
          setState(() {
            _latitude = lat is int ? lat.toDouble() : lat.toDouble();
            _longitude = lng is int ? lng.toDouble() : lng.toDouble();
          });
          return true;
        } else {
          print('Latitude or longitude is null in API response');
          return false;
        }
      } else {
        print('API returned error status or null result');
        return false;
      }
    } else if (response.statusCode == 404) {
      print('Postcode not found (404)');
      return false;
    } else {
      print('HTTP error: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Exception during geocoding: $e');
    return false;
  } finally {
    setState(() {
      _isGeocodingPostcode = false;
    });
  }
}

 Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_useManualAddress) {
    if (_manualAddressController.text.trim().isEmpty) {
      _showErrorDialog(appLanguage.get('please_enter_postcode'));
      return;
    }
    if (_addressLine1Controller.text.trim().isEmpty) {
      _showErrorDialog(appLanguage.get('please_enter_address_line_1'));
      return;
    }
    if (_townController.text.trim().isEmpty) {
      _showErrorDialog(appLanguage.get('please_enter_town_city'));
      return;
    }
    
    // Validate postcode when saving profile
    if (_latitude == null || _longitude == null) {
      print('Coordinates are null - validating postcode now...');
      try {
        bool isValid = await _geocodePostcode(_manualAddressController.text.trim());
        // Check if geocoding was successful
        if (!isValid) {
          _showErrorDialog(appLanguage.get('please_enter_a_valid_uk_postcode'));
          return;
        }
      } catch (e) {
        _showErrorDialog(appLanguage.get('please_enter_a_valid_uk_postcode'));
        return;
      }
    }
  } else {
    if (_selectedAddress == null || _latitude == null || _longitude == null) {
      _showErrorDialog(appLanguage.get('select_working_area'));
      return;
    }
  }

  if (_selectedDrivingDuration == null) {
    _showErrorDialog(appLanguage.get('please_select_driving_duration'));
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
      throw Exception(appLanguage.get('authentication_token_not_found'));
    }

    final url = Uri.parse(ApiConfig.driverProfileUrl);
    final request = http.MultipartRequest('PUT', url);

    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    });

    request.fields['name'] = _nameController.text;
    request.fields['phone_number'] = _phoneController.text;
    if (_useManualAddress) {
      request.fields['address'] = _manualAddressController.text;
      request.fields['address_line1'] = _addressLine1Controller.text;
      request.fields['address_line2'] = _addressLine2Controller.text;
      request.fields['town'] = _townController.text;
      request.fields['preferred_working_address'] =
          '${_addressLine1Controller.text}, ${_addressLine2Controller.text.isNotEmpty ? _addressLine2Controller.text + ', ' : ''}${_townController.text}, ${_manualAddressController.text}';
    } else {
      request.fields['preferred_working_address'] = _selectedAddress ?? '';
    }
    request.fields['latitude'] = _latitude!.toString();
    request.fields['longitude'] = _longitude!.toString();
    request.fields['driving_duration'] = _selectedDrivingDuration!;

    final streamedResponse = await request.send().timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException(appLanguage.get('request_timed_out'));
      },
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      await _clearAccessToken();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      await prefs.setString('user_name', _nameController.text);
      await _loadProfileData();
      _showSuccessDialog(appLanguage.get('profile_updated_successfully'));
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (context) => const MainWrapper()),
        (Route<dynamic> route) => false,
      );
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
              _errorMessage = errors.isNotEmpty
                  ? errors.join('\n')
                  : appLanguage.get('unknown_error');
            }
          } else {
            _errorMessage = appLanguage.get('unexpected_response_format');
          }
        } catch (e) {
          _errorMessage = appLanguage.get('failed_to_parse_response') + ': ${e.toString()}';
        }
      });
    }
  } catch (e) {
    setState(() {
      if (e is TimeoutException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = appLanguage.get('error_updating_profile') + ': ${e.toString()}';
      }
    });
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}

  Future<void> _clearAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
    } catch (e) {
      print('Error clearing access token: $e');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoTheme(
        data: CupertinoThemeData(brightness: Brightness.light),
        child: CupertinoAlertDialog(
          title: Text(
            appLanguage.get('OOPS!'),
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

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
    return WillPopScope(
      onWillPop: () async => true,
      child: CupertinoPageScaffold(
        backgroundColor: Color(0xFFF8F9FA),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4A90E2).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.all(6),
                        minSize: 36,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.chevron_left,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguage.get('edit_profile'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              appLanguage.get('update_your_profile_details'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 36),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading || _isSaving
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CupertinoActivityIndicator(
                                  color: Color(0xFF4A90E2),
                                  radius: 16,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  _isLoading
                                      ? appLanguage.get('loading_profile_information')
                                      : appLanguage.get('saving_profile_information'),
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFFE2E8F0),
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Error message
                                  if (_errorMessage != null)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Color(0xFFFECACA),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.exclamationmark_circle_fill,
                                            color: Color(0xFFDC2626),
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Personal Information Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF4A90E2).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.person_2_fill,
                                          color: Color(0xFF4A90E2),
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        appLanguage.get('personal_information'),
                                        style: TextStyle(
                                          color: Color(0xFF2D3748),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Name Field
                                  _buildModernTextField(
                                    controller: _nameController,
                                    label: appLanguage.get('full_name'),
                                    placeholder: appLanguage.get('name'),
                                    icon: CupertinoIcons.person_fill,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return appLanguage.get('please_enter_name');
                                      }
                                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                        return appLanguage.get('name_must_contain_only_alphabets');
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12),

                                  // Email Field
                                  _buildModernTextField(
                                    controller: _emailController,
                                    label: appLanguage.get('email'),
                                    placeholder: appLanguage.get('email'),
                                    icon: CupertinoIcons.mail,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                  ),
                                  SizedBox(height: 12),

                                  // Phone Field
                                  _buildModernTextField(
                                    controller: _phoneController,
                                    label: appLanguage.get('phone_number'),
                                    placeholder: appLanguage.get('phone_number'),
                                    icon: CupertinoIcons.phone_fill,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return appLanguage.get('please_enter_phone_number');
                                      }
                                      if (!_isValidUKPhoneNumber(value)) {
                                        return appLanguage.get('please_enter_valid_uk_phone_number');
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (!value.startsWith('+44')) {
                                        _phoneController.text = '+44 ' + value.replaceAll('+44', '').trim();
                                        _phoneController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: _phoneController.text.length),
                                        );
                                      }
                                    },
                                  ),
                                  SizedBox(height: 24),

                                  // Address Section
                                  _buildUpdatedAddressSection(),
                                  SizedBox(height: 24),

                                  // Driving Experience Section
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF4A90E2).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.star_fill,
                                          color: Color(0xFF4A90E2),
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        appLanguage.get('driving_experience'),
                                        style: TextStyle(
                                          color: Color(0xFF2D3748),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    appLanguage.get('how_long_have_you_been_driving'),
                                    style: TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  GestureDetector(
                                    onTap: () {
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (context) => CupertinoActionSheet(
                                          title: Text(
                                            appLanguage.get('driving_experience'),
                                            style: TextStyle(
                                              color: Color(0xFF2D3748),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          actions: _drivingDurationOptions
                                              .map(
                                                (option) => CupertinoActionSheetAction(
                                                  child: Text(
                                                    option['label']!,
                                                    style: TextStyle(
                                                      color: Color(0xFF4A90E2),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedDrivingDuration = option['value'];
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              )
                                              .toList(),
                                          cancelButton: CupertinoActionSheetAction(
                                            child: Text(
                                              appLanguage.get('cancel'),
                                              style: TextStyle(
                                                color: CupertinoColors.destructiveRed,
                                              ),
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF7FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Color(0xFFE2E8F0),
                                          width: 0.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 6,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.time,
                                            color: Color(0xFF4A90E2),
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _selectedDrivingDuration == null
                                                  ? appLanguage.get('select_driving_duration')
                                                  : _drivingDurationOptions
                                                      .firstWhere(
                                                        (option) => option['value'] == _selectedDrivingDuration,
                                                      )['label']!,
                                              style: TextStyle(
                                                color: _selectedDrivingDuration == null
                                                    ? Color(0xFF718096)
                                                    : Color(0xFF2D3748),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.chevron_down,
                                            color: Color(0xFF718096),
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24),

                                  // Save Button
                                  CupertinoButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF4A90E2),
                                            Color(0xFF357ABD),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF4A90E2).withOpacity(0.2),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            appLanguage.get('save_profile'),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        CupertinoTextFormFieldRow(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          onChanged: onChanged,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: readOnly ? Color(0xFFF7FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0), width: 1),
          ),
          prefix: Container(
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: Color(0xFF4A90E2), size: 20),
          ),
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          placeholderStyle: TextStyle(color: Color(0xFF718096), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildUpdatedAddressSection() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.briefcase_fill, color: Color(0xFF4A90E2), size: 20),
            SizedBox(width: 8),
            Text(
              appLanguage.get('working_area'),
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          appLanguage.get('preferred_working_address'),
          style: TextStyle(color: Color(0xFF718096), fontSize: 14),
        ),
        SizedBox(height: 16),

        // Toggle between search and manual entry
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _useManualAddress = false;
                    _manualAddressController.clear();
                    _addressLine1Controller.clear();
                    _addressLine2Controller.clear();
                    _townController.clear();
                    _latitude = null;
                    _longitude = null;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: !_useManualAddress ? Color(0xFF4A90E2) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_useManualAddress ? Color(0xFF4A90E2) : Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        color: !_useManualAddress ? Colors.white : Color(0xFF718096),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        appLanguage.get('search_address'),
                        style: TextStyle(
                          color: !_useManualAddress ? Colors.white : Color(0xFF718096),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _useManualAddress = true;
                    _selectedAddress = null;
                    _postcodeController.clear();
                    _latitude = null;
                    _longitude = null;
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _useManualAddress ? Color(0xFF4A90E2) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _useManualAddress ? Color(0xFF4A90E2) : Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.pencil,
                        color: _useManualAddress ? Colors.white : Color(0xFF718096),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        appLanguage.get('enter_manually'),
                        style: TextStyle(
                          color: _useManualAddress ? Colors.white : Color(0xFF718096),
                          fontSize: MediaQuery.of(context).size.width * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Conditional content based on selected mode
        if (!_useManualAddress) ...[
          PostcodeSearchWidget(
            postcodeController: _postcodeController,
            placeholderText: appLanguage.get('postcode'),
            onAddressSelected: (latitude, longitude, address) {
              setState(() {
                _selectedAddress = address;
                _latitude = latitude;
                _longitude = longitude;
              });
            },
          ),
          if (_selectedAddress != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress!,
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Postcode field
              Text(
                appLanguage.get('postcode'),
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: CupertinoTextFormFieldRow(
                  controller: _manualAddressController,
                  placeholder: appLanguage.get('enter_postcode'),
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefix: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      CupertinoIcons.location_fill,
                      color: Color(0xFF4A90E2),
                      size: 18,
                    ),
                  ),
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  placeholderStyle: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 15,
                  ),
                  onChanged: (value) {
                    // Clear coordinates when postcode changes
                    setState(() {
                      _latitude = null;
                      _longitude = null;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),

              // Address Line 1
              Text(
                appLanguage.get('address_line_1'),
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: CupertinoTextFormFieldRow(
                  controller: _addressLine1Controller,
                  placeholder: appLanguage.get('house_number_and_street_name'),
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefix: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      CupertinoIcons.home,
                      color: Color(0xFF4A90E2),
                      size: 18,
                    ),
                  ),
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  placeholderStyle: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Address Line 2
              Text(
                appLanguage.get('address_line_2') + ' (' + appLanguage.get('optional') + ')',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: CupertinoTextFormFieldRow(
                  controller: _addressLine2Controller,
                  placeholder: appLanguage.get('apartment_suite_building'),
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefix: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      CupertinoIcons.building_2_fill,
                      color: Color(0xFF4A90E2),
                      size: 18,
                    ),
                  ),
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  placeholderStyle: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Town/City
              Text(
                appLanguage.get('town_city'),
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: CupertinoTextFormFieldRow(
                  controller: _townController,
                  placeholder: appLanguage.get('enter_town_or_city'),
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefix: Container(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      CupertinoIcons.map_fill,
                      color: Color(0xFF4A90E2),
                      size: 18,
                    ),
                  ),
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  placeholderStyle: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    _manualAddressController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _townController.dispose();
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