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

class _JobDetailPageState extends State<JobDetailPage> {
  String? _jobRequestId;
  bool _isAccepted = false;
  bool _isLoading = false;
  String? _chatRoomId;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyApplied();
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
          _chatRoomId = data['chat_room_id']?.toString(); // Add this line
          _driverId =data['driver_id']?.toString(); // Add this line
        });
        print(_driverId);
        print(_chatRoomId);
        print('****************************************************************************************************************');
      }
    } catch (e) {
      print('Error checking job acceptance: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.jobPost.title),
        backgroundColor: Colors.blue[700],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Content
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: _isAccepted ? 160 : 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large Business Image
                  _buildBusinessImage(),
                  // Business Name with distance
                  Container(
                    width: double.infinity,
                    color: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.jobPost.businessName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.jobPost.distanceMiles != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              formatDistance(widget.jobPost.distanceMiles),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Job Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection(
                          'Description',
                          widget.jobPost.description ??
                              'No description available',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          'Start Time',
                          widget.jobPost.startTime ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          'End Time',
                          widget.jobPost.endTime ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          'Hourly Rate',
                          widget.jobPost.hourlyRate != null
                              ? '\$${widget.jobPost.hourlyRate?.toStringAsFixed(2)}'
                              : 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          'Per Delivery Rate',
                          widget.jobPost.perDeliveryRate != null
                              ? '\$${widget.jobPost.perDeliveryRate?.toStringAsFixed(2)}'
                              : 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _buildLocationSection(),
                        const SizedBox(height: 16),
                        _buildBenefitsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chat Button (if job is accepted)
            if (_isAccepted)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100,
                child: GestureDetector(
                  onTap: () {
                    if (_chatRoomId != null) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (context) => ChatPage(
                                driverId: _driverId!,
                                chatRoomId: _chatRoomId!,
                                businessName: widget.jobPost.businessName,
                              ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_text_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Chat with ${widget.jobPost.businessName}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Apply Button - Fixed at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child:
                    _isLoading
                        ? Center(child: CupertinoActivityIndicator())
                        : GestureDetector(
                          onTap:
                              _isAccepted
                                  ? null // Disable button if already accepted
                                  : () => _handleJobApplication(context),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient:
                                  _isAccepted
                                      ? null
                                      : LinearGradient(
                                        colors: [
                                          Colors.blue[600]!,
                                          Colors.blue[800]!,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                              color: _isAccepted ? Colors.grey : null,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow:
                                  _isAccepted
                                      ? null
                                      : [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isAccepted
                                      ? CupertinoIcons.checkmark_alt
                                      : CupertinoIcons.paperplane_fill,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  _isAccepted
                                      ? 'Application Accepted'
                                      : 'Apply for this Job',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the business image for the detail page
  Widget _buildBusinessImage() {
    if (widget.jobPost.businessImage != null &&
        widget.jobPost.businessImage!.isNotEmpty) {
      String imageUrl = widget.jobPost.businessImage!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.getImageUrl}$imageUrl';
      }

      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                CupertinoIcons.building_2_fill,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            CupertinoIcons.building_2_fill,
            size: 60,
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }

  void _handleJobApplication(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text('Apply for ${widget.jobPost.title}'),
            content: Text(
              'Are you sure you want to apply for this job at ${widget.jobPost.businessName}?',
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Apply'),
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
      // Show loading indicator
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          loadingContext = ctx;
          return Center(child: CupertinoActivityIndicator(radius: 15));
        },
      );

      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      // Create request body
      final requestBody = {'job': widget.jobPost.id};

      // Send POST request to job-requests API
      final response = await http.post(
        Uri.parse(ApiConfig.jobRequestUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Close loading dialog
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.pop(loadingContext!);
      }

      if (response.statusCode == 201) {
        // Application submitted successfully
        final responseData = jsonDecode(response.body);
        final jobRequestId = responseData['id'].toString();
        print('Job request ID: $jobRequestId');
        print(
          '------------------------------------------------------------------------------------------------------------',
        );
        setState(() {
          _jobRequestId = jobRequestId;
        });

        // Check if job is accepted
        await _checkIfJobIsAccepted();

        _showApplicationSuccessMessage(context);
      } else {
        // Handle API error
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['detail'] ??
            'Failed to submit application. Please try again.';

        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: Text('Error'),
                content: Text(errorMessage),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.pop(loadingContext!);
      }

      // Show error dialog
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: Text('Please wait for your request to be approved'),
              content: Text("You are allready applied for this job."),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  // Success message after application is submitted
  void _showApplicationSuccessMessage(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            color: Colors.black.withOpacity(0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled,
                  color: Colors.greenAccent,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  'Application Submitted!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Your application for ${widget.jobPost.title} has been sent to ${widget.jobPost.businessName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 20),
                CupertinoButton(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(12),
                  child: Text('Got it'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.blue[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.blue[800], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Location',
            style: TextStyle(
              color: Colors.blue[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Latitude: ${widget.jobPost.businessLatitude.toStringAsFixed(6)}',
            style: TextStyle(color: Colors.blue[800], fontSize: 16),
          ),
          Text(
            'Longitude: ${widget.jobPost.businessLongitude.toStringAsFixed(6)}',
            style: TextStyle(color: Colors.blue[800], fontSize: 16),
          ),
          if (widget.jobPost.distanceMiles != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.location,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Distance: ${formatDistance(widget.jobPost.distanceMiles)}',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = widget.jobPost.complimentaryBenefits;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complimentary Benefits',
            style: TextStyle(
              color: Colors.blue[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          benefits.isEmpty
              ? Text(
                'No benefits listed',
                style: TextStyle(color: Colors.blue[800], fontSize: 16),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    benefits
                        .map(
                          (benefit) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    benefit.toString(),
                                    style: TextStyle(
                                      color: Colors.blue[800],
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
}
