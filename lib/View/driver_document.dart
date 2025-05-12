import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons; // Only for icons not available in Cupertino
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Homepage/admin_approval.dart';

class DocumentRegistrationPage extends StatefulWidget {
  const DocumentRegistrationPage({Key? key}) : super(key: key);

  @override
  State<DocumentRegistrationPage> createState() => _DocumentRegistrationPageState();
}

class _DocumentRegistrationPageState extends State<DocumentRegistrationPage> {
  final ImagePicker _picker = ImagePicker();
  bool? _isBritishCitizen;
  bool _isLoading = false;
  
  // Store image files
  File? _idFront;
  File? _idBack;
  File? _passportFront;
  File? _passportBack;
  File? _rightToWorkUKFront;
  File? _rightToWorkUKBack;
  File? _addressProofFront;
  File? _addressProofBack;
  File? _vehicleInsuranceFront;
  File? _vehicleInsuranceBack;
  File? _drivingLicenseFront;
  File? _drivingLicenseBack;
  
  // Text controllers for document details
  final TextEditingController _identityDetailsController = TextEditingController();
  final TextEditingController _rightToWorkDetailsController = TextEditingController();
  final TextEditingController _addressDetailsController = TextEditingController();
  final TextEditingController _insuranceDetailsController = TextEditingController();
  final TextEditingController _licenseDetailsController = TextEditingController();
  
  // Track completion status
  Map<String, bool> _documentStatus = {
    'identity': false,
    'citizenship': false,
    'address': false,
    'insurance': false,
    'license': false,
  };

  // Blue and White Color Scheme
  final Color _primaryColor = CupertinoColors.systemBlue; // Main blue color
  final Color _backgroundColor = CupertinoColors.white; // White background
  final Color _accentColor = const Color(0xFF007AFF); // Slightly darker blue for accents
  final Color _completedColor = CupertinoColors.systemGreen; // Keep green for completed status
  final Color _textColor = CupertinoColors.black; // Black for text readability
  final Color _secondaryTextColor = CupertinoColors.systemGrey; // Grey for secondary text

  @override
  void initState() {
    super.initState();
    _fetchCitizenshipStatus();
  }
  
  @override
  void dispose() {
    // Dispose of controllers when the widget is removed
    _identityDetailsController.dispose();
    _rightToWorkDetailsController.dispose();
    _addressDetailsController.dispose();
    _insuranceDetailsController.dispose();
    _licenseDetailsController.dispose();
    super.dispose();
  }

  void _updateDocumentStatus() {
    setState(() {
      _documentStatus['identity'] = _idFront != null && _idBack != null;
      
      if (_isBritishCitizen != null) {
        _documentStatus['citizenship'] = _isBritishCitizen! 
            ? (_passportFront != null && _passportBack != null)
            : (_rightToWorkUKFront != null && _rightToWorkUKBack != null);
      }
      
      _documentStatus['address'] = _addressProofFront != null && _addressProofBack != null;
      _documentStatus['insurance'] = _vehicleInsuranceFront != null && _vehicleInsuranceBack != null;
      _documentStatus['license'] = _drivingLicenseFront != null && _drivingLicenseBack != null;
    });
  }

