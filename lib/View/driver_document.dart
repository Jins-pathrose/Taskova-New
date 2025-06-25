import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/Model/image_compresser.dart';
import 'package:taskova_new/View/Homepage/admin_approval.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Staticpages/britishpassport.dart';
import 'package:taskova_new/View/Staticpages/driver_licence.dart';
import 'package:taskova_new/View/Staticpages/dvls.dart';
import 'package:taskova_new/View/Staticpages/proof_of_address.dart';
import 'package:taskova_new/View/Staticpages/proof_of_identity.dart';
import 'package:taskova_new/View/Staticpages/right_to_work.dart';
import 'package:taskova_new/View/Staticpages/vehicle_insurance.dart';

class DocumentRegistrationPage extends StatefulWidget {
  const DocumentRegistrationPage({Key? key}) : super(key: key);

  @override
  State<DocumentRegistrationPage> createState() =>
      _DocumentRegistrationPageState();
}

class _DocumentRegistrationPageState extends State<DocumentRegistrationPage> {
  final ImagePicker _picker = ImagePicker();
  bool? _isBritishCitizen;
  bool _isLoading = false;

  // Store image files
  File? _idImage;
  File? _passportFront;
  File? _passportBack;
  File? _rightToWorkImage;
  File? _addressProofImage;
  File? _vehicleInsuranceImage;
  File? _drivingLicenseFront;
  File? _drivingLicenseBack;
  File? _dvlsImage;

  // Text controllers for document details (optional)
  final TextEditingController _identityDetailsController =
      TextEditingController();
  final TextEditingController _rightToWorkDetailsController =
      TextEditingController();
  final TextEditingController _addressDetailsController =
      TextEditingController();
  final TextEditingController _insuranceDetailsController =
      TextEditingController();
  final TextEditingController _licenseDetailsController =
      TextEditingController();
  final TextEditingController _dvlaController = TextEditingController();

  // Track completion status
  Map<String, bool> _documentStatus = {
    'identity': false,
    'citizenship': false,
    'address': false,
    'insurance': false,
    'license': false,
    'dvla': false,
  };

