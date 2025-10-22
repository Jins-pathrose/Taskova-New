import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Chat/chat.dart';
import 'package:taskova_new/View/Homepage/admin_approval.dart';
import 'package:taskova_new/View/Homepage/canceljobpost.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/driver_document.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailPage extends StatefulWidget {
  final JobPost jobPost;

  const JobDetailPage({Key? key, required this.jobPost}) : super(key: key);

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage>
    with SingleTickerProviderStateMixin {
  String? _jobRequestId;
  bool _isAccepted = false;
  bool _isLoading = false;
  bool _hasApplied = false; // New flag to track application status
  String? _chatRoomId;
  String? _driverId;
  String _status = 'pending';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  bool _showOtpFab = false;
  bool _showFloatingChat = false;
  bool _otp = false;
  final TextEditingController _otpController = TextEditingController();
  bool _hasSubmittedReview = false; // New flag to track review submission
  final ScrollController _scrollController = ScrollController();
  late AppLanguage appLanguage;

 void initState() {
  super.initState();
  appLanguage = Provider.of<AppLanguage>(context, listen: false);

  _animationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 800),
  );
  _fadeAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  );
  _slideAnimation = Tween<Offset>(
    begin: Offset(0, 0.05),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
  );
  _animationController.forward();
  _checkIfAlreadyApplied();
  _checkIfReviewExists();
  _checkIfOtpVerified(); // Add this line
  _showOtpFab = _status == 'accepted';
  _showFloatingChat = true;
  _scrollController.addListener(_scrollListener);
}
Future<void> _checkIfOtpVerified() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final otpKey = 'otp_verified_${widget.jobPost.id}';
    final hasVerifiedOtp = prefs.getBool(otpKey) ?? false;

    if (mounted) {
      setState(() {
        _otp = hasVerifiedOtp;
      });
    }
  } catch (e) {
    print('Error checking OTP status: $e');
  }
}
  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    _scrollController.dispose();
    _otpController.dispose();

    super.dispose();
  }