  Future<void> _fetchCitizenshipStatus() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) throw Exception('Access token not found');

      final response = await http.get(
        Uri.parse(ApiConfig.driverProfileUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _isBritishCitizen = responseData['is_british_citizen'] as bool?;
          if (_isBritishCitizen == null) {
            _isBritishCitizen = false; // Default to non-British if not specified
          }
        });
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error loading profile: ${e.toString()}');
      setState(() => _isBritishCitizen = false); // Default to non-British on error
    } finally {
      setState(() => _isLoading = false);
      _updateDocumentStatus();
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message, style: TextStyle(color: _textColor)),
        actions: [
          CupertinoDialogAction(
            child: Text('Retry', style: TextStyle(color: _accentColor)),
            onPressed: () {
              Navigator.pop(context);
              _fetchCitizenshipStatus();
            },
          ),
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: _accentColor)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message, style: TextStyle(color: _textColor)),
        actions: [
          CupertinoDialogAction(
          
            child: Text('OK', style: TextStyle(color: _accentColor)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (context) => const DocumentVerificationPendingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<File?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      _showErrorDialog('Error selecting image: ${e.toString()}');
      return null;
    }
  }

  void _promptForDetails(String documentType, Function(String) onSave) {
    TextEditingController tempController = TextEditingController();
    
    showCupertinoDialog(
  context: context,
  builder: (context) => CupertinoAlertDialog(
    title: Text(
      '${_getDocumentTitle(documentType)} Details',
      style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
    ),
    content: Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: CupertinoTextField(
        controller: tempController,
        placeholder: 'Enter document details',
        maxLines: 3,
        style: const TextStyle(color: CupertinoColors.black),
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    actions: [
      CupertinoDialogAction(
        child: const Text('Cancel', style: TextStyle(color: CupertinoColors.systemRed)),
        onPressed: () => Navigator.pop(context),
        isDestructiveAction: true,
      ),
      CupertinoDialogAction(
        child: const Text('Save', style: TextStyle(color: CupertinoColors.activeBlue)),
        onPressed: () {
          onSave(tempController.text);
          Navigator.pop(context);
        },
      ),
    ],
  ),
);

  }
  
  String _getDocumentTitle(String documentType) {
    switch (documentType) {
      case 'IDENTITY': return 'Identity';
      case 'RIGHT_TO_WORK': return 'Right to Work';
      case 'ADDRESS': return 'Address Proof';
      case 'INSURANCE': return 'Vehicle Insurance';
      case 'LICENSE': return 'Driving License';
      default: return 'Document';
    }
  }

  Future<bool> _uploadDocument({
    required String documentType,
    required File frontImage,
    required File backImage,
    required String details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) throw Exception('Access token not found');

      final uri = Uri.parse(ApiConfig.driverDocumentUrl);
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['document_type'] = documentType;
      
      switch (documentType) {
        case 'IDENTITY':
          request.fields['identity_details'] = details;
          break;
        case 'RIGHT_TO_WORK':
          request.fields['right_to_work_details'] = details;
          break;
        case 'ADDRESS':
          request.fields['address_details'] = details;
          break;
        case 'INSURANCE':
          request.fields['insurance_details'] = details;
          break;
        case 'LICENSE':
          request.fields['license_details'] = details;
          break;
      }
      
      request.files.add(await http.MultipartFile.fromPath('front_image', frontImage.path));
      request.files.add(await http.MultipartFile.fromPath('back_image', backImage.path));
      
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Upload success: $responseString');
        return true;
      }
      
      debugPrint('Upload failed: $responseString');
      return false;
    } catch (e) {
      debugPrint('Upload error: $e');
      return false;
    }
  }

  Future<void> _submitAllDocuments() async {
    setState(() => _isLoading = true);

    try {
      if (_idFront == null || _idBack == null) {
        throw Exception('Please upload both sides of your Proof of Identity');
      }

      if (_isBritishCitizen == null) {
        throw Exception('Citizenship status not loaded. Please try again.');
      }
      
      if (_identityDetailsController.text.isEmpty) {
        _promptForDetails('IDENTITY', (details) {
          _identityDetailsController.text = details;
          _submitAllDocuments();
        });
        setState(() => _isLoading = false);
        return;
      }

      List<Future<bool>> uploads = [
        _uploadDocument(
          documentType: 'IDENTITY',
          frontImage: _idFront!,
          backImage: _idBack!,
          details: _identityDetailsController.text,
        ),
      ];

      if (_isBritishCitizen!) {
        if (_passportFront == null || _passportBack == null) {
          throw Exception('Please upload both sides of your British Passport');
        }
        
        if (_rightToWorkDetailsController.text.isEmpty) {
          _promptForDetails('RIGHT_TO_WORK', (details) {
            _rightToWorkDetailsController.text = details;
            _submitAllDocuments();
          });
          setState(() => _isLoading = false);
          return;
        }
        
        uploads.add(
          _uploadDocument(
            documentType: 'RIGHT_TO_WORK',
            frontImage: _passportFront!,
            backImage: _passportBack!,
            details: _rightToWorkDetailsController.text,
          ),
        );
      } else {
        if (_rightToWorkUKFront == null || _rightToWorkUKBack == null) {
          throw Exception('Please upload both sides of your Right to Work document');
        }
        
        if (_rightToWorkDetailsController.text.isEmpty) {
          _promptForDetails('RIGHT_TO_WORK', (details) {
            _rightToWorkDetailsController.text = details;
            _submitAllDocuments();
          });
          setState(() => _isLoading = false);
          return;
        }
        
        uploads.add(
          _uploadDocument(
            documentType: 'RIGHT_TO_WORK',
            frontImage: _rightToWorkUKFront!,
            backImage: _rightToWorkUKBack!,
            details: _rightToWorkDetailsController.text,
          ),
        );
      }

      if (_addressProofFront != null && _addressProofBack != null) {
        if (_addressDetailsController.text.isEmpty) {
          _promptForDetails('ADDRESS', (details) {
            _addressDetailsController.text = details;
            _submitAllDocuments();
          });
          setState(() => _isLoading = false);
          return;
        }
        
        uploads.add(
          _uploadDocument(
            documentType: 'ADDRESS',
            frontImage: _addressProofFront!,
            backImage: _addressProofBack!,
            details: _addressDetailsController.text,
          ),
        );
      }

      if (_vehicleInsuranceFront != null && _vehicleInsuranceBack != null) {
        if (_insuranceDetailsController.text.isEmpty) {
          _promptForDetails('INSURANCE', (details) {
            _insuranceDetailsController.text = details;
            _submitAllDocuments();
          });
          setState(() => _isLoading = false);
          return;
        }
        
        uploads.add(
          _uploadDocument(
            documentType: 'INSURANCE',
            frontImage: _vehicleInsuranceFront!,
            backImage: _vehicleInsuranceBack!,
            details: _insuranceDetailsController.text,
          ),
        );
      }

      if (_drivingLicenseFront != null && _drivingLicenseBack != null) {
        if (_licenseDetailsController.text.isEmpty) {
          _promptForDetails('LICENSE', (details) {
            _licenseDetailsController.text = details;
            _submitAllDocuments();
          });
          setState(() => _isLoading = false);
          return;
        }
        
        uploads.add(
          _uploadDocument(
            documentType: 'LICENSE',
            frontImage: _drivingLicenseFront!,
            backImage: _drivingLicenseBack!,
            details: _licenseDetailsController.text,
          ),
        );
      }

      final results = await Future.wait(uploads);
      if (results.contains(false)) {
        throw Exception('Some documents failed to upload. Please try again.');
      }

      _showSuccessDialog('All documents submitted successfully!');
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProgressIndicator() {
    final completedDocs = _documentStatus.values.where((v) => v).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Completion',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$completedDocs/${_documentStatus.length}',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoActivityIndicator.partiallyRevealed(
            progress: completedDocs / _documentStatus.length,
            color: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required File? frontFile,
    required File? backFile,
    required Function(File?) onFrontUploaded,
    required Function(File?) onBackUploaded,
    bool isRequired = true,
    TextEditingController? detailsController,
    String documentType = '',
  }) {
    final isComplete = frontFile != null && backFile != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? _completedColor : _accentColor.withOpacity(0.5),
          width: isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isComplete ? _completedColor : _accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isComplete ? CupertinoIcons.checkmark_alt : icon,
                    color: _backgroundColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _completedColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Complete',
                      style: TextStyle(
                        color: _completedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildImageUpload(
                  label: 'Front',
                  file: frontFile,
                  onPressed: () async {
                    final file = await _pickImage();
                    if (file != null) {
                      onFrontUploaded(file);
                      _updateDocumentStatus();
                    }
                  },
                ),
                const SizedBox(width: 16),
                _buildImageUpload(
                  label: 'Back',
                  file: backFile,
                  onPressed: () async {
                    final file = await _pickImage();
                    if (file != null) {
                      onBackUploaded(file);
                      _updateDocumentStatus();
                    }
                  },
                ),
              ],
            ),
            if (detailsController != null && isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Details',
                      style: TextStyle(color: _textColor, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: detailsController,
                      placeholder: 'Enter document details',
                      maxLines: 3,
                      style: TextStyle(color: _textColor),
                      placeholderStyle: TextStyle(color: _secondaryTextColor),
                      decoration: BoxDecoration(
                        border: Border.all(color: _accentColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                        color: _backgroundColor,
                      ),
                    ),
                    if (detailsController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Add Details',
                            style: TextStyle(color: _accentColor),
                          ),
                          onPressed: () => _promptForDetails(
                            documentType, 
                            (details) => setState(() => detailsController.text = details)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload({
    required String label,
    required File? file,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: file != null ? null : _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: file != null ? _accentColor : _accentColor.withOpacity(0.5),
            ),
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(file, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo, size: 32, color: _accentColor),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(color: _textColor),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Document Registrations',
          style: TextStyle(color: _textColor),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.refresh, color: _accentColor),
          onPressed: _fetchCitizenshipStatus,
        ),
        backgroundColor: _backgroundColor,
        border: Border(bottom: BorderSide(color: _accentColor.withOpacity(0.2))),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          color: _backgroundColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Document Verification',
                                style: TextStyle(
                                  color: _backgroundColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload all required documents',
                                style: TextStyle(
                                  color: _backgroundColor.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildProgressIndicator(),
                  Text(
                    'Required Documents',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDocumentCard(
                    title: 'Proof of Identity',
                    icon: CupertinoIcons.person_alt_circle,
                    frontFile: _idFront,
                    backFile: _idBack,
                    onFrontUploaded: (file) => setState(() => _idFront = file),
                    onBackUploaded: (file) => setState(() => _idBack = file),
                    isRequired: true,
                    detailsController: _identityDetailsController,
                    documentType: 'IDENTITY',
                  ),
                  if (_isBritishCitizen == null)
                    Center(child: CupertinoActivityIndicator(color: _accentColor))
                  else if (_isBritishCitizen!)
                    _buildDocumentCard(
                      title: 'British Passport',
                      icon: CupertinoIcons.airplane,
                      frontFile: _passportFront,
                      backFile: _passportBack,
                      onFrontUploaded: (file) => setState(() => _passportFront = file),
                      onBackUploaded: (file) => setState(() => _passportBack = file),
                      isRequired: true,
                      detailsController: _rightToWorkDetailsController,
                      documentType: 'RIGHT_TO_WORK',
                    )
                  else
                    _buildDocumentCard(
                      title: 'Right to Work in UK',
                      icon: CupertinoIcons.briefcase,
                      frontFile: _rightToWorkUKFront,
                      backFile: _rightToWorkUKBack,
                      onFrontUploaded: (file) => setState(() => _rightToWorkUKFront = file),
                      onBackUploaded: (file) => setState(() => _rightToWorkUKBack = file),
                      isRequired: true,
                      detailsController: _rightToWorkDetailsController,
                      documentType: 'RIGHT_TO_WORK',
                    ),
                  Text(
                    'Additional Documents',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDocumentCard(
                    title: 'Proof of Address',
                    icon: CupertinoIcons.home,
                    frontFile: _addressProofFront,
                    backFile: _addressProofBack,
                    onFrontUploaded: (file) => setState(() => _addressProofFront = file),
                    onBackUploaded: (file) => setState(() => _addressProofBack = file),
                    isRequired: false,
                    detailsController: _addressDetailsController,
                    documentType: 'ADDRESS',
                  ),
                  _buildDocumentCard(
                    title: 'Vehicle Insurance',
                    icon: CupertinoIcons.car_detailed,
                    frontFile: _vehicleInsuranceFront,
                    backFile: _vehicleInsuranceBack,
                    onFrontUploaded: (file) => setState(() => _vehicleInsuranceFront = file),
                    onBackUploaded: (file) => setState(() => _vehicleInsuranceBack = file),
                    isRequired: false,
                    detailsController: _insuranceDetailsController,
                    documentType: 'INSURANCE',
                  ),
                  _buildDocumentCard(
                    title: 'Driving License',
                    icon: CupertinoIcons.car,
                    frontFile: _drivingLicenseFront,
                    backFile: _drivingLicenseBack,
                    onFrontUploaded: (file) => setState(() => _drivingLicenseFront = file),
                    onBackUploaded: (file) => setState(() => _drivingLicenseBack = file),
                    isRequired: false,
                    detailsController: _licenseDetailsController,
                    documentType: 'LICENSE',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        child: _isLoading
                            ? CupertinoActivityIndicator(color: _backgroundColor)
                            : Text(
                                'Submit Documents',
                                style: TextStyle(color: _backgroundColor),
                              ),
                        onPressed: _submitAllDocuments,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: _textColor.withOpacity(0.5),
                child: Center(
                  child: CupertinoAlertDialog(
                    title: Text(
                      "Processing",
                      style: TextStyle(color: _textColor),
                    ),
                    content: CupertinoActivityIndicator(color: _accentColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}