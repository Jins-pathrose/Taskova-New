import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Chat/chat.dart';
import 'package:taskova_new/View/Homepage/admin_approval.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/driver_document.dart';

class JobDetailPage extends StatefulWidget {
  final JobPost jobPost;

  const JobDetailPage({Key? key, required this.jobPost}) : super(key: key);

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> with SingleTickerProviderStateMixin {
  String? _jobRequestId;
  bool _isAccepted = false;
  bool _isLoading = false;
  String? _chatRoomId;
  String? _driverId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _checkIfAlreadyApplied();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
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
        final List<dynamic> jobRequests = jsonDecode(response.body);
        final appliedJob = jobRequests.firstWhere(
          (request) => request['job'] == widget.jobPost.id,
          orElse: () => null,
        );

        if (appliedJob != null) {
          setState(() {
            _jobRequestId = appliedJob['id'].toString();
          });
          _checkIfJobIsAccepted();
        }
      }
    } catch (e) {
      print('Error checking applied jobs: $e');
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
        setState(() {
          _isAccepted = data['is_accepted'] ?? false;
          _chatRoomId = data['chat_room_id']?.toString();
          _driverId = data['driver_id']?.toString();
        });
      }
    } catch (e) {
      print('Error checking job acceptance: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('${ApiConfig.jobRequestUrl}/$_jobRequestId/reviews'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': _rating,
          'comment': _reviewController.text,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessMessage(context, 'Review submitted successfully!');
        _reviewController.clear();
        setState(() {
          _rating = 0.0;
        });
      } else {
        _showErrorMessage(context, 'Failed to submit review. Please try again.');
      }
    } catch (e) {
      _showErrorMessage(context, 'Error submitting review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            widget.jobPost.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        border: null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color.fromARGB(255, 125, 140, 162), Colors.blue.shade600],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: _isAccepted ? 260 : 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBusinessImage(),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildBusinessHeader(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildDetailSection(
                                'Description',
                                widget.jobPost.description ?? 'No description available',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildDetailSection(
                                'Start Time',
                                widget.jobPost.startTime ?? 'N/A',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildDetailSection(
                                'End Time',
                                widget.jobPost.endTime ?? 'N/A',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildDetailSection(
                                'Hourly Rate',
                                widget.jobPost.hourlyRate != null
                                    ? '\$${widget.jobPost.hourlyRate?.toStringAsFixed(2)}'
                                    : 'N/A',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildDetailSection(
                                'Per Delivery Rate',
                                widget.jobPost.perDeliveryRate != null
                                    ? '\$${widget.jobPost.perDeliveryRate?.toStringAsFixed(2)}'
                                    : 'N/A',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildLocationSection(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildBenefitsSection(),
                            ),
                          ),
                          if (_isAccepted) ...[
                            const SizedBox(height: 20),
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildReviewSection(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAccepted)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 110,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildChatButton(),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildApplyButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessImage() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade900, Colors.blue.shade700],
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            child: widget.jobPost.businessImage != null && widget.jobPost.businessImage!.isNotEmpty
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.network(
                      widget.jobPost.businessImage!.startsWith('http')
                          ? widget.jobPost.businessImage!
                          : '${ApiConfig.getImageUrl}${widget.jobPost.businessImage}',
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.blue.shade900.withOpacity(0.7)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.building_2_fill,
          size: 100,
          color: Colors.blue.shade200,
        ),
      ),
    );
  }

  Widget _buildBusinessHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade800.withOpacity(0.9),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.jobPost.businessName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (widget.jobPost.distanceMiles != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                formatDistance(widget.jobPost.distanceMiles),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Location',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(CupertinoIcons.location_solid, color: Colors.blue.shade700, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lat: ${widget.jobPost.businessLatitude.toStringAsFixed(6)}, Long: ${widget.jobPost.businessLongitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 16),
                ),
              ),
            ],
          ),
          if (widget.jobPost.distanceMiles != null)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(CupertinoIcons.map_fill, color: Colors.blue.shade700, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Distance: ${formatDistance(widget.jobPost.distanceMiles)}',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = widget.jobPost.complimentaryBenefits;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complimentary Benefits',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          benefits.isEmpty
              ? Text(
                  'No benefits listed',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 16),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: benefits
                      .map(
                        (benefit) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.blue.shade700, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit.toString(),
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 16,
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
    );
  }

  Widget _buildReviewSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave a Review',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16),
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
                    index < _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          CupertinoTextField(
            controller: _reviewController,
            placeholder: 'Share your experience...',
            placeholderStyle: TextStyle(color: Colors.blue.shade400),
            maxLines: 5,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            style: TextStyle(color: Colors.blue.shade800),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _rating > 0 && _reviewController.text.isNotEmpty ? _submitReview : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _rating > 0 && _reviewController.text.isNotEmpty
                        ? [Colors.blue.shade600, Colors.blue.shade800]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Submit Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: _chatRoomId != null
          ? () {
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
            }
          : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'Chat with ${widget.jobPost.businessName}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: _isLoading
          ? Center(
              child: CupertinoActivityIndicator(radius: 16, color: Colors.blue.shade700),
            )
          : GestureDetector(
              onTap: _isAccepted ? null : () => _handleJobApplication(context),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: _isAccepted
                      ? LinearGradient(
                          colors: [Colors.grey.shade500, Colors.grey.shade600],
                        )
                      : LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade500],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAccepted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.paperplane_fill,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      _isAccepted ? 'Application Accepted' : 'Apply for this Job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _handleJobApplication(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(
          'Apply for ${widget.jobPost.title}',
          style: TextStyle(color: Colors.blue.shade900),
        ),
        content: Text(
          'Are you sure you want to apply for this job at ${widget.jobPost.businessName}?',
          style: TextStyle(color: Colors.blue.shade800),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: TextStyle(color: Colors.blue.shade700)),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Apply', style: TextStyle(color: Colors.blue.shade700)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _submitJobApplication(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitJobApplication(BuildContext context) async {
    BuildContext? loadingContext;

    try {
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
              child: CupertinoActivityIndicator(radius: 16, color: Colors.blue.shade700),
            ),
          );
        },
      );

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final requestBody = {'job': widget.jobPost.id};

      final response = await http.post(
        Uri.parse(ApiConfig.jobRequestUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.pop(loadingContext!);
      }

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final jobRequestId = responseData['id'].toString();
        setState(() {
          _jobRequestId = jobRequestId;
        });
        await _checkIfJobIsAccepted();
        _showApplicationSuccessMessage(context);
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorMessage(context, errorData['detail'] ?? 'Failed to submit application. Please try again.');
      }
    } catch (e) {
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.pop(loadingContext!);
      }
      _showErrorMessage(context, 'You have already applied for this job. Please wait for your request to be approved.');
    }
  }

  void _showApplicationSuccessMessage(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
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
              'Application Submitted!',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your application for ${widget.jobPost.title} has been sent to ${widget.jobPost.businessName}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Got it',
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
  }

  void _showSuccessMessage(BuildContext context, String message) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
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
              'Success!',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'OK',
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
  }

  void _showErrorMessage(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Oops!',
          style: TextStyle(color: Colors.blue.shade900),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.blue.shade800),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: Colors.blue.shade700)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}