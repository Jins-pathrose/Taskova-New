import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.jobPost.title,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.blue[50],
      child: SafeArea(
        child: Stack(
          children: [
            // Content
            SingleChildScrollView(
              // Add padding at the bottom to prevent content from being covered by the apply button
              padding: EdgeInsets.only(bottom: 100),
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
                        // Distance badge
                        if (widget.jobPost.distanceKm != null)
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
                              formatDistance(widget.jobPost.distanceKm),
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

            // Apply Button - Fixed at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _handleJobApplication(context),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
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
                          CupertinoIcons.paperplane_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Apply for this Job',
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
    // Ensure the image URL is properly formatted
    if (widget.jobPost.businessImage != null &&
        widget.jobPost.businessImage!.isNotEmpty) {
      String imageUrl = widget.jobPost.businessImage!;
      if (!imageUrl.startsWith('http')) {
        // If it's a relative URL, prepend the base URL
        imageUrl = 'https://anjalitechfifo.pythonanywhere.com${imageUrl}';
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
                  // Close the dialog first
                  Navigator.pop(dialogContext);

                  // Create a BuildContext variable to track the loading dialog context
                  BuildContext? loadingContext;

                  try {
                    // Show loading indicator
                    showCupertinoDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext ctx) {
                        loadingContext = ctx;
                        return Center(
                          child: CupertinoActivityIndicator(radius: 15),
                        );
                      },
                    );

                    // Fetch profile status from API
                    final prefs = await SharedPreferences.getInstance();
                    final accessToken = prefs.getString('access_token');
                    final response = await http.get(
                      Uri.parse(
                        'https://anjalitechfifo.pythonanywhere.com/api/profile-status/',
                      ),
                      headers: {
                        'Authorization': 'Bearer $accessToken',
                        'Content-Type': 'application/json',
                      },
                    );

                    // Make sure to close the loading dialog before further navigation
                    if (loadingContext != null &&
                        Navigator.canPop(loadingContext!)) {
                      Navigator.pop(loadingContext!);
                    }

                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      final bool isDocumentComplete =
                          data['is_document_complete'] ?? false;
                      final bool isApproved = data['is_approved'] ?? false;

                      if (!isDocumentComplete) {
                        // Navigate to document registration page
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => DocumentRegistrationPage(),
                            fullscreenDialog: true, //
                          ),
                        );
                      } else if (!isApproved) {
                        // Navigate to a wrapper that contains only the DocumentRegistrationPage
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder:
                                (context) => CupertinoPageScaffold(
                                  navigationBar: CupertinoNavigationBar(
                                    middle: Text('Please wait for approval'),
                                    backgroundColor: Colors.blue[700],
                                  ),
                                  child: DocumentVerificationPendingScreen(),
                                ),
                          ),
                        );
                      } else {
                        // Both conditions are true, proceed with application
                        // Here you would make the API call to submit the application
                        // After successful submission:
                        _showApplicationSuccessMessage(context);
                      }
                    } else {
                      // Handle API error
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: Text('Error'),
                              content: Text(
                                'Failed to check profile status. Please try again.',
                              ),
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
                    if (loadingContext != null &&
                        Navigator.canPop(loadingContext!)) {
                      Navigator.pop(loadingContext!);
                    }

                    // Show error dialog
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
                            title: Text('Error'),
                            content: Text('An error occurred: ${e.toString()}'),
                            actions: [
                              CupertinoDialogAction(
                                child: Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),
            ],
          ),
    );
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
          if (widget.jobPost.distanceKm != null) ...[
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
                  'Distance: ${formatDistance(widget.jobPost.distanceKm)}',
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