void _scrollListener() {
  if (_scrollController.offset > 200 && _showFloatingChat) {
    setState(() {
      _showFloatingChat = false; // Hide when scrolling down
    });
  } else if (_scrollController.offset <= 200 && !_showFloatingChat) {
    setState(() {
      _showFloatingChat = true; // Show when at top
    });
  }
}
  Future<void> _checkIfAlreadyApplied() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse(ApiConfig.jobRequestUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> jobRequests = decoded['data'];
      final appliedJob = jobRequests.firstWhere(
        (request) => request['job'] == widget.jobPost.id,
        orElse: () => null,
      );

      if (appliedJob != null) {
        setState(() {
          _jobRequestId = appliedJob['id'].toString();
          _status = appliedJob['status'] ?? 'pending';
          _hasApplied = true;
          _chatRoomId = appliedJob['chat_room_id']?.toString();
          _driverId = appliedJob['driver_id']?.toString();
          _showOtpFab = _status == 'accepted';
          print('Status: $_status, Show OTP FAB: $_showOtpFab');
        });

        if (_chatRoomId == null) {
          await _fetchChatRoomId();
        }
      } else {
        setState(() {
          _hasApplied = false;
          _status = 'pending';
          _showOtpFab = false;
        });
      }
    }
  } catch (e) {
    print('Error checking applied jobs: $e');
    setState(() {
      _hasApplied = false;
      _status = 'pending';
      _showOtpFab = false;
    });
  }
}

  void _showOtpDialog() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Submit OTP'),
            content: Column(
              children: [
                SizedBox(height: 16),
                Text('Enter the 6-digit OTP provided by the business:'),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: _otpController,
                  placeholder: 'Enter OTP',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: Text('Submit'),
                onPressed: () { _submitOtp();
                Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
 
Future<void> _submitOtp() async {
  if (_otpController.text.length != 6) {
    _showErrorMessage(context, 'Please enter a valid 6-digit OTP');
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/job-requests/$_jobRequestId/verify-otp/',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'otp': _otpController.text}),
    );

    if (response.statusCode == 200) {
      // Clear the OTP field
      _otpController.clear();
      
      // Save OTP verification status to SharedPreferences
      final otpKey = 'otp_verified_${widget.jobPost.id}';
      await prefs.setBool(otpKey, true);
      
      setState(() {
        _otp = true;
      });
      
      // Then show the success message
      _showSuccessMessage(context, 'OTP verified successfully!');
    } else {
      final error = jsonDecode(response.body);
      _showErrorMessage(context, error['detail'] ?? 'Invalid OTP');
    }
  } catch (e) {
    _showErrorMessage(context, 'Error verifying OTP: $e');
  }
}
  Future<void> _checkIfReviewExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewKey = 'review_submitted_${widget.jobPost.id}';
      final hasSubmitted = prefs.getBool(reviewKey) ?? false;

      if (mounted) {
        setState(() {
          _hasSubmittedReview = hasSubmitted;
        });
      }
    } catch (e) {
      print('Error checking review status: $e');
    }
  }

  Future<void> _checkIfJobIsAccepted() async {
  if (_jobRequestId == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('${ApiConfig.jobRequestsAcceptedUrl}$_jobRequestId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _status = data['status'] ?? 'pending';
          _chatRoomId = data['chat_room_id']?.toString();
          _driverId = data['driver_id']?.toString();
          _showOtpFab = _status == 'accepted'; // Add this line
          print('Status updated: $_status, Show OTP FAB: $_showOtpFab');
        });
      }
    }
  } catch (e) {
    print('Error checking job status: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

 Future<void> _submitReview() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      _showErrorMessage(
        context,
        'Authentication error: Access token is missing.',
      );
      return;
    }

    if (widget.jobPost.id == null || widget.jobPost.businessId == null) {
      _showErrorMessage(context, 'Error: Job ID or Business ID is missing.');
      return;
    }
    
    if (_rating <= 0) {
      _showErrorMessage(context, 'Please provide a rating.');
      return;
    }

    final requestBody = {
      'rater_type': 'user',
      'ratee_type': 'business',
      'job': widget.jobPost.id,
      'ratee': widget.jobPost.businessId,
      'rating': _rating.toInt(),
      'comment': _reviewController.text.trim(),
    };

    print('Submitting review with body: $requestBody');

    final response = await http.post(
      Uri.parse(ApiConfig.ratingUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final reviewKey = 'review_submitted_${widget.jobPost.id}';
      await prefs.setBool(reviewKey, true);
      
      _showSuccessMessage(context, 'Review submitted successfully!');
      
      if (mounted) {
        setState(() {
          _reviewController.clear();
          _rating = 0.0;
          _hasSubmittedReview = true; // This will hide the review form and show thank you message
        });
      }
    } else {
      String errorMessage = 'Failed to submit review. Please try again.';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
      } catch (_) {}
      _showErrorMessage(context, errorMessage);
    }
  } catch (e, stackTrace) {
    print('Error submitting review: $e\n$stackTrace');
    _showErrorMessage(context, 'Error submitting review: $e');
  }
}
Future<void> _openMap() async {
  final lat = widget.jobPost.businessLatitude;
  final lng = widget.jobPost.businessLongitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
   await launchUrl(url);    
  }
  @override
  Widget build(BuildContext context) { 
      print('Building with status: $_status, showOtpFab: $_showOtpFab'); // Debug print

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      child: Stack(
        children: [
          CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverNavigationBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildBusinessImage(),
              _buildJobHeader(),
              _buildJobContent(),
              SizedBox(height: 100),
            ],
          ),
        ),
      ],
    ),
    
    // Floating Chat Icon
    if (_hasApplied &&
    _status != 'cancelled_by_driver' &&
    _status != 'cancelled_by_shopkeeper' &&
    _chatRoomId != null && // Add this check
    _driverId != null) // Add this check
  AnimatedPositioned(
    duration: Duration(milliseconds: 300),
    top: _showFloatingChat ? 100 : -60,
    right: 20,
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ChatPage(
              driverId: _driverId!, // Now safe to use !
              chatRoomId: _chatRoomId!, // Now safe to use !
              businessName: widget.jobPost.businessName,
            ),
          ),
        );
      },
          child: Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        CupertinoColors.activeBlue,
        CupertinoColors.activeBlue,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Color.fromARGB(255, 102, 177, 234).withOpacity(0.4),
        blurRadius: 20,
        spreadRadius: 2,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Icon(
    CupertinoIcons.chat_bubble_2_fill,
    color: Colors.white,
    size: 28,
  ),
),
        ),
      ),
         if (_showOtpFab)
  Positioned(
    bottom: 30,
    right: 20,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: LinearGradient(
          colors: [
            CupertinoColors.activeBlue,
            CupertinoColors.activeBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.activeBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(35),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.shield_lefthalf_fill,
              size: 24,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'OTP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        onPressed: _showOtpDialog,
      ),
    ),
  ),
        ],
      ),
    );
  }

  Widget _buildSliverNavigationBar() {
    return CupertinoSliverNavigationBar(
      largeTitle: Text(
        widget.jobPost.title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.black,
        ),
      ),
      middle: Text(
        widget.jobPost.businessName,
        style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
      ),
      backgroundColor: CupertinoColors.white,
      border: null,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.back,
          color: CupertinoColors.activeBlue,
          size: 28,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBusinessImage() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CupertinoColors.systemGrey5, CupertinoColors.white],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.jobPost.businessImage != null &&
                  widget.jobPost.businessImage!.isNotEmpty
              ? FadeTransition(
                opacity: _fadeAnimation,
                child: Image.network(
                  widget.jobPost.businessImage!.startsWith('http')
                      ? widget.jobPost.businessImage!
                      : '${ApiConfig.getImageUrl}${widget.jobPost.businessImage}',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildPlaceholderImage(),
                ),
              )
              : _buildPlaceholderImage(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverlayChip(
                      CupertinoIcons.calendar,
                      widget.jobPost.jobDate ?? 'TBD',
                      CupertinoColors.systemGreen,
                    ),
                    if (widget.jobPost.distanceMiles != null)
                      _buildOverlayChip(
                        CupertinoIcons.location_solid,
                        formatDistance(widget.jobPost.distanceMiles),
                        CupertinoColors.systemBlue,
                      ),
                  ],
                ),
                SizedBox(height: 8),
                _buildOverlayChip(
                  CupertinoIcons.clock,
                  '${widget.jobPost.startTime ?? 'N/A'} - ${widget.jobPost.endTime ?? 'N/A'}',
                  CupertinoColors.systemOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: CupertinoColors.systemGrey4,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.building_2_fill,
              size: 80,
              color: CupertinoColors.systemGrey2,
            ),
            SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.jobPost.distanceMiles != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CupertinoColors.systemBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 16,
                        color: CupertinoColors.systemBlue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        formatDistance(widget.jobPost.distanceMiles),
                        style: TextStyle(
                          color: CupertinoColors.systemBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                CupertinoIcons.calendar,
                appLanguage.get('Date'),
                widget.jobPost.jobDate ?? 'TBD',
                CupertinoColors.systemGreen,
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                CupertinoIcons.clock,
                appLanguage.get('Time'),
                '${widget.jobPost.startTime ?? 'N/A'} - ${widget.jobPost.endTime ?? 'N/A'}',
                CupertinoColors.systemOrange,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              if (widget.jobPost.hourlyRate != null)
                _buildInfoChip(
                  CupertinoIcons.money_euro,
                  appLanguage.get('Hourly'),
                  '\€ ${widget.jobPost.hourlyRate?.toStringAsFixed(2)}',
                  CupertinoColors.systemPurple,
                ),
              if (widget.jobPost.hourlyRate != null &&
                  widget.jobPost.perDeliveryRate != null)
                SizedBox(width: 12),
              if (widget.jobPost.perDeliveryRate != null)
                _buildInfoChip(
                  CupertinoIcons.car_detailed,
                  appLanguage.get('Per_Delivery'),
                  '\€ ${widget.jobPost.perDeliveryRate?.toStringAsFixed(2)}',
                  CupertinoColors.systemTeal,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobContent() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        _buildSection(
          appLanguage.get('Job_Description'),
          widget.jobPost.description ?? 'No description available',
          CupertinoIcons.doc_text,
        ),
        SizedBox(height: 16),
        _buildLocationSection(),
        SizedBox(height: 16),
        _buildBenefitsSection(),
        SizedBox(height: 16),
        
        // Show review section only when OTP is verified AND user hasn't submitted review yet
        if (_otp == true && _hasSubmittedReview == false) ...[
          SizedBox(height: 16),
          _buildReviewSection(),
        ],
        
        // Show thank you message if review has been submitted
        if (_otp == true && _hasSubmittedReview == true) ...[
          SizedBox(height: 16),
          _buildReviewSubmittedMessage(),
        ],
        
        SizedBox(height: 16),
        _buildBottomActions(),
      ],
    ),
  );
}
Widget _buildReviewSubmittedMessage() {
  return SlideTransition(
    position: _slideAnimation,
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CupertinoColors.systemGreen.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              appLanguage.get('Thank You!'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              appLanguage.get('Your review has been submitted successfully.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildSection(String title, String content, IconData icon) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: CupertinoColors.systemBlue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
  return GestureDetector(
    onTap: _openMap,
    child: SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.location_solid,
                      color: CupertinoColors.systemGreen,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appLanguage.get('Location'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                  // Map indicator with "Tap to view" text
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.systemBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.map,
                          color: CupertinoColors.systemBlue,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          appLanguage.get('Tap to view'),
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                  // Add subtle shadow to indicate it's tappable
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey4.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location,
                          color: CupertinoColors.systemGrey,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.jobPost.address}',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Arrow indicating tappable action
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey2,
                          size: 16,
                        ),
                      ],
                    ),
                    if (widget.jobPost.distanceMiles != null) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.arrow_right_arrow_left,
                            color: CupertinoColors.systemGrey,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${appLanguage.get('Distance')}: ${formatDistance(widget.jobPost.distanceMiles)}',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 12),
                    // Map preview hint with clear call-to-action
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.map_fill,
                            color: CupertinoColors.systemBlue,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            appLanguage.get('View on Map'),
                            style: TextStyle(
                              color: CupertinoColors.systemBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBenefitsSection() {
    final benefits = widget.jobPost.complimentaryBenefits;
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.gift,
                      color: CupertinoColors.systemPurple,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    appLanguage.get('Benefits'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              benefits.isEmpty
                  ? Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CupertinoColors.systemGrey5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          color: CupertinoColors.systemGrey2,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          appLanguage.get('No_additional_benefits_listed'),
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children:
                        benefits
                            .map(
                              (benefit) => Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.systemGreen,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_circle,
                                      color: CupertinoColors.systemGreen,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        benefit.toString(),
                                        style: TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.star_fill,
                      color: CupertinoColors.systemYellow,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    appLanguage.get('Leave_a_Review'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                appLanguage.get('Rate_your_experience'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        color: CupertinoColors.systemYellow,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              Text(
                appLanguage.get('Your_Feedback'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              SizedBox(height: 12),
              CupertinoTextField(
                controller: _reviewController,
                placeholder: appLanguage.get('Share_your_experience...'),
                placeholderStyle: TextStyle(
                  color: CupertinoColors.systemGrey2,
                  fontSize: 16,
                ),
                minLines: 3,
                maxLines: 5,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                style: TextStyle(color: CupertinoColors.black, fontSize: 16),
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed:
                      _rating > 0
                          // && _reviewController.text.isNotEmpty
                          ? _submitReview
                          : null,
                  color: CupertinoColors.activeBlue,
                  child: Text(
                    appLanguage.get('Submit_Review'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) Center(child: CupertinoActivityIndicator()),

            if (!_isLoading) ...[
              // CASE 1: Job is cancelled (by either party)
              if (_status == 'cancelled_by_driver' ||
                  _status == 'cancelled_by_shopkeeper')
                _buildStatusChip(
                  _status == 'cancelled_by_driver'
                      ? 'Job cancelled by you'
                      : 'Cancelled by Shopkeeper',
                  _status == 'cancelled_by_driver'
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemRed,
                ),

              // CASE 2: Job is applied (not cancelled) - show both chat and cancel
              if (_hasApplied &&
                  _status != 'cancelled_by_driver' &&
                  _status != 'cancelled_by_shopkeeper') ...[
                if (_chatRoomId != null) _buildChatButton(),
                SizedBox(height: 12),
                _buildCancelButton(),
              ],

              // CASE 3: Not applied yet - show apply button
              if (!_hasApplied &&
                  _status != 'cancelled_by_driver' &&
                  _status != 'cancelled_by_shopkeeper')
                _buildApplyButton(),
            ],
          ],
        ),
      ),
    );
  }

  // Cancel button with confirmation dialog
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder:
                (context) => CupertinoCancelJobPage(
                  jobPost: widget.jobPost.id,
                  jobRequestId: _jobRequestId!,
                  onJobCancelled: (String reason) {
                    _cancelJob(reason);
                  },
                ),
          );
        },
        color: CupertinoColors.systemRed,
        child: Text(
          'Cancel Job',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  // Status chip for cancellation messages
  Widget _buildStatusChip(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: color,
          fontSize: 16,
        ),
      ),
    );
  }

  // Applied button (disabled state)
  Widget _buildAppliedButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        onPressed: () {},
        color: Colors.green,
        child: Text(
          appLanguage.get('Applied'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  // Apply button (active state)
  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: () => _handleJobApplication(context),
        child: Text(
          'Apply for this Job',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Chat button for accepted jobs
 Widget _buildChatButton() {
  // Show loading if chat room is still being fetched
  if (_chatRoomId == null || _driverId == null) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CupertinoButton(
        onPressed: null,
        color: CupertinoColors.systemGrey4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 12),
            SizedBox(width: 8),
            Text(
              'Setting up chat...',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return SizedBox(
    width: double.infinity,
    child: CupertinoButton.filled(
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ChatPage(
              driverId: _driverId!,
              chatRoomId: _chatRoomId!,
              businessName: widget.jobPost.businessName,
            ),
          ),
        );
      },
      child: Text(
        'Chat with ${widget.jobPost.businessName}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

  void _handleJobApplication(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text(
              appLanguage.get('Apply_for') + ' ${widget.jobPost.title}?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLanguage.get('You_are_about_to_apply_for_this_job_at') +
                      ' ${widget.jobPost.businessName}.',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemBlue),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        color: CupertinoColors.systemBlue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appLanguage.get(
                            'The_business_will_be_notified_of_your_application.',
                          ),
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  appLanguage.get('cancel'),
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _submitJobApplication(context);
                },
                child: Text(
                  appLanguage.get('Apply_Now'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ],
          ),
    );
  }

 void _showSuccessMessage(BuildContext context, String message) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(appLanguage.get('Success')),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: Text(appLanguage.get('OK')),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
  super.setState(() {
    _showOtpFab = false;
  });
}

  void _showErrorMessage(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Oops!'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  String formatDistance(double? distanceMiles) {
    if (distanceMiles == null) return 'N/A';
    if (distanceMiles < 1) {
      return '${(distanceMiles * 5280).round()} ft';
    } else {
      return '${distanceMiles.toStringAsFixed(1)} miles';
    }
  }

  Future<void> _submitJobApplication(BuildContext context) async {
    BuildContext? loadingContext;

    try {
      // Show loading dialog
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          loadingContext = ctx;
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoActivityIndicator(
                radius: 16,
                color: Colors.blue.shade700,
              ),
            ),
          );
        },
      );

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final profileResponse = await http.get(
        Uri.parse(ApiConfig.profileStatusUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        if (profileData['is_approved'] != true) {
          if (loadingContext != null && Navigator.canPop(loadingContext!)) {
            Navigator.pop(loadingContext!);
          }
          if (profileData['is_document_complete'] == true) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => DocumentVerificationPendingScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => DocumentRegistrationPage(),
              ),
            );
          }
          return;
        }
      } else {
        throw Exception('Failed to check profile status');
      }
      // Submit application
      final requestBody = {'job': widget.jobPost.id, 'status': 'applied'};

      final response = await http.post(
        Uri.parse(ApiConfig.jobRequestUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Update state with the new application
        if (mounted) {
          setState(() {
            _jobRequestId = responseData['id']?.toString();
            _status = 'applied'; // Set status directly to applied
            _hasApplied = true;
            // Set chat room ID and driver ID from response if available
            _chatRoomId = responseData['chat_room_id']?.toString();
            _driverId = responseData['driver_id']?.toString();
                  _showOtpFab = _status == 'accepted'; // Add this line

          });
          print(_chatRoomId);
          print('chaaaaaaattttt');
        }

        // If chat room ID wasn't in initial response, try to fetch it
        if (_chatRoomId == null) {
          await _fetchChatRoomId();
        }

        if (loadingContext != null && Navigator.canPop(loadingContext!)) {
          Navigator.pop(loadingContext!);
        }

        _showApplicationSuccessMessage(context);
        
      } else {
        // throw Exception('Failed to submit application');
        print(response.statusCode);
      }
    } catch (e) {
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.pop(loadingContext!);
      }
      // _showErrorMessage(
      //   context,
      //   'Application failed: ${e is SocketException ? 'No internet connection' : e.toString()}',
      // );
    }
  }

  Future<void> _fetchChatRoomId() async {
    if (_jobRequestId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.jobRequestsListUrl}${widget.jobPost.id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobRequest = data['data'].firstWhere(
          (req) => req['id'].toString() == _jobRequestId,
          orElse: () => null,
        );

        if (jobRequest != null && mounted) {
          setState(() {
            _chatRoomId = jobRequest['chat_room_id']?.toString();
            _driverId = jobRequest['driver_id']?.toString();
          });
        }
        print(_chatRoomId);
        print('00000chattt');
      }
    } catch (e) {
      print('Error fetching chat room ID: $e');
    }
  }

  void _showApplicationSuccessMessage(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.check_mark_circled,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  appLanguage.get('Application_Submitted'),
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  appLanguage.get('Your_application_for') +
                      ' ${widget.jobPost.title} ' +
                      appLanguage.get('has_been_sent_to') +
                      ' ${widget.jobPost.businessName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(context, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainWrapper(),
                          ),
                          (Route<dynamic> route) => false,
                        ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appLanguage.get('Got_it'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelJob(String reason) async {
    if (_jobRequestId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse(ApiConfig.cancelJobByDriverUrl(_jobRequestId!)),

        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cancellation_reason': reason}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _status = 'cancelled_by_driver';
        });
        _showSuccessMessage(context, 'Job cancelled successfully.');
      } else {
        String errorMessage = 'Failed to cancel job. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        _showErrorMessage(context, errorMessage);
      }
    } catch (e) {
      _showErrorMessage(context, 'Error cancelling job: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}