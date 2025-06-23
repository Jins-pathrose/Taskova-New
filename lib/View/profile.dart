import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For icons and Colors not available in Cupertino
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/postcode.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class ProfileRegistrationPage extends StatefulWidget {
  @override
  _ProfileRegistrationPageState createState() =>
      _ProfileRegistrationPageState();
}

class _ProfileRegistrationPageState extends State<ProfileRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _customExperienceController =
      TextEditingController();

  bool _isBritishCitizen = false;
  bool _hasCriminalHistory = false;
  bool _hasDisability = false;
  File? _imageFile;
  File? _disabilityCertificateFile;
  final picker = ImagePicker();

  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  late AppLanguage appLanguage;
  String? _selectedHomeAddress;
  double? _homeLatitude;
  double? _homeLongitude;
  bool _formSubmittedSuccessfully = false;
  String? _selectedExperienceType;
  String? _selectedDrivingDuration;
  bool _isCustomExperienceSelected = false;
  // Experience types options based on Django model
  final List<Map<String, String>> _experienceTypeOptions = [
    {
      'value': 'food_delivery',
      'label': 'Food delivery (Uber Eats, Just Eat, etc.)',
    },
    {
      'value': 'parcel_delivery',
      'label': 'Parcel or courier delivery (Amazon, Evri, etc.)',
    },
    {'value': 'freelance', 'label': 'Freelance/delivery for local shops'},
    {
      'value': 'friends_family',
      'label': 'I help friends and family with deliveries',
    },
    {
      'value': 'no_experience',
      'label': 'No experience yet — but ready to roll!',
    },
    {'value': 'custom', 'label': 'Other (specify)'},
  ];

  // Driving duration options based on Django model
  final List<Map<String, String>> _drivingDurationOptions = [
    {'value': '0-1', 'label': 'Less than 1 year'},
    {'value': '1-2', 'label': '1–2 years'},
    {'value': '3-5', 'label': '3–5 years'},
    {'value': '5+', 'label': '5+ years'},
  ];

  // Updated color scheme
  final Color primaryBlue = Color(0xFF1565C0); // Deep blue
  final Color lightBlue = Color(0xFFE3F2FD); // Very light blue
  final Color whiteColor = Colors.white; // Pure white
  final Color accentBlue = Color(0xFF42A5F5); // Lighter blue for accents

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _loadSavedUserData();
  }

  Future<bool> _onWillPop() async {
    if (_formSubmittedSuccessfully) return true;

    final shouldExit = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(appLanguage.get('Exit_Profile_Registration?')),
            content: Text(
              'Are you sure you want to exit? Your progress will be lost.',
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(appLanguage.get('cancel')),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                child: Text(appLanguage.get('exit')),
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (shouldExit ?? false) {
      await _clearAccessToken();
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  Future<void> _loadSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    final savedName = prefs.getString('user_name');

    setState(() {
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
      _phoneController.text = '+44 ';
    });
  }

  bool _isValidUKPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('+44', '');
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return false;
    }
    return RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
  }

  Future<void> _getImage(
    ImageSource source, {
    bool isDisabilityCertificate = false,
  }) async {
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    setState(() {
      if (pickedFile != null) {
        if (isDisabilityCertificate) {
          _disabilityCertificateFile = File(pickedFile.path);
        } else {
          _imageFile = File(pickedFile.path);
        }
      }
    });
  }

  Future<void> _submitMultipartForm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final url = Uri.parse(ApiConfig.driverProfileUrl);
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      });

      request.fields['name'] = _nameController.text;
      request.fields['phone_number'] = _phoneController.text;
      // request.fields['email'] = _emailController.text;
      request.fields['address'] = _selectedHomeAddress ?? '';
      request.fields['preferred_working_address'] = _selectedAddress ?? '';
      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();
      request.fields['is_british_citizen'] =
          _isBritishCitizen ? 'true' : 'false';
      request.fields['has_criminal_history'] =
          _hasCriminalHistory ? 'true' : 'false';
      request.fields['has_disability'] = _hasDisability ? 'true' : 'false';
      request.fields['experience_types'] = jsonEncode(
        _selectedExperienceType == 'custom'
            ? [_customExperienceController.text]
            : [_selectedExperienceType],
      );
      request.fields['driving_duration'] = _selectedDrivingDuration ?? '';

      if (_imageFile != null) {
        final fileName = _imageFile!.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();

        final multipartFile = await http.MultipartFile.fromPath(
          'profile_picture',
          _imageFile!.path,
          contentType: MediaType('image', extension),
          filename: fileName,
        );

        request.files.add(multipartFile);
      }
      if (_hasDisability && _disabilityCertificateFile != null) {
        final fileName = _disabilityCertificateFile!.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();

        final multipartFile = await http.MultipartFile.fromPath(
          'disability_certificate',
          _disabilityCertificateFile!.path,
          contentType: MediaType('image', extension),
          filename: fileName,
        );

        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Request timed out. Please check your connection.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
    await _clearAccessToken();
    if (mounted) {  // Check if widget is still in the tree
        Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
        );
    }
    return;
}

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text);

        setState(() {
          _formSubmittedSuccessfully = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => const MainWrapper()),
            (Route<dynamic> route) => false,
          );
        });
        _showSuccessDialog(appLanguage.get('Profile_registered_successfully!'));
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
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        _showErrorDialog(appLanguage.get('select_profile_picture'));
        return;
      }

      if (_selectedAddress == null || _latitude == null || _longitude == null) {
        _showErrorDialog(appLanguage.get('select_working_area'));
        return;
      }

      if (_hasDisability && _disabilityCertificateFile == null) {
        _showErrorDialog(
          appLanguage.get('please_upload_disability_certificate'),
        );
        return;
      }

      if (_selectedExperienceType == null) {
        _showErrorDialog(appLanguage.get('Please_select_an_experience_type'));
        return;
      }

      if (_selectedDrivingDuration == null) {
        _showErrorDialog(appLanguage.get('Please_select_driving_duration'));
        return;
      }

      await _submitMultipartForm();
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
                appLanguage.get('Please_submit_all_required_fields'),
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
  void dispose() {
    if (!_formSubmittedSuccessfully) {
      _clearAccessToken();
    }
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _customExperienceController.dispose();
    super.dispose();
  }

  Future<void> _clearAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
    } catch (e) {
      print('Error clearing access token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        backgroundColor: Color(0xFFF8F9FA),
        child: Column(
          children: [
            // Modern header with gradient
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
                        onPressed: () async {
                          if (await _onWillPop()) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguage.get('profile_registration'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              appLanguage.get('Complete_your_profile_to_get_started'),
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
              child:
                  _isSubmitting
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
                                    appLanguage.get(
                                      'submitting_profile_information',
                                    ),
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
                            // Profile Image Section
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
                              child: Column(
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
                                            CupertinoIcons
                                                .exclamationmark_circle_fill,
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

                                  // Profile image
                                  Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient:
                                              _imageFile == null
                                                  ? LinearGradient(
                                                    colors: [
                                                      Color(
                                                        0xFF4A90E2,
                                                      ).withOpacity(0.1),
                                                      Color(
                                                        0xFF357ABD,
                                                      ).withOpacity(0.1),
                                                    ],
                                                  )
                                                  : null,
                                          image:
                                              _imageFile != null
                                                  ? DecorationImage(
                                                    image: FileImage(
                                                      _imageFile!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : null,
                                          border: Border.all(
                                            color: Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child:
                                            _imageFile == null
                                                ? Icon(
                                                  CupertinoIcons.person_fill,
                                                  size: 32,
                                                  color: Color(
                                                    0xFF4A90E2,
                                                  ).withOpacity(0.6),
                                                )
                                                : null,
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: GestureDetector(
                                          onTap:
                                              () =>
                                                  _getImage(ImageSource.camera),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF4A90E2),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(
                                                    0xFF4A90E2,
                                                  ).withOpacity(0.2),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              CupertinoIcons.camera_fill,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    appLanguage.get('Profile_Photo'),
                                    style: TextStyle(
                                      color: Color(0xFF2D3748),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    appLanguage.get('Add_a_photo_to_personalize_your_profile'),
                                    style: TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Form Container
                            Container(
                              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                    // Personal Information Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons.person_2_fill,
                                            color: Color(0xFF4A90E2),
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          appLanguage.get('Personal_Information'),
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
                                          return appLanguage.get(
                                            'please_enter_name',
                                          );
                                        }
                                        if (!RegExp(
                                          r'^[a-zA-Z\s]+$',
                                        ).hasMatch(value)) {
                                          return appLanguage.get(
                                            'name_must_contain_only_alphabets',
                                          );
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
                                      label: appLanguage.get(
                                        'phone_number',
                                      ),
                                      placeholder: appLanguage.get(
                                        'phone_number',
                                      ),
                                      icon: CupertinoIcons.phone_fill,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return appLanguage.get(
                                            'please_enter_phone_number',
                                          );
                                        }
                                        if (!_isValidUKPhoneNumber(value)) {
                                          return appLanguage.get('Please_enter_a_valid_UK_phone_number');
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (!value.startsWith('+44')) {
                                          _phoneController.text =
                                              '+44 ' +
                                              value
                                                  .replaceAll('+44', '')
                                                  .trim();
                                          _phoneController.selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset:
                                                      _phoneController
                                                          .text
                                                          .length,
                                                ),
                                              );
                                        }
                                      },
                                    ),
                                    SizedBox(height: 24),

                                    // Address Section
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons.location_fill,
                                            color: Color(0xFF4A90E2),
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          appLanguage.get('Address_Information'),
                                          style: TextStyle(
                                            color: Color(0xFF2D3748),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),

                                    // Home Address
                                    _buildAddressSection(
                                      title: appLanguage.get('Home_Address'),
                                      subtitle: appLanguage.get('Your_residential_address'),
                                      icon: CupertinoIcons.house_fill,
                                      child: PostcodeSearchWidget(
                                        placeholderText: appLanguage.get(
                                          'home_postcode',
                                        ),
                                        onAddressSelected: (
                                          latitude,
                                          longitude,
                                          address,
                                        ) {
                                          setState(() {
                                            _selectedHomeAddress = address;
                                            _homeLatitude = latitude;
                                            _homeLongitude = longitude;
                                          });
                                        },
                                      ),
                                      selectedAddress: _selectedHomeAddress,
                                    ),
                                    SizedBox(height: 16),

                                    // Working Area
                                    _buildAddressSection(
                                      title: appLanguage.get('Workinga-Area'),
                                      subtitle: appLanguage.get('preferred_working_address'),
                                      icon: CupertinoIcons.briefcase_fill,
                                      child: PostcodeSearchWidget(
                                        postcodeController: _postcodeController,
                                        placeholderText: appLanguage.get(
                                          'postcode',
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
                                          });
                                        },
                                      ),
                                      selectedAddress: _selectedAddress,
                                    ),
                                    SizedBox(height: 24),

                                    // Experience Section
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons.star_fill,
                                            color: Color(0xFF4A90E2),
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          appLanguage.get('Experience&Skills'),
                                          style: TextStyle(
                                            color: Color(0xFF2D3748),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),

                                    // Delivery Experience
                                    Text(
                                      appLanguage.get('Delivery_Experience'),
                                      style: TextStyle(
                                        color: Color(0xFF2D3748),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      appLanguage.get('Select_your_experience_level'),
                                      style: TextStyle(
                                        color: Color(0xFF718096),
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 10),

                                    // Experience Options
                                    ..._experienceTypeOptions.map((option) {
                                      final isSelected =
                                          _selectedExperienceType ==
                                          option['value'];
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedExperienceType =
                                                option['value'];
                                            _isCustomExperienceSelected =
                                                option['value'] == 'custom';
                                            if (!_isCustomExperienceSelected) {
                                              _customExperienceController
                                                  .clear();
                                            }
                                          });
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(bottom: 10),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Color(
                                                      0xFF4A90E2,
                                                    ).withOpacity(0.1)
                                                    : Color(0xFFF7FAFC),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? Color(0xFF4A90E2)
                                                      : Color(0xFFE2E8F0),
                                              width: isSelected ? 1.5 : 0.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 6,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      isSelected
                                                          ? Color(0xFF4A90E2)
                                                          : Colors.transparent,
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? Color(0xFF4A90E2)
                                                            : Color(0xFFCBD5E0),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child:
                                                    isSelected
                                                        ? Icon(
                                                          CupertinoIcons
                                                              .checkmark,
                                                          color: Colors.white,
                                                          size: 10,
                                                        )
                                                        : null,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  option['label']!,
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
                                      );
                                    }).toList(),

                                    if (_isCustomExperienceSelected) ...[
                                      SizedBox(height: 8),
                                      _buildModernTextField(
                                        controller: _customExperienceController,
                                        label: appLanguage.get('Custom_Experience'),
                                        placeholder: appLanguage.get('Specify_your_experience'),
                                        icon: CupertinoIcons.textbox,
                                        validator: (value) {
                                          if (_selectedExperienceType ==
                                                  'custom' &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return appLanguage.get('Please_specify_custom_experience');
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    SizedBox(height: 16),

                                    // Driving Experience
                                    Text(
                                      appLanguage.get('Driving_Experience'),
                                      style: TextStyle(
                                        color: Color(0xFF2D3748),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      appLanguage.get('How_long_have_you_been_driving?'),
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
                                          builder:
                                              (context) => CupertinoActionSheet(
                                                title: Text(
                                                  'Driving Experience',
                                                  style: TextStyle(
                                                    color: Color(0xFF2D3748),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                actions:
                                                    _drivingDurationOptions
                                                        .map(
                                                          (
                                                            option,
                                                          ) => CupertinoActionSheetAction(
                                                            child: Text(
                                                              option['label']!,
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF4A90E2,
                                                                ),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                _selectedDrivingDuration =
                                                                    option['value'];
                                                              });
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            },
                                                          ),
                                                        )
                                                        .toList(),
                                                cancelButton:
                                                    CupertinoActionSheetAction(
                                                      child: Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                          color:
                                                              CupertinoColors
                                                                  .destructiveRed,
                                                        ),
                                                      ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                              ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF7FAFC),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Color(0xFFE2E8F0),
                                            width: 0.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.04,
                                              ),
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
                                                    ? 'Select driving duration'
                                                    : _drivingDurationOptions
                                                        .firstWhere(
                                                          (option) =>
                                                              option['value'] ==
                                                              _selectedDrivingDuration,
                                                        )['label']!,
                                                style: TextStyle(
                                                  color:
                                                      _selectedDrivingDuration ==
                                                              null
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

                                    // Background & Eligibility
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF4A90E2,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons
                                                .checkmark_shield_fill,
                                            color: Color(0xFF4A90E2),
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Background & Eligibility',
                                          style: TextStyle(
                                            color: Color(0xFF2D3748),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),

                                    // Toggle Questions
                                    _buildModernToggle(
                                      title: 'British Citizenship',
                                      question: appLanguage.get(
                                        'are_u_british',
                                      ),
                                      value: _isBritishCitizen,
                                      onChanged: (value) {
                                        setState(() {
                                          _isBritishCitizen = value;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 12),

                                    _buildModernToggle(
                                      title: 'Criminal History',
                                      question:
                                          'Have you ever been convicted of a criminal offence?',
                                      value: _hasCriminalHistory,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasCriminalHistory = value;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 12),

                                    _buildModernToggle(
                                      title: 'Accessibility Needs',
                                      question:
                                          'Do you have a disability or accessibility need?',
                                      value: _hasDisability,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasDisability = value;
                                          if (!value) {
                                            _disabilityCertificateFile = null;
                                          }
                                        });
                                      },
                                    ),

                                    // Disability Certificate Upload
                                    if (_hasDisability) ...[
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF0F8FF),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Color(0xFFBEE3F8),
                                            width: 0.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.04,
                                              ),
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  CupertinoIcons.doc_text_fill,
                                                  color: Color(0xFF4A90E2),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Disability Certificate',
                                                  style: TextStyle(
                                                    color: Color(0xFF2D3748),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Please upload your disability certificate',
                                              style: TextStyle(
                                                color: Color(0xFF718096),
                                                fontSize: 13,
                                              ),
                                            ),
                                            SizedBox(height: 12),

                                            _disabilityCertificateFile != null
                                                ? Container(
                                                  padding: EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFF7FAFC),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Color(0xFFE2E8F0),
                                                      width: 0.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.04),
                                                        blurRadius: 6,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        CupertinoIcons
                                                            .doc_checkmark,
                                                        color: Color(
                                                          0xFF10B981,
                                                        ),
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          _disabilityCertificateFile!
                                                              .path
                                                              .split('/')
                                                              .last,
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFF2D3748,
                                                            ),
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _disabilityCertificateFile =
                                                                null;
                                                          });
                                                        },
                                                        child: Icon(
                                                          CupertinoIcons
                                                              .xmark_circle_fill,
                                                          color: Color(
                                                            0xFFEF4444,
                                                          ),
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                                : GestureDetector(
                                                  onTap:
                                                      () => _getImage(
                                                        ImageSource.gallery,
                                                        isDisabilityCertificate:
                                                            true,
                                                      ),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF4A90E2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Color(
                                                            0xFF4A90E2,
                                                          ).withOpacity(0.2),
                                                          blurRadius: 6,
                                                          offset: Offset(0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          CupertinoIcons
                                                              .cloud_upload_fill,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Upload Certificate',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Submit Button
                            Container(
                              margin: EdgeInsets.fromLTRB(16, 0, 16, 32),
                              child: CupertinoButton(
                                onPressed: _submitForm,
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
                                        color: Color(
                                          0xFF4A90E2,
                                        ).withOpacity(0.2),
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
                                        'Complete Profile',
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

  // Helper method to build modern text fields
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

  // Helper method to build address sections
  Widget _buildAddressSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    String? selectedAddress,
  }) {
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
              Icon(icon, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 8),
              Text(
                title,
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
            subtitle,
            style: TextStyle(color: Color(0xFF718096), fontSize: 14),
          ),
          SizedBox(height: 16),
          child,
          if (selectedAddress != null) ...[
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
                      selectedAddress,
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
        ],
      ),
    );
  }

  // Helper method to build modern toggle switches
  Widget _buildModernToggle({
    required String title,
    required String question,
    required bool value,
    required void Function(bool) onChanged,
  }) {
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
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                ),
              ),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeColor: Color(0xFF4A90E2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    required bool readOnly,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CupertinoFormRow(
        child: CupertinoTextFormFieldRow(
          controller: controller,
          placeholder: placeholder,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefix: Container(
            margin: EdgeInsets.only(right: 12),
            child: Icon(icon, color: primaryBlue, size: 22),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            color: primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          placeholderStyle: TextStyle(
            color: primaryBlue.withOpacity(0.6),
            fontSize: 16,
          ),
          decoration: BoxDecoration(color: Colors.transparent),
          validator: validator,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
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
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: whiteColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String text,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              value
                  ? primaryBlue.withOpacity(0.5)
                  : primaryBlue.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: value ? primaryBlue : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: whiteColor, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: primaryBlue,
              trackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAddressCard({
    required String title,
    required String address,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.location_solid, color: primaryBlue, size: 18),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            address,
            style: TextStyle(color: primaryBlue, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
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