  // Professional Color Scheme
  final Color _primaryColor = const Color(0xFF0A66C2); // LinkedIn blue
  final Color _backgroundColor = CupertinoColors.systemGroupedBackground;
  final Color _cardColor = CupertinoColors.white;
  final Color _successColor = const Color(0xFF057642); // Professional green
  final Color _warningColor = const Color(0xFFE16F24); // Professional orange
  final Color _textPrimary = const Color(0xFF000000);
  final Color _textSecondary = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFE0E0E0);
  late AppLanguage appLanguage;

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _fetchCitizenshipStatus();
  }

  @override
  void dispose() {
    _identityDetailsController.dispose();
    _rightToWorkDetailsController.dispose();
    _addressDetailsController.dispose();
    _insuranceDetailsController.dispose();
    _licenseDetailsController.dispose();
    _dvlaController.dispose();
    super.dispose();
  }

  void _updateDocumentStatus() {
    setState(() {
      _documentStatus['identity'] = _idImage != null;
      if (_isBritishCitizen != null) {
        _documentStatus['citizenship'] = _isBritishCitizen!
            ? (_passportFront != null && _passportBack != null)
            : (_rightToWorkImage != null);
      }
      _documentStatus['address'] = _addressProofImage != null;
      _documentStatus['insurance'] = _vehicleInsuranceImage != null;
      _documentStatus['license'] =
          _drivingLicenseFront != null && _drivingLicenseBack != null;
      _documentStatus['dvla'] = _dvlsImage != null;
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
          _isBritishCitizen =
              responseData['is_british_citizen'] as bool? ?? false;
        });
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error loading profile: ${e.toString()}');
      setState(() => _isBritishCitizen = false);
    } finally {
      setState(() => _isLoading = false);
      _updateDocumentStatus();
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Oops!'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: TextStyle(color: _textPrimary)),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: _primaryColor)),
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
        title:  Text(appLanguage.get('success')),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message, style: TextStyle(color: _textPrimary)),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              appLanguage.get('continue'),
             style: TextStyle(color: _primaryColor)),
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

   Future<File?> _pickImage(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(await image.readAsBytes());
        
        if (await tempFile.exists()) {
          // Compress the image to ~20KB
          final compressedFile = await ImageCompressor.compressImage(
            tempFile,
            '${documentType}_${DateTime.now().millisecondsSinceEpoch}',
            targetSizeKB: 50,
          );
          
          if (compressedFile != null && await compressedFile.exists()) {
            debugPrint('Compressed image for $documentType: ${compressedFile.path}');
            // Clean up temporary file
            await tempFile.delete();
            return compressedFile;
          } else {
            debugPrint('Compression failed for $documentType');
            _showErrorDialog('Failed to compress image for $documentType');
            return null;
          }
        } else {
          debugPrint('Copied file does not exist: ${tempFile.path}');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error selecting or compressing image for $documentType: $e');
      _showErrorDialog('Error processing image: ${e.toString()}');
      return null;
    }
  }

  Future<bool> _uploadDocument({
    required String documentType,
    required File image,
    File? backImage,
    String? details,
  }) async {
    try {
      // Validate file existence
      if (!await image.exists()) {
        debugPrint('Image file does not exist: ${image.path}');
        return false;
      }
      if (backImage != null && !await backImage.exists()) {
        debugPrint('Back image file does not exist: ${backImage.path}');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        debugPrint('Access token not found');
        throw Exception('Access token not found');
      }

      final uri = Uri.parse(ApiConfig.driverDocumentUrl);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['document_type'] = documentType;

      // Send default "N/A" if details are empty
      final effectiveDetails = (details?.trim().isEmpty ?? true) ? 'N/A' : details;
      switch (documentType) {
        case 'IDENTITY':
          request.fields['identity_details'] = effectiveDetails as String;
          break;
        case 'RIGHT_TO_WORK':
          request.fields['right_to_work_details'] = effectiveDetails as String;
          break;
        case 'ADDRESS':
          request.fields['address_details'] = effectiveDetails as String;
          break;
        case 'INSURANCE':
          request.fields['insurance_details'] = effectiveDetails as String;
          break;
        case 'LICENSE':
          request.fields['license_details'] = effectiveDetails as String;
          break;
        case 'DVLA':
          request.fields['dvla_details'] = effectiveDetails as String;
          break;
      }

      // Use compressed image
      final compressedImage = await ImageCompressor.compressImage(
        image,
        '${documentType}_${DateTime.now().millisecondsSinceEpoch}',
        targetSizeKB: 20,
      );
      if (compressedImage == null) {
        debugPrint('Failed to compress image for $documentType');
        _showErrorDialog('Failed to compress image for $documentType');
        return false;
      }

      request.files.add(
        await http.MultipartFile.fromPath('front_image', compressedImage.path),
      );

      // Compress back image if provided
      if (backImage != null) {
        final compressedBackImage = await ImageCompressor.compressImage(
          backImage,
          '${documentType}_back_${DateTime.now().millisecondsSinceEpoch}',
          targetSizeKB: 20,
        );
        if (compressedBackImage == null) {
          debugPrint('Failed to compress back image for $documentType');
          _showErrorDialog('Failed to compress back image for $documentType');
          return false;
        }
        request.files.add(
          await http.MultipartFile.fromPath('back_image', compressedBackImage.path),
        );
      }

      debugPrint('Uploading document: $documentType, front_image: ${compressedImage.path}');
      if (backImage != null) {
        debugPrint('Back_image: ${backImage.path}');
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Upload success for $documentType: $responseString');
        // Clean up compressed files
        await compressedImage.delete();
        if (backImage != null) {
          final compressedBackImage = await ImageCompressor.compressImage(
            backImage,
            '${documentType}_back_${DateTime.now().millisecondsSinceEpoch}',
            targetSizeKB: 20,
          );
          await compressedBackImage?.delete();
        }
        return true;
      } else {
        debugPrint('Upload failed for $documentType: $responseString');
        _showErrorDialog('Failed to upload $documentType: $responseString');
        return false;
      }
    } catch (e) {
      debugPrint('Upload error for $documentType: $e');
      _showErrorDialog('Error uploading $documentType: ${e.toString()}');
      return false;
    }
  }

  Future<void> _submitAllDocuments() async {
    setState(() => _isLoading = true);
    try {
      if (_idImage == null) {
        throw Exception(appLanguage.get('Please_upload_your_Proof_of_Identity'));
      }
      if (_isBritishCitizen == null) {
        throw Exception(appLanguage.get('Citizenship_status_not_loaded._Please_try_again.'));
      }
      if (_isBritishCitizen!) {
        if (_passportFront == null || _passportBack == null) {
          throw Exception(appLanguage.get('Please_upload_both_sides_of_your_British_Passport'));
        }
      } else {
        if (_rightToWorkImage == null) {
          throw Exception(appLanguage.get('Please_upload_your_Right_to_Work_document'));
        }
      }
      if (_addressProofImage == null) {
        throw Exception(appLanguage.get('Please_upload_your_Address_Proof'));
      }
      if (_vehicleInsuranceImage == null) {
        throw Exception(appLanguage.get('Please_upload_your_Vehicle_Insurance'));
      }
      if (_drivingLicenseFront == null || _drivingLicenseBack == null) {
        throw Exception(appLanguage.get('Please_upload_both_sides_of_your_Driving_License'));
      }
      if (_dvlsImage == null) {
        throw Exception(appLanguage.get('Please_upload_your_DVLA_Electronic_Counterpart'));
      }

      List<Future<bool>> uploads = [
        _uploadDocument(
          documentType: 'IDENTITY',
          image: _idImage!,
          details: _identityDetailsController.text,
        ),
        if (_isBritishCitizen!)
          _uploadDocument(
            documentType: 'RIGHT_TO_WORK',
            image: _passportFront!,
            backImage: _passportBack!,
            details: _rightToWorkDetailsController.text,
          )
        else
          _uploadDocument(
            documentType: 'RIGHT_TO_WORK',
            image: _rightToWorkImage!,
            details: _rightToWorkDetailsController.text,
          ),
        _uploadDocument(
          documentType: 'ADDRESS',
          image: _addressProofImage!,
          details: _addressDetailsController.text,
        ),
        _uploadDocument(
          documentType: 'INSURANCE',
          image: _vehicleInsuranceImage!,
          details: _insuranceDetailsController.text,
        ),
        _uploadDocument(
          documentType: 'LICENSE',
          image: _drivingLicenseFront!,
          backImage: _drivingLicenseBack!,
          details: _licenseDetailsController.text,
        ),
        _uploadDocument(
          documentType: 'DVLA',
          image: _dvlsImage!,
          details: _dvlaController.text,
        ),
      ];

      final results = await Future.wait(uploads);
      if (results.contains(false)) {
        throw Exception('Some documents failed to upload. Please check the errors and try again.');
      }

      _showSuccessDialog(appLanguage.get('All_documents_submitted_successfully!'));
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.doc_text_fill,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLanguage.get('Document_Verification'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appLanguage.get('Complete_your_application_by_uploading_all_required_documents'),
                      style: TextStyle(
                        fontSize: 15,
                        color: _textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final completedDocs = _documentStatus.values.where((v) => v).length;
    final totalDocs = _documentStatus.length;
    final progress = completedDocs / totalDocs;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLanguage.get('Application_Progress'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: progress == 1.0 ? _successColor : _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedDocs/$totalDocs ${appLanguage.get('Complete')}',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progress == 1.0 ? _successColor : _primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress == 1.0
                ? appLanguage.get('All_documents_uploaded!_Ready_to_submit.')
: '${appLanguage.get('Upload')} ${totalDocs - completedDocs} ${appLanguage.get('more_documents_to_complete_your_application')}',            style: TextStyle(
              fontSize: 14,
              color: progress == 1.0 ? _successColor : _textSecondary,
              fontWeight: progress == 1.0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: _textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required File? image,
    File? backImage,
    required Function(File?) onImageUploaded,
    Function(File?)? onBackImageUploaded,
    bool isRequired = true,
    bool isSingleImage = true,
    required String documentType,
    required TextEditingController detailsController,
  }) {
    final isComplete = isSingleImage
        ? image != null
        : image != null && backImage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? _successColor : _borderColor,
          width: isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isComplete
                            ? _successColor.withOpacity(0.1)
                            : _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isComplete
                        ? CupertinoIcons.checkmark_alt_circle_fill
                        : icon,
                    color: isComplete ? _successColor : _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          if (isComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appLanguage.get('Complete'),
                                style: TextStyle(
                                  color: _successColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!isComplete && isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appLanguage.get('Required'),
                                style: TextStyle(
                                  color: _warningColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: Text(
                          appLanguage.get("Learn_more_about_this_document"),
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => _navigateToDocumentInfo(title),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Upload Section
            Row(
              children: [
                _buildImageUpload(
                  label: isSingleImage ? appLanguage.get('Document') : appLanguage.get('Front_Side'),
                  file: image,
                  onPressed: () async {
                    final file = await _pickImage(documentType);
                    if (file != null) {
                      onImageUploaded(file);
                      _updateDocumentStatus();
                    }
                  },
                ),
                if (!isSingleImage) ...[
                  const SizedBox(width: 12),
                  _buildImageUpload(
                    label: appLanguage.get('Back_Side'),
                    file: backImage,
                    onPressed: () async {
                      final file = await _pickImage('${documentType}_back');
                      if (file != null) {
                        onBackImageUploaded!(file);
                        _updateDocumentStatus();
                      }
                    },
                  ),
                ],
              ],
            ),
            // Details Section
            const SizedBox(height: 20),
            Text(
              appLanguage.get('Additional_Details_(Optional)'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: detailsController,
              placeholder: appLanguage.get('Add_any_relevant_details_about_this_document...'),
              maxLines: 2,
              style: TextStyle(color: _textPrimary, fontSize: 15),
              placeholderStyle: TextStyle(color: _textSecondary),
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor),
                borderRadius: BorderRadius.circular(10),
                color: _cardColor,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDocumentInfo(String docTitle) {
    Widget targetPage;
    switch (docTitle) {
      case 'Proof of Identity':
      case 'Proof_of_Identity':
      case var _ when docTitle == appLanguage.get('Proof_of_Identity'):
        targetPage = const IdentityVerificationScreen();
        break;
      case 'British Passport':
      case 'British_Passport':
       case var _ when docTitle == appLanguage.get('British_Passport'):
        targetPage = const BritishPassport();
        break;
      case 'Right to Work in UK':
      case 'Right_to_Work_in_UK':
      case var _ when docTitle == appLanguage.get('Right_to_Work_in_UK'):
        targetPage = const RightToWork();
        break;
      case 'Proof of Address':
      case 'Proof_of_Address':
      case var _ when docTitle == appLanguage.get('Proof_of_Address'):
        targetPage = const ProofOfAddress();
        break;
      case 'Vehicle Insurance':
      case 'Vehicle_Insurance':
      case var _ when docTitle == appLanguage.get('Vehicle_Insurance'):
        targetPage = const VehicleInsurance();
        break;
      case 'Driving License':
      case 'Driving_License':
      case var _ when docTitle == appLanguage.get('Driving_License'):
        targetPage = const DriverLicence();
        break;
      case 'DVLA Electronic Counterpart':
      case 'DVLA_Electronic_Counterpart':
      case var _ when docTitle == appLanguage.get('DVLA_Electronic_Counterpart'):
        targetPage = const DvlsDocument();
        break;
      default:
        return;
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => targetPage));
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
          height: 140,
          decoration: BoxDecoration(
            color: file != null ? null : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: file != null ? _successColor : _borderColor,
              width: file != null ? 2 : 1,
            ),
          ),
          child:
              file != null
                  ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _successColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.camera_fill,
                        color: _textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appLanguage.get('Tap_to_upload'),
                        style: TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allComplete = _documentStatus.values.every((status) => status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            appLanguage.get('Final_Step'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allComplete
                ? appLanguage.get('All_documents_are_ready._Submit_your_application_for_review.')
                : appLanguage.get('Please_complete_all_document_uploads_before_submitting.'),
            style: TextStyle(fontSize: 15, color: _textSecondary),
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            onPressed: _isLoading || !allComplete ? null : _submitAllDocuments,
            padding: const EdgeInsets.symmetric(vertical: 16),
            borderRadius: BorderRadius.circular(12),
            color: allComplete ? _primaryColor : _borderColor,
            child:
                _isLoading
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          appLanguage.get('Submitting...'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      appLanguage.get('Submit_Application'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color:
                            allComplete
                                ? CupertinoColors.white
                                : _textSecondary,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: _cardColor.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: _borderColor.withOpacity(0.3), width: 0.5),
        ),
        middle: Text(
          appLanguage.get('Document_Upload'),
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _isLoading && _isBritishCitizen == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(
                          radius: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appLanguage.get('Loading_your_profile...'),
                          style: TextStyle(fontSize: 16, color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildProgressSection(),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          appLanguage.get('Identity_Verification'),
                          appLanguage.get('Required_documents_to_verify_your_identity'),
                        ),
                        _buildDocumentCard(
                          title: appLanguage.get('Proof_of_Identity'),
                          icon: CupertinoIcons.person_badge_plus,
                          image: _idImage,
                          onImageUploaded: (file) => setState(() => _idImage = file),
                            isRequired: true,
                            documentType: 'IDENTITY',
                            detailsController: _identityDetailsController,
                          ),
                          _buildSectionHeader(
                            appLanguage.get('Citizenship_&_Work_Authorization'),
                            _isBritishCitizen == true
                                ? appLanguage.get('British_passport_required_for_citizens')
                                : appLanguage.get('Right_to_work_documentation_required'),
                          ),
                          if (_isBritishCitizen == true)
                            _buildDocumentCard(
                              title: appLanguage.get('British_Passport'),
                              icon: CupertinoIcons.doc_text,
                              image: _passportFront,
                              backImage: _passportBack,
                              onImageUploaded:
                                  (file) => setState(() => _passportFront = file),
                              onBackImageUploaded:
                                  (file) => setState(() => _passportBack = file),
                              isRequired: true,
                              isSingleImage: false,
                              documentType: 'RIGHT_TO_WORK',
                              detailsController: _rightToWorkDetailsController,
                            )
                          else
                            _buildDocumentCard(
                              title: appLanguage.get('Right_to_Work_in_UK'),
                              icon: CupertinoIcons.globe,
                              image: _rightToWorkImage,
                              onImageUploaded:
                                  (file) => setState(() => _rightToWorkImage = file),
                              isRequired: true,
                              documentType: 'RIGHT_TO_WORK',
                              detailsController: _rightToWorkDetailsController,
                            ),
                          _buildSectionHeader(
                            appLanguage.get('Address_Verification'),
                            appLanguage.get('Proof_of_your_current_residential_address'),
                          ),
                          _buildDocumentCard(
                            title: appLanguage.get('Proof_of_Address'),
                            icon: CupertinoIcons.location_solid,
                            image: _addressProofImage,
                            onImageUploaded:
                                (file) => setState(() => _addressProofImage = file),
                            isRequired: true,
                            documentType: 'ADDRESS',
                            detailsController: _addressDetailsController,
                          ),
                          _buildSectionHeader(
                            appLanguage.get('Driving_Documentation'),
                            appLanguage.get('Required_documents_for_vehicle_operation'),
                          ),
                          _buildDocumentCard(
                            title: appLanguage.get('Vehicle_Insurance'),
                            icon: CupertinoIcons.car_detailed,
                            image: _vehicleInsuranceImage,
                            onImageUploaded:
                                (file) => setState(() => _vehicleInsuranceImage = file),
                            isRequired: true,
                            documentType: 'INSURANCE',
                            detailsController: _insuranceDetailsController,
                          ),
                          _buildDocumentCard(
                            title: appLanguage.get('Driving_License'),
                            icon: CupertinoIcons.creditcard,
                            image: _drivingLicenseFront,
                            backImage: _drivingLicenseBack,
                            onImageUploaded:
                                (file) => setState(() => _drivingLicenseFront = file),
                            onBackImageUploaded:
                                (file) => setState(() => _drivingLicenseBack = file),
                            isRequired: true,
                            isSingleImage: false,
                            documentType: 'LICENSE',
                            detailsController: _licenseDetailsController,
                          ),
                          _buildDocumentCard(
                            title: appLanguage.get('DVLA_Electronic_Counterpart'),
                            icon: CupertinoIcons.doc_checkmark,
                            image: _dvlsImage,
                            onImageUploaded:
                                (file) => setState(() => _dvlsImage = file),
                            isRequired: true,
                            documentType: 'DVLA',
                            detailsController: _dvlaController,
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            if (_isLoading && _isBritishCitizen != null)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: _primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}