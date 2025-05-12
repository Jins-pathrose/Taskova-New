import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Language/language_provider.dart';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Profile data
  Map<String, dynamic> _profileData = {};
  
  // Text controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  late AppLanguage appLanguage;

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
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
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out. Please check your connection.');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _profileData = data;
          // Initialize controllers with current data
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      } else {
        setState(() {
          try {
            final responseData = json.decode(response.body);
            if (responseData is Map<String, dynamic> && responseData.containsKey('detail')) {
              _errorMessage = responseData['detail'];
            } else {
              _errorMessage = 'Failed to fetch profile data. Status code: ${response.statusCode}';
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
        _isLoading = false;
      });
    }
  }
  
 Future<void> _updateProfile() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

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
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json', // Remove charset parameter
    };
    
    // Prepare data for update
    final data = {
      'name': _nameController.text,
      'phone_number': _phoneController.text,
      'email': _emailController.text,
      'address': _addressController.text,
    };
    
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(data),
    ).timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Request timed out. Please check your connection.');
      },
    );
    
    if (response.statusCode == 200) {
      _showSuccessDialog('Profile updated successfully!');
      _fetchProfileData(); // Refresh the profile data
      setState(() {
        _isEditing = false;
      });
    } else {
      setState(() {
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic> && responseData.containsKey('detail')) {
            _errorMessage = responseData['detail'];
          } else {
            _errorMessage = 'Failed to update profile. Status code: ${response.statusCode}';
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



  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(appLanguage.get('success')),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(appLanguage.get('ok')),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with icon
          Icon(
            CupertinoIcons.person_circle,
            size: 100,
            color: CupertinoColors.activeBlue,
          ),
          
          SizedBox(height: 24),
          
          // Name
          _buildInfoCard(
            title: appLanguage.get('name'),
            value: _profileData['name'] ?? appLanguage.get('not_specified'),
            icon: CupertinoIcons.person,
          ),
          
          SizedBox(height: 16),
          
          // Email
          _buildInfoCard(
            title: appLanguage.get('email'),
            value: _profileData['email'] ?? appLanguage.get('not_specified'),
            icon: CupertinoIcons.mail,
          ),
          
          SizedBox(height: 16),
          
          // Phone
          _buildInfoCard(
            title: appLanguage.get('phone_number'),
            value: _profileData['phone_number'] ?? appLanguage.get('not_specified'),
            icon: CupertinoIcons.phone,
          ),
          
          SizedBox(height: 16),
          
          // Address
          _buildInfoCard(
            title: appLanguage.get('address'),
            value: _profileData['address'] ?? appLanguage.get('not_specified'),
            icon: CupertinoIcons.home,
          ),
          
          SizedBox(height: 30),
          
          // Edit Button
          // CupertinoButton.filled(
          //   child: Text(appLanguage.get('edit_profile')),
          //   onPressed: () {
          //     setState(() {
          //       _isEditing = true;
          //     });
          //   },
          // ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.activeBlue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.destructiveRed),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLanguage.get('update_failed'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: CupertinoColors.destructiveRed),
                    ),
                  ],
                ),
              ),
            
            // Header icon
            Icon(
              CupertinoIcons.person_circle,
              size: 100,
              color: CupertinoColors.activeBlue,
            ),
            
            SizedBox(height: 30),
            
            // Name Field
            CupertinoFormRow(
              child: CupertinoTextFormFieldRow(
                controller: _nameController,
                placeholder: appLanguage.get('name'),
                prefix: Icon(CupertinoIcons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLanguage.get('please_enter_name');
                  }
                  return null;
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Email Field
            CupertinoFormRow(
              child: CupertinoTextFormFieldRow(
                controller: _emailController,
                placeholder: appLanguage.get('email'),
                prefix: Icon(CupertinoIcons.mail),
                keyboardType: TextInputType.emailAddress,
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
            
            SizedBox(height: 16),
            
            // Phone Number Field
            CupertinoFormRow(
              child: CupertinoTextFormFieldRow(
                controller: _phoneController,
                placeholder: appLanguage.get('phone_number'),
                prefix: Icon(CupertinoIcons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLanguage.get('please_enter_phone_number');
                  }
                  return null;
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Address Field
            CupertinoFormRow(
              child: CupertinoTextFormFieldRow(
                controller: _addressController,
                placeholder: appLanguage.get('address'),
                prefix: Icon(CupertinoIcons.home),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLanguage.get('please_enter_address');
                  }
                  return null;
                },
              ),
            ),
            
            SizedBox(height: 30),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: CupertinoColors.systemGrey5,
                    child: Text(
                      appLanguage.get('cancel'),
                      style: TextStyle(color: CupertinoColors.systemBlue),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _errorMessage = null;
                        // Reset controllers to current values
                        _nameController.text = _profileData['name'] ?? '';
                        _phoneController.text = _profileData['phone_number'] ?? '';
                        _emailController.text = _profileData['email'] ?? '';
                        _addressController.text = _profileData['address'] ?? '';
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton.filled(
                    child: Text(appLanguage.get('save')),
                    onPressed: _updateProfile,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(appLanguage.get('profile')),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(height: 16),
                    Text(
                      appLanguage.get('loading_profile'),
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                    ),
                  ],
                ),
              )
            : _isSubmitting
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(),
                        SizedBox(height: 16),
                        Text(
                          appLanguage.get('updating_profile'),
                          style: CupertinoTheme.of(context).textTheme.textStyle,
                        ),
                      ],
                    ),
                  )
                : _isEditing
                    ? _buildEditForm()
                    : _buildProfileView(),
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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