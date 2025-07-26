import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Homepage/detailspage.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class AppliedJobsPage extends StatefulWidget {
  const AppliedJobsPage({Key? key}) : super(key: key);

  @override
  State<AppliedJobsPage> createState() => _AppliedJobsPageState();
}

class _AppliedJobsPageState extends State<AppliedJobsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allJobRequests = [];
  List<Map<String, dynamic>> _filteredJobRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AppLanguage appLanguage;
  
  // Filter states
  String _selectedFilter = 'all'; // 'all', 'accepted', 'applied', 'cancelled'

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _fetchAppliedJobs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _filterJobs(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'all') {
        _filteredJobRequests = List.from(_allJobRequests);
      } else {
        _filteredJobRequests = _allJobRequests.where((jobRequest) {
          final status = jobRequest['request']['status']?.toString().toLowerCase() ?? '';
          switch (filter) {
            case 'accepted':
              return status == 'accepted';
            case 'applied':
              return status == 'applied' || status == 'pending';
            case 'cancelled':
              return status.contains('cancelled');
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  int _getCountForFilter(String filter) {
    if (filter == 'all') return _allJobRequests.length;
    
    return _allJobRequests.where((jobRequest) {
      final status = jobRequest['request']['status']?.toString().toLowerCase() ?? '';
      switch (filter) {
        case 'accepted':
          return status == 'accepted';
        case 'applied':
          return status == 'applied' || status == 'pending';
        case 'cancelled':
          return status.contains('cancelled');
        default:
          return true;
      }
    }).length;
  }

  Future<void> _fetchAppliedJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allJobRequests = [];
      _filteredJobRequests = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          _errorMessage = 'No access token found. Please log in.';
          _isLoading = false;
        });
        return;
      }

      // Fetch job requests
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
        final List<Map<String, dynamic>> enrichedJobRequests = [];

        // Fetch job details for each request
        for (var request in jobRequests) {
          try {
            final jobResponse = await http.get(
              Uri.parse('${ApiConfig.jobListUrl}${request['job']}/'),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              },
            );

            if (jobResponse.statusCode == 200) {
              final jobData = jsonDecode(jobResponse.body);
              final jobPost = JobPost.fromJson(jobData);

              // Optionally fetch driver profile to calculate distance
              final driverProfile = await _fetchDriverProfile(accessToken);
              if (driverProfile != null) {
                jobPost.calculateDistanceFrom(
                  driverProfile.latitude,
                  driverProfile.longitude,
                );
              }

              enrichedJobRequests.add({
                'request': request,
                'job': jobPost,
              });
            } else {
              print('Failed to fetch job details for job ID ${request['job']}: ${jobResponse.statusCode}');
              enrichedJobRequests.add({
                'request': request,
                'job': JobPost(
                  id: request['job'],
                  title: 'Job Details Unavailable',
                  businessName: 'Unknown',
                  complimentaryBenefits: [],
                  createdAt: '',
                  businessId: 0,
                  businessLatitude: 0.0,
                  businessLongitude: 0.0,
                  jobDate: request['created_at']?.substring(0, 10) ?? 'TBD',
                ),
              });
            }
          } catch (e) {
            print('Error fetching job details for job ID ${request['job']}: $e');
            enrichedJobRequests.add({
              'request': request,
              'job': JobPost(
                id: request['job'],
                title: 'Job Details Unavailable',
                businessName: 'Unknown',
                complimentaryBenefits: [],
                createdAt: '',
                businessId: 0,
                businessLatitude: 0.0,
                businessLongitude: 0.0,
                jobDate: request['created_at']?.substring(0, 10) ?? 'TBD',
              ),
            });
          }
        }

        if (mounted) {
          setState(() {
            _allJobRequests = enrichedJobRequests;
            _filterJobs(_selectedFilter); // Apply current filter
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Authentication failed. Please log in again.';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load applied jobs: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading applied jobs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<DriverProfile?> _fetchDriverProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.driverProfileUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return DriverProfile.fromJson(jsonResponse);
      }
    } catch (e) {
      print('Error fetching driver profile: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverNavigationBar(theme),
          SliverToBoxAdapter(
            child: _buildFilterTabs(theme),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _isLoading
                  ? _buildLoadingState(theme)
                  : _errorMessage != null
                      ? _buildErrorState(theme)
                      : _filteredJobRequests.isEmpty
                          ? _buildEmptyState(theme)
                          : _buildJobList(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverNavigationBar(CupertinoThemeData theme) {
    return CupertinoSliverNavigationBar(
      largeTitle: Text(
        appLanguage.get('Applied_Jobs'),
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: theme.barBackgroundColor,
      border: null,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.back,
          color: CupertinoColors.activeBlue,
          size: 28,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.refresh,
          color: CupertinoColors.activeBlue,
          size: 28,
        ),
        onPressed: _fetchAppliedJobs,
      ),
    );
  }

  Widget _buildFilterTabs(CupertinoThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab(
            'all',
            'All',
            CupertinoColors.systemBlue,
            theme,
          ),
          _buildFilterTab(
            'accepted',
            'Accepted',
            CupertinoColors.systemGreen,
            theme,
          ),
          _buildFilterTab(
            'applied',
            'Applied',
            CupertinoColors.systemYellow,
            theme,
          ),
          _buildFilterTab(
            'cancelled',
            'Cancelled',
            CupertinoColors.systemRed,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String title, Color color, CupertinoThemeData theme) {
    final isSelected = _selectedFilter == filter;
    final count = _isLoading ? 0 : _getCountForFilter(filter);
    
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _filterJobs(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.textStyle.copyWith(
                  color: isSelected ? color : CupertinoColors.label,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? color : CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(CupertinoThemeData theme) {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.barBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(11.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildErrorState(CupertinoThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Something Went Wrong',
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.systemRed,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.systemRed,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minSize: 36,
            onPressed: _fetchAppliedJobs,
            child: const Text('Try Again', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CupertinoThemeData theme) {
    String emptyMessage;
    IconData emptyIcon;
    
    switch (_selectedFilter) {
      case 'accepted':
        emptyMessage = 'No accepted jobs found';
        emptyIcon = CupertinoIcons.checkmark_circle;
        break;
      case 'applied':
        emptyMessage = 'No applied jobs found';
        emptyIcon = CupertinoIcons.clock;
        break;
      case 'cancelled':
        emptyMessage = 'No cancelled jobs found';
        emptyIcon = CupertinoIcons.xmark_circle;
        break;
      default:
        emptyMessage = appLanguage.get('no_applied_Jobs');
        emptyIcon = CupertinoIcons.briefcase;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            color: CupertinoColors.systemGrey,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            emptyMessage,
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (_selectedFilter == 'all')
            Text(
              '''You haven't applied for any jobs yet. Browse available jobs to get started!''',
              style: theme.textTheme.textStyle.copyWith(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildJobList(CupertinoThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: _filteredJobRequests.asMap().entries.map((entry) {
          final index = entry.key;
          final jobRequest = entry.value['request'];
          final JobPost job = entry.value['job'];
          
          // Determine status text and color based on the status field
          final status = jobRequest['status'] ?? 'pending';
          final (statusText, statusColor) = _getStatusInfo(status);

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => JobDetailPage(jobPost: job),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.barBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBusinessImage(job),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    job.title,
                                    style: theme.textTheme.textStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: statusColor,
                                    ),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: theme.textTheme.textStyle.copyWith(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.businessName,
                              style: theme.textTheme.textStyle.copyWith(
                                color: CupertinoColors.systemBlue,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildInfoChip(
                                  icon: CupertinoIcons.calendar,
                                  text: job.jobDate ?? 'TBD',
                                  color: CupertinoColors.systemBlue,
                                  theme: theme,
                                ),
                                if (job.distanceMiles != null) ...[
                                  const SizedBox(width: 6),
                                  _buildInfoChip(
                                    icon: CupertinoIcons.location_solid,
                                    text: formatDistance(job.distanceMiles),
                                    color: _getDistanceColor(job.distanceMiles),
                                    theme: theme,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.tertiaryLabel,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  (String, Color) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return ('Accepted', CupertinoColors.systemGreen);
      case 'pending':
        return ('Pending', CupertinoColors.systemYellow);
      case 'applied':
        return ('Applied', CupertinoColors.systemBlue);
      case 'cancelled_by_driver':
        return ('Cancelled', CupertinoColors.systemOrange);
      case 'cancelled_by_shopkeeper':
        return ('Cancelled', CupertinoColors.systemRed);
      default:
        return (status, CupertinoColors.systemGrey);
    }
  }

  Widget _buildBusinessImage(JobPost job, {double size = 70}) {
    if (job.businessImage != null && job.businessImage!.isNotEmpty) {
      String imageUrl = job.businessImage!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.getImageUrl}$imageUrl';
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(11.5),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            return loadingProgress == null
                ? child
                : _buildImagePlaceholder(size);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(size);
          },
        ),
      );
    }
    return _buildImagePlaceholder(size);
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey4,
        borderRadius: BorderRadius.circular(11.5),
      ),
      child: Icon(
        CupertinoIcons.building_2_fill,
        color: CupertinoColors.systemGrey,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
    required CupertinoThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.textStyle.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDistanceColor(double? distance) {
    if (distance == null) return CupertinoColors.systemOrange;
    if (distance < 2) return CupertinoColors.systemGreen;
    if (distance < 5) return CupertinoColors.systemBlue;
    return CupertinoColors.systemOrange;
  }
}