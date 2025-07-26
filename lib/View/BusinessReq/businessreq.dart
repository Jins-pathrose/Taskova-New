import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';

import 'package:taskova_new/View/BusinessReq/JobRequestDetailPage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class JobRequestsPage extends StatefulWidget {
  @override
  _JobRequestsPageState createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  List jobRequests = [];
  bool isLoading = true;
  late AppLanguage appLanguage;

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    fetchDriverIdAndRequests();
  }

  Future<void> fetchDriverIdAndRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final driverId = prefs.getString('driver_id');

      if (driverId == null) {
        debugPrint('Driver ID not found in SharedPreferences.');
        setState(() => isLoading = false);
        return;
      }

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(
        Uri.parse(ApiConfig.jobApplicationUrl(driverId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          jobRequests = decoded is List ? decoded : [];
          isLoading = false;
        });
      } else {
        debugPrint(
          'Failed to fetch job requests. Code: ${response.statusCode}',
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          appLanguage.get('Job_Requests'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child:
            isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(radius: 20),
                      SizedBox(height: 16),
                      Text(
                        appLanguage.get('Loading_job_requests...'),
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : jobRequests.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.briefcase,
                        size: 80,
                        color: CupertinoColors.systemGrey3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        appLanguage.get('No_job_requests_found'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        appLanguage.get(
                          'Check_back_later_for_new_opportunities',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                )
                : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: fetchDriverIdAndRequests,
                    ),
                    SliverPadding(
                      padding: EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final req = jobRequests[index];
                          final job = req['job'];
                          final requester = req['requested_by'];

                          return GestureDetector(
                            // Inside the GestureDetector onTap:
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder:
                                      (_) => JobRequestDetailPage(
                                        data: req,
                                        jobRequestId:
                                            req['id'], // 5 in your example
                                        chatRoomId:
                                            req['chat_room_id'], // 8 in your example
                                        requesterId:
                                            requester['id'], // 10 in your example
                                        driverId:
                                            req['driver']['id'], // 27 in your example
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 236, 236, 236),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  children: [
                                    // Header with image and basic info
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Profile image
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color:
                                                  CupertinoColors.systemGrey6,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                "${ApiConfig.getImageUrl}${requester['image']}",
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    color:
                                                        CupertinoColors
                                                            .systemGrey5,
                                                    child: Icon(
                                                      CupertinoIcons
                                                          .person_alt_circle,
                                                      size: 30,
                                                      color:
                                                          CupertinoColors
                                                              .systemGrey,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          // Job info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${job['title']}",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        CupertinoColors.black,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  "${appLanguage.get('by')} ${requester['name']}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        CupertinoColors
                                                            .systemBlue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons
                                                          .location_solid,
                                                      size: 14,
                                                      color:
                                                          CupertinoColors
                                                              .systemGrey,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        "${requester['address']}",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              CupertinoColors
                                                                  .systemGrey,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Arrow icon
                                          Icon(
                                            CupertinoIcons.chevron_right,
                                            color: CupertinoColors.systemGrey2,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Job details section
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey6
                                            .withOpacity(0.5),
                                        border: Border(
                                          top: BorderSide(
                                            color: CupertinoColors.systemGrey5,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Description
                                          Text(
                                            "${job['description']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: CupertinoColors.systemGrey,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 12),

                                          // Date and time row
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: CupertinoColors
                                                      .systemBlue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.calendar,
                                                      size: 12,
                                                      color:
                                                          CupertinoColors
                                                              .systemBlue,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "${job['job_date']}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            CupertinoColors
                                                                .systemBlue,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: CupertinoColors
                                                      .systemGreen
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.clock,
                                                      size: 12,
                                                      color:
                                                          CupertinoColors
                                                              .systemGreen,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "${job['start_time']} - ${job['end_time']}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            CupertinoColors
                                                                .systemGreen,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),

                                          // Payment info
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: CupertinoColors
                                                        .systemOrange
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        appLanguage.get(
                                                          'Hourly_Rate',
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              CupertinoColors
                                                                  .systemOrange,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        '£${job['hourly_rate']}/hr',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              CupertinoColors
                                                                  .systemOrange,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: CupertinoColors
                                                        .systemPurple
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        appLanguage.get(
                                                          'Per_Delivery',
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              CupertinoColors
                                                                  .systemPurple,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        '£${job['per_delivery_rate']}',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              CupertinoColors
                                                                  .systemPurple,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: jobRequests.length),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
