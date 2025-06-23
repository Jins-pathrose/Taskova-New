
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Chat/chat.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class JobRequestDetailPage extends StatefulWidget {
  final Map data;
  final int jobRequestId;
  final int chatRoomId;
  final int requesterId;
  final int driverId;

  JobRequestDetailPage({
    required this.data,
    required this.jobRequestId,
    required this.chatRoomId,
    required this.requesterId,
    required this.driverId,
  });

  @override
  _JobRequestDetailPageState createState() => _JobRequestDetailPageState();
}

class _JobRequestDetailPageState extends State<JobRequestDetailPage> {
  bool isProcessing = false;
  late String _currentStatus;
  late AppLanguage appLanguage;

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _currentStatus = widget.data['status'] ?? 'pending';
  }

  Future<void> _updateRequestStatus(String status) async {
    try {
      setState(() {
        isProcessing = true;
        _currentStatus = status;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      
      final url = (ApiConfig.updateRequestStatusUrl(widget.jobRequestId.toString()));
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        // Show success message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(status == 'accepted' ? 'Job Accepted' : 'Job Rejected'),
            content: Text(status == 'accepted' 
                ? appLanguage.get('You_have_successfully_accepted_this_job_request.')
                : appLanguage.get('You_have_rejected_this_job_request.')),
            actions: [
              CupertinoDialogAction(
                child: Text(appLanguage.get('ok')),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ],
          ),
        );
      } else {
        // Revert status if failed
        setState(() {
          _currentStatus = widget.data['status'] ?? 'pending';
        });
        // Show error message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to update status. Please try again.'),
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
      debugPrint('Error updating status: $e');
      // Revert status on error
      setState(() {
        _currentStatus = widget.data['status'] ?? 'pending';
      });
    } finally {
      setState(() => isProcessing = false);
    }
  }

void _handleAccept() {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(appLanguage.get('Accept_Job')),
      content: Text(appLanguage.get('Are_you_sure_you_want_to_accept_this_job_request?')),
      actions: [
        CupertinoDialogAction(
          child: Text(appLanguage.get('cancel')),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text(appLanguage.get('Accept')),
          onPressed: () async {
            Navigator.pop(context);
            await _updateRequestStatus('accepted');
          },
        ),
      ],
    ),
  );
}


  void _handleReject() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(appLanguage.get('Reject_Job')),
        content: Text(appLanguage.get('Are_you_sure_you_want_to_reject_this_job_request?')),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Reject'),
            onPressed: () async {
              Navigator.pop(context);
              await _updateRequestStatus('rejected');
            },
          ),
        ],
      ),
    );
  }

  void _handleChat() {
    if (widget.chatRoomId == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Chat Not Available'),
          content: Text('Chat room ID is missing for this request.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ChatPage(
          driverId: widget.driverId.toString(),
          chatRoomId: widget.chatRoomId.toString(),
          businessName: widget.data['requested_by']['name'] ?? 'Business',
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentStatus == 'accepted') {
      return Row(
        children: [
          // Chat button
          Expanded(
            child: Container(
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                onPressed: _handleChat,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.chat_bubble,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Accepted status indicator
          Expanded(
            flex: 2,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGreen,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'You accepted this job',
                  style: TextStyle(
                    color: CupertinoColors.systemGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_currentStatus == 'rejected') {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemRed,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Job request rejected',
            style: TextStyle(
              color: CupertinoColors.systemRed,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      // Pending status - show all buttons
      return Row(
        children: [
          // Reject button
          Expanded(
            child: Container(
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(12),
                onPressed: isProcessing ? null : _handleReject,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.xmark_circle,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reject',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Chat button
          Expanded(
            child: Container(
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                onPressed: isProcessing ? null : _handleChat,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.chat_bubble,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Accept button
          Expanded(
            child: Container(
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(12),
                onPressed: isProcessing ? null : _handleAccept,
                child: isProcessing
                    ? CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle,
                            color: CupertinoColors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Accept',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.data['job'];
    final requester = widget.data['requested_by'];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Job Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with requester info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: CupertinoColors.systemGrey6,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                "http://192.168.20.29:8001${requester['image']}",
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: CupertinoColors.systemGrey5,
                                    child: Icon(
                                      CupertinoIcons.person_alt_circle,
                                      size: 40,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "${requester['name']}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 16,
                                color: CupertinoColors.systemBlue,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "${requester['address']}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Job details card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Job Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Job title
                          _buildDetailRow(
                            icon: CupertinoIcons.briefcase,
                            title: "Job Title",
                            value: "${job['title']}",
                            color: CupertinoColors.systemBlue,
                          ),
                          
                          // Description
                          _buildDetailRow(
                            icon: CupertinoIcons.doc_text,
                            title: "Description",
                            value: "${job['description']}",
                            color: CupertinoColors.systemGreen,
                          ),
                          
                          // Date and time
                          _buildDetailRow(
                            icon: CupertinoIcons.calendar,
                            title: "Date",
                            value: "${job['job_date']}",
                            color: CupertinoColors.systemOrange,
                          ),
                          
                          _buildDetailRow(
                            icon: CupertinoIcons.clock,
                            title: "Time",
                            value: "${job['start_time']} - ${job['end_time']}",
                            color: CupertinoColors.systemPurple,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Payment information
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payment Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        CupertinoIcons.money_pound_circle,
                                        size: 24,
                                        color: CupertinoColors.systemOrange,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Hourly Rate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '£${job['hourly_rate']}/hr',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: CupertinoColors.systemOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        CupertinoIcons.cube_box,
                                        size: 24,
                                        color: CupertinoColors.systemPurple,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Per Delivery',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '£${job['per_delivery_rate']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: CupertinoColors.systemPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Location details
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          _buildDetailRow(
                            icon: CupertinoIcons.location,
                            title: "Address",
                            value: "${requester['address']}",
                            color: CupertinoColors.systemRed,
                          ),
                          
                          _buildDetailRow(
                            icon: CupertinoIcons.location_circle,
                            title: "Postcode",
                            value: "${requester['postcode']}",
                            color: CupertinoColors.systemTeal,
                          ),
                          
                          _buildDetailRow(
                            icon: CupertinoIcons.map,
                            title: "Coordinates",
                            value: "${requester['latitude']}, ${requester['longitude']}",
                            color: CupertinoColors.systemIndigo,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
            
            // Bottom action buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: _buildActionButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.black,
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
}