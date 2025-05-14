import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For icons and Colors not available in Cupertino
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/postcode.dart';
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

  // Define blue and white color scheme
  final Color primaryBlue = Color(0xFF1A5DC1); // Primary blue color
  final Color lightBlue = Color(0xFFE6F0FF); // Light blue for backgrounds
  final Color accentBlue = Color(0xFF0E4DA4); // Darker blue for accents
  final Color whiteColor = CupertinoColors.white;

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
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

  Future<void> _searchByPostcode(String postcode) async {
    if (postcode.isEmpty) return;

    setState(() {
      _isSearching = true;
      _selectedAddress = null;
      _latitude = null;
      _longitude = null;
    });

    try {
      List<Location> locations = await locationFromAddress(postcode);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          setState(() {
            _selectedAddress =
                '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}';
            _latitude = location.latitude;
            _longitude = location.longitude;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Error searching postcode: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _submitMultipartForm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse(ApiConfig.driverProfileUrl);
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      });

      request.fields['name'] = _nameController.text;
      request.fields['phone_number'] = _phoneController.text;
      request.fields['email'] = _emailController.text;
      request.fields['address'] = _selectedHomeAddress ?? '';
      request.fields['preferred_working_address'] = _selectedAddress ?? '';
      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();
      request.fields['is_british_citizen'] =
          _isBritishCitizen ? 'true' : 'false';
      request.fields['has_criminal_history'] =
          _hasCriminalHistory ? 'true' : 'false';
      request.fields['has_disability'] = _hasDisability ? 'true' : 'false';

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog('Profile registered successfully!');
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

      await _submitMultipartForm();
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Brightness.light,
            ),
            child: CupertinoAlertDialog(
              title: Text(
                appLanguage.get('Please submit all required fields'),
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
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: whiteColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: primaryBlue,
        middle: Text(
          appLanguage.get('profile_registration'),
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
      ),
      child:
          _isSubmitting
              ? Container(
                color: whiteColor,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(
                        color: primaryBlue,
                        radius: 15,
                      ),
                      SizedBox(height: 16),
                      Text(
                        appLanguage.get('submitting_profile_information'),
                        style: TextStyle(color: primaryBlue, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
              : Container(
                color: whiteColor,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                  appLanguage.get('registration_failed'),
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

                        // Profile Picture
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: lightBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryBlue,
                                    width: 3,
                                  ),
                                  image:
                                      _imageFile != null
                                          ? DecorationImage(
                                            image: FileImage(_imageFile!),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                ),
                                child:
                                    _imageFile == null
                                        ? Icon(
                                          CupertinoIcons.person_solid,
                                          size: 70,
                                          color: primaryBlue,
                                        )
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: whiteColor,
                                        width: 2,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      CupertinoIcons.camera_fill,
                                      color: whiteColor,
                                      size: 20,
                                    ),
                                  ),
                                  onPressed:
                                      () => _getImage(ImageSource.camera),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // Form Fields in Blue and White
                        _buildFormField(
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

                        SizedBox(height: 16),

                        _buildFormField(
                          controller: _emailController,
                          placeholder: appLanguage.get('email'),
                          icon: CupertinoIcons.mail,
                          keyboardType: TextInputType.emailAddress,
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
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Home Address Section
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
                                appLanguage.get('home_address'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Home Address Postcode Search Widget
                              PostcodeSearchWidget(
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

                              SizedBox(height: 16),

                              // Display Selected Home Address
                              if (_selectedHomeAddress != null)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primaryBlue.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appLanguage.get(
                                          'selected_home_address',
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _selectedHomeAddress!,
                                        style: TextStyle(color: accentBlue),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Toggle Switches with Blue Theme
                        _buildToggleRow(
                          text: appLanguage.get('are_u_british'),
                          value: _isBritishCitizen,
                          onChanged: (value) {
                            setState(() {
                              _isBritishCitizen = value;
                            });
                          },
                        ),

                        SizedBox(height: 16),

                        _buildToggleRow(
                          text: appLanguage.get('criminal_record'),
                          value: _hasCriminalHistory,
                          onChanged: (value) {
                            setState(() {
                              _hasCriminalHistory = value;
                            });
                          },
                        ),

                        SizedBox(height: 16),

                        _buildToggleRow(
                          text: appLanguage.get('has_disability'),
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
                          Text(
                            appLanguage.get('disability_certificate'),
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          _disabilityCertificateFile != null
                              ? Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primaryBlue.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc,
                                      size: 40,
                                      color: primaryBlue,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _disabilityCertificateFile!.path
                                            .split('/')
                                            .last,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: primaryBlue),
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        CupertinoIcons.trash,
                                        color: CupertinoColors.destructiveRed,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _disabilityCertificateFile = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                              : Row(
                                children: [
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      color: primaryBlue,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Text(
                                        appLanguage.get('upload_certificate'),
                                        style: TextStyle(color: whiteColor),
                                      ),
                                      onPressed:
                                          () => _getImage(
                                            ImageSource.gallery,
                                            isDisabilityCertificate: true,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                        ],

                        SizedBox(height: 24),

                        // Preferred Working Area Section
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
                                appLanguage.get('working_area'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Working Area Postcode Search
                              PostcodeSearchWidget(
                                postcodeController: _postcodeController,
                                placeholderText: appLanguage.get('postcode'),
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

                              SizedBox(height: 16),

                              // Display Selected Working Address
                              if (_selectedAddress != null)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primaryBlue.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appLanguage.get(
                                          'selected_working_area',
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _selectedAddress!,
                                        style: TextStyle(color: accentBlue),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // Submit Button
                        CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          child: Text(
                            appLanguage.get('confirm').toUpperCase(),
                            style: TextStyle(
                              color: whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: _submitForm,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // Helper widget for creating consistent form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightBlue,
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
          maxLines: maxLines,
          style: TextStyle(color: primaryBlue),
          placeholderStyle: TextStyle(color: primaryBlue.withOpacity(0.7)),
          decoration: BoxDecoration(color: Colors.transparent),
          validator: validator,
        ),
      ),
    );
  }

  // Helper widget for creating consistent toggle rows
  Widget _buildToggleRow({
    required String text,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryBlue,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
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
