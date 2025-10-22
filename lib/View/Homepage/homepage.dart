import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Controller/Jobstatus/jobstatus.dart';
import 'package:taskova_new/Controller/Theme/theme.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/Homepage/detailspage.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:video_player/video_player.dart';

// Extension for safely accessing map values
extension SafeAccess on Map<String, dynamic> {
  T? get<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    return null;
  }
}

// Models
class DriverProfile {
  final double latitude;
  final double longitude;

  DriverProfile({required this.latitude, required this.longitude});

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
    );
  }

  factory DriverProfile.defaultProfile() =>
      DriverProfile(latitude: 0.0, longitude: 0.0);
}

class Business {
  final int id;
  final String name;
  final String? image;

  Business({required this.id, required this.name, this.image});
}

class JobPost {
  final int id;
  final String title;
  final String? description;
  final String? startTime;
  final String? endTime;
  final double? hourlyRate;
  final double? perDeliveryRate;
  final List<dynamic> complimentaryBenefits;
  final String createdAt;
  final int businessId;
  final String businessName;
  final String? businessImage;
  final double businessLatitude;
  final double businessLongitude;
  double? distanceMiles;
  final String? jobDate;
  final String? address; // Added address property
  final String? subscriptionPlanName;

  JobPost({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.hourlyRate,
    this.perDeliveryRate,
    required this.complimentaryBenefits,
    required this.createdAt,
    required this.businessId,
    required this.businessName,
    this.businessImage,
    required this.businessLatitude,
    required this.businessLongitude,
    this.distanceMiles,
    this.jobDate,
    this.address, // Include address in constructor
    this.subscriptionPlanName,
  });

  Business get business =>
      Business(id: businessId, name: businessName, image: businessImage);

  factory JobPost.fromJson(Map<String, dynamic> json) {
    final businessDetail = json['business_detail'] as Map<String, dynamic>?;
    return JobPost(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unnamed Job',
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      jobDate: json['job_date'],
      hourlyRate: _parseDouble(json['hourly_rate']),
      perDeliveryRate: _parseDouble(json['per_delivery_rate']),
      complimentaryBenefits: json['complimentary_benefits'] ?? [],
      createdAt: json['created_at'] ?? '',
      businessId: businessDetail?['id'] ?? 0,
      businessName:
          businessDetail?['name'] ?? 'Unknown Business', // Updated source
      businessImage: businessDetail?['image'] ?? '',
      businessLatitude: _parseDouble(businessDetail?['latitude']) ?? 0.0,
      businessLongitude: _parseDouble(businessDetail?['longitude']) ?? 0.0,
      address: businessDetail?['address'], // Added address
      subscriptionPlanName: json['subscription_plan_name'], // Add this line
    );
  }

  void calculateDistanceFrom(double driverLat, double driverLng) {
    distanceMiles = calculateDistanceInMiles(
      driverLat,
      driverLng,
      businessLatitude,
      businessLongitude,
    );
  }
}

// Utility Functions
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

double calculateDistanceInMiles(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371;
  const kmToMiles = 0.621371;

  final lat1Rad = _degreesToRadians(lat1);
  final lon1Rad = _degreesToRadians(lon1);
  final lat2Rad = _degreesToRadians(lat2);
  final lon2Rad = _degreesToRadians(lon2);

  final dLat = lat2Rad - lat1Rad;
  final dLon = lon2Rad - lon1Rad;
  final a =
      pow(sin(dLat / 2), 2) +
      cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final distanceKm = earthRadiusKm * c;
  return distanceKm * kmToMiles;
}

double _degreesToRadians(double degrees) => degrees * (pi / 180);

String formatDistance(double? distanceMiles) {
  if (distanceMiles == null) return 'Unknown distance';
  if (distanceMiles < 1) {
    final feet = (distanceMiles * 5280).round();
    return '$feet ft';
  } else if (distanceMiles < 10) {
    return '${distanceMiles.toStringAsFixed(1)} mi';
  }
  return '${distanceMiles.round()} mi';
}

// Home Page Widget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<JobPost> _jobPosts = [];
  List<JobPost> _filteredJobPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  DriverProfile? _driverProfile;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _userName;
  double _radiusFilter = 30.0; // Default to 30 miles
  bool _showRadiusFilter = false; // Add this line
  late AppLanguage appLanguage;
  static const Color _darkmode = Color.fromARGB(255, 46, 15, 149);
  static const Color _darkGradientEnd = Color.fromARGB(255, 43, 33, 99);
  Map<String, dynamic>? _activeJobRequest;
  bool _isLoadingJobRequest = false;
  bool _isVideoInitialized = false;
  late VideoPlayerController _videoController;
  final GoogleSignIn _googleSignIn = GoogleSignIn();


  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);

    WidgetsBinding.instance.addObserver(this);
    _searchFocusNode.unfocus();
    _loadData();
    _initializeVideoPlayer();
    
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _videoController.dispose();

    super.dispose();
  }
Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        print('No refresh token found'); // Debug
        return false;
      }

      final response = await http.post(
        Uri.parse('https://taskova.co.uk/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      print('Token refresh response: ${response.statusCode} ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        final newRefreshToken = data['refresh'] ?? refreshToken; // Fallback to old refresh token

        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);
        print('Token refreshed successfully'); // Debug
        return true;
      } else {
        print('Token refresh failed: ${response.statusCode}'); // Debug
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e'); // Debug
      return false;
    }
  }
  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/logogif.mp4');

    _videoController.initialize().then((_) {
      _videoController.setLooping(true);
      _videoController.setVolume(0.0);
      _videoController.play();
      setState(() {
        _isVideoInitialized = true; // Add this line
      });
    });
  }

  Future<void> _loadData() async {
    try {
      await _fetchDriverProfile();
      await _fetchActiveJobRequest();
      await _fetchJobPosts();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchActiveJobRequest() async {
    try {
      setState(() {
        _isLoadingJobRequest = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          _isLoadingJobRequest = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://taskova.co.uk/api/job-requests/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> jobRequests = jsonResponse['data'] ?? [];

        // Find the completed job request
        final completedJob = jobRequests.firstWhere(
          (job) => job['status'] == 'completed' && job['job_is_active'] == true,
          orElse: () => null,
        );

        setState(() {
          _activeJobRequest = completedJob;
          _isLoadingJobRequest = false;
        });
      } else {
        setState(() {
          _isLoadingJobRequest = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingJobRequest = false;
      });
      print('Error fetching job request: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _jobPosts = [];
      _filteredJobPosts = [];
      _searchQuery = '';
      _radiusFilter = 30.0; // Add this line
      _showRadiusFilter = false; // Add this line

      _searchController.clear();
      _driverProfile = null;
    });
    await _loadData();
  }

  Future<void> _fetchDriverProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userName =
          prefs.getString('user_name')?.trim() ??
          'Driver'; // Fallback from SharedPreferences
      print('Retrieved user_name from SharedPreferences: "$userName"'); // Debug

      setState(() {
        _userName = userName; // Set initial username
        if (accessToken == null || accessToken.isEmpty) {
          
          _isLoading = false;
        }
      });

      if (accessToken == null || accessToken.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.driverProfileUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(
          'Driver profile API response: $jsonResponse',
        ); // Debug API response
        setState(() {
          _driverProfile = DriverProfile.fromJson(jsonResponse);
          // Use 'name' field from API, fallback to SharedPreferences value
          final apiUserName = jsonResponse['name']?.toString().trim();
          _userName =
              (apiUserName != null && apiUserName.isNotEmpty)
                  ? apiUserName
                  : _userName;
          print('Updated user_name: "$_userName"'); // Debug final username
        });
      } else if (response.statusCode == 401) {
        await _refreshToken();
        print(response.statusCode);
        print('6666666666666666666666666666666666666666666666666666666');
        // setState(() {
        //   _errorMessage = 'Authentication failed. Please log in again.';
        //   _isLoading = false;
        // });
      } else {
        logout(context);
      }
    } catch (e) {
      // setState(() {
      //   _errorMessage = 'Error fetching driver profile: $e';
      //   _driverProfile = DriverProfile.defaultProfile();
      // });
      print('Error in _fetchDriverProfile: $e'); // Debug error
    }
  }
 Future<void> logout(BuildContext context) async {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    
  }
  Future<void> _fetchJobPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null || accessToken.isEmpty) {
        setState(() {

Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.jobListUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as List<dynamic>;
        List<JobPost> posts =
            jsonResponse.map((job) => JobPost.fromJson(job)).toList();

        if (_driverProfile != null) {
          // Calculate distances for all jobs
          for (var post in posts) {
            post.calculateDistanceFrom(
              _driverProfile!.latitude,
              _driverProfile!.longitude,
            );
          }

          // Filter jobs based on subscription plan distance requirements
          posts =
              posts.where((job) {
                final isPremium =
                    job.subscriptionPlanName?.toLowerCase().contains(
                      'premium',
                    ) ??
                    false;
                if (isPremium) {
                  return job.distanceMiles != null && job.distanceMiles! <= 30;
                } else {
                  return job.distanceMiles != null && job.distanceMiles! <= 5;
                }
              }).toList();

          // Sort jobs - premium first, then by distance
          posts.sort((a, b) {
            // Premium jobs first
            final aIsPremium =
                a.subscriptionPlanName?.toLowerCase().contains('premium') ??
                false;
            final bIsPremium =
                b.subscriptionPlanName?.toLowerCase().contains('premium') ??
                false;

            if (aIsPremium && !bIsPremium) return -1;
            if (!aIsPremium && bIsPremium) return 1;

            // Then sort by distance
            if (a.distanceMiles == null && b.distanceMiles == null) return 0;
            if (a.distanceMiles == null) return 1;
            if (b.distanceMiles == null) return -1;
            return a.distanceMiles!.compareTo(b.distanceMiles!);
          });
        }

        setState(() {
          _jobPosts = posts;
          _filteredJobPosts = posts;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
                await _refreshToken();

      } else {
        logout(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _applyRadiusFilter() {
    setState(() {
      _filteredJobPosts =
          _jobPosts.where((job) {
            // Check subscription plan and distance requirements
            final isPremium =
                job.subscriptionPlanName?.toLowerCase().contains('premium') ??
                false;
            final isBasic =
                !isPremium; // Assuming if not premium then it's basic

            // Apply distance limits based on plan
            if (isPremium &&
                (job.distanceMiles == null || job.distanceMiles! > 30)) {
              return false;
            }
            if (isBasic &&
                (job.distanceMiles == null || job.distanceMiles! > 5)) {
              return false;
            }

            // Apply search filter
            final matchesSearch =
                _searchQuery.isEmpty ||
                job.businessName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (job.address?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (job.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);

            return matchesSearch;
          }).toList();
    });
  }

  void _toggleRadiusFilter() {
    setState(() {
      _showRadiusFilter = !_showRadiusFilter;
    });
  }

  void _filterJobPosts(String query) {
    setState(() {
      _searchQuery = query;
      _applyRadiusFilter();
      if (query.isEmpty) {
        _filteredJobPosts = _jobPosts;
      } else {
        final queryLower = query.toLowerCase();
        _filteredJobPosts =
            _jobPosts.where((job) {
              return job.businessName.toLowerCase().contains(queryLower) ||
                  job.title.toLowerCase().contains(queryLower) ||
                  (job.address?.toLowerCase().contains(queryLower) ?? false) ||
                  (job.description?.toLowerCase().contains(queryLower) ??
                      false);
            }).toList();
      }
    });
  }

  Widget _buildBusinessImage(JobPost job, {double size = 70}) {
    if (job.businessImage != null && job.businessImage!.isNotEmpty) {
      String imageUrl = job.businessImage!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${ApiConfig.getImageUrl}$imageUrl';
        print(imageUrl);
      } else {}

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

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = CupertinoTheme.of(context);

        return CupertinoPageScaffold(
          backgroundColor: Colors.transparent,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              appLanguage.get('Nearby_Jobs'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color
                    
                        : CupertinoColors.black,
              ),
            ),
            backgroundColor:
                themeProvider.isDarkMode
                    ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8)
                    : theme.barBackgroundColor,
            border: null,
          ),
          child: Container(
            decoration:
                 const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: _refreshData,
                    refreshTriggerPullDistance: 100,
                    refreshIndicatorExtent: 60,
                  ),
                  _buildHeaderSection(theme, themeProvider),
                  _buildContentSection(theme, themeProvider),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadiusFilter(
    CupertinoThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
             CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLanguage.get('Radius_Filter'),
                style: theme.textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color:
                       const Color.fromARGB(255, 70, 70, 70),
                ),
              ),
              Text(
                '${_radiusFilter.round()} ${_radiusFilter == 30 ? '+ miles' : 'miles'}',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoSlider(
            value: _radiusFilter,
            min: 1.0,
            max: 30.0,
            divisions: 29,
            activeColor: CupertinoColors.systemBlue,
            onChanged: (value) {
              setState(() {
                _radiusFilter = value;
              });
              _applyRadiusFilter();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToActiveJob() {
    if (_activeJobRequest != null) {
      final jobId = _activeJobRequest!['job'];

      // Find the job post with matching ID
      final jobPost = _jobPosts.firstWhere(
        (job) => job.id == jobId,
        // orElse: () => null,
      );

      if (jobPost != null) {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder:
                (context) => ChangeNotifierProvider(
                  create: (_) => JobStatusProvider(),
                  child: JobDetailPage(jobPost: jobPost),
                ),
          ),
        );
      }
    }
  }

  Widget _buildHeaderSection(
    CupertinoThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              themeProvider.isDarkMode
                  ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7)
                  : theme.barBackgroundColor,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show active job status if available
            if (_activeJobRequest != null && !_isLoadingJobRequest) ...[
              GestureDetector(
                onTap: _navigateToActiveJob,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 110, 110, 110).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              _isVideoInitialized
                                  ? VideoPlayer(_videoController)
                                  : Container(
                                    color: Colors.white.withOpacity(0.1),
                                    child: const Icon(
                                      CupertinoIcons.play_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You are currently working',
                              style: GoogleFonts.oswald(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 51, 51, 51),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Job ID: ${_activeJobRequest!['job']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 163, 162, 162),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 86, 85, 85).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.chevron_right,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Show regular header content if no active job
            if (_activeJobRequest == null && !_isLoadingJobRequest) ...[
              if (_userName != null)
                Text(
                  '${appLanguage.get('Hi,')} $_userName',
                  style: GoogleFonts.oswald(
                    textStyle: theme.textTheme.navTitleTextStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color
                              : CupertinoColors.black,
                    ),
                  ),
                ),
              if (_userName != null) const SizedBox(height: 8),
              Text(
                appLanguage.get('Discover_Opportunities'),
                style: theme.textTheme.navTitleTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appLanguage.get('Find_jobs_near_you'),
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Show loading state
            if (_isLoadingJobRequest) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const CupertinoActivityIndicator(radius: 10),
                    const SizedBox(width: 12),
                    Text(
                      'Checking job status...',
                      style: theme.textTheme.textStyle.copyWith(
                        color: CupertinoColors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildSearchBar(theme, themeProvider),
            if (_showRadiusFilter) _buildRadiusFilter(theme, themeProvider),
            if (!_isLoading && _errorMessage == null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: CupertinoIcons.briefcase,
                    label: appLanguage.get('Jobs'),
                    value: '${_filteredJobPosts.length}',
                    theme: theme,
                    themeProvider: themeProvider,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: CupertinoColors.separator,
                  ),
                  _buildStatItem(
                    icon: CupertinoIcons.location_circle,
                    label: appLanguage.get('Nearby'),
                    value:
                        '${_filteredJobPosts.where((job) => job.distanceMiles != null && job.distanceMiles! < 5).length}',
                    theme: theme,
                    themeProvider: themeProvider,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    CupertinoThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              placeholder: appLanguage.get('Search_jobs,_companies...'),
              placeholderStyle: theme.textTheme.textStyle.copyWith(
                color: const Color.fromARGB(75, 0, 0, 0),
                fontSize: 14,
              ),
              style: theme.textTheme.textStyle.copyWith(fontSize: 14),
              decoration: const BoxDecoration(),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.systemBlue,
                  size: 18,
                ),
              ),
              suffix:
                  _searchQuery.isNotEmpty
                      ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _filterJobPosts('');
                            _searchFocusNode.unfocus();
                          },
                          child: const Icon(
                            CupertinoIcons.clear_circled,
                            color: CupertinoColors.systemGrey,
                            size: 18,
                          ),
                        ),
                      )
                      : null,
              onChanged: _filterJobPosts,
            ),
          ),
          // Filter Icon Button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minSize: 0,
            onPressed: _toggleRadiusFilter,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    _showRadiusFilter
                        ? CupertinoColors.systemBlue.withOpacity(0.1)
                        : CupertinoColors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                CupertinoIcons.slider_horizontal_3,
                color:
                    _showRadiusFilter
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    CupertinoThemeData theme,
    ThemeProvider themeProvider,
  ) {
    if (_isLoading) return _buildLoadingState(theme, themeProvider);
    // if (_errorMessage != null) return _buildErrorState(theme);
    if (_filteredJobPosts.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState(theme);
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildJobCard(
            context,
            _filteredJobPosts[index],
            index,
            theme,
            themeProvider,
          ),
          childCount: _filteredJobPosts.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState(
    CupertinoThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                 CupertinoColors.systemGrey6,
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
                      color: CupertinoColors.systemGrey5,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      color: CupertinoColors.systemGrey5,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 80,
                      height: 10,
                      color:
                           CupertinoColors.systemGrey5,
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
        childCount: 3,
      ),
    );
  }

  Widget _buildNoResultsState(CupertinoThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.search,
              color: CupertinoColors.systemGrey,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              '${appLanguage.get('No_Jobs_Found_for')} "$_searchQuery"',
              style: theme.textTheme.textStyle.copyWith(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              appLanguage.get('Try_a_different_search_term.'),
              style: theme.textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minSize: 36,
              onPressed: () {
                _searchController.clear();
                _filterJobPosts('');
                _searchFocusNode.unfocus();
              },
              child: Text(
                appLanguage.get('Clear_Search'),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required CupertinoThemeData theme,
    required ThemeProvider themeProvider,
  }) {
    return Column(
      children: [
        Icon(icon, color: CupertinoColors.systemBlue, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.textStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:
                CupertinoColors.black,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.textStyle.copyWith(
            color:
                CupertinoColors.secondaryLabel,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

 Widget _buildJobCard(
  BuildContext context,
  JobPost job,
  int index,
  CupertinoThemeData theme,
  ThemeProvider themeProvider,
) {
  final isUrgent = job.distanceMiles != null && job.distanceMiles! < 2;
  final isHighPay =
      (job.hourlyRate ?? 0) > 20 || (job.perDeliveryRate ?? 0) > 8;
  final isPremium =
      job.subscriptionPlanName?.toLowerCase().contains('premium') ?? false;

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
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => JobStatusProvider(),
                child: JobDetailPage(jobPost: job),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:  const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color:  const Color.fromARGB(255, 1, 1, 1).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              // Subtle top highlight for depth
              BoxShadow(
                color:  const Color.fromARGB(255, 207, 207, 207).withOpacity(0.8),
                blurRadius: 1,
                offset: const Offset(0, -1),
                spreadRadius: 0,
              ),
              // Additional depth shadow
              BoxShadow(
                color:  const Color.fromARGB(255, 212, 211, 211).withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... rest of your existing code remains the same
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    ),
                    child: _buildBusinessImage(job),
                  ),
                  if (isPremium)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:  theme.barBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.star_fill,
                          color: CupertinoColors.black,
                          size: 10,
                        ),
                      ),
                    ),
                  if (!isPremium && isUrgent)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:  theme.barBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.flame,
                          color: CupertinoColors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: theme.textTheme.textStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color:  CupertinoColors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isHighPay)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'HIGH PAY',
                              style: theme.textTheme.textStyle.copyWith(
                                color: CupertinoColors.systemGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
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
                    if (job.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        job.address!,
                        style: theme.textTheme.textStyle.copyWith(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: CupertinoIcons.location_solid,
                          text: formatDistance(job.distanceMiles),
                          color: _getDistanceColor(job.distanceMiles),
                          theme: theme,
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(width: 6),
                        _buildInfoChip(
                          icon: CupertinoIcons.clock,
                          text: job.startTime ?? 'N/A',
                          color: CupertinoColors.systemBlue,
                          theme: theme,
                          themeProvider: themeProvider,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        
                        Expanded(
                          child: Text(
                            _formatPayInfo(job),
                            style: theme.textTheme.textStyle.copyWith(
                              color: CupertinoColors.systemGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color:  CupertinoColors.tertiaryLabel,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
    required CupertinoThemeData theme,
    required ThemeProvider themeProvider,
  }) {
    // Adjust color opacity based on dark mode
    final chipColor =
       color.withOpacity(0.1);

    // Adjust text color for better visibility in dark mode
    final textColor = color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
        border:
             null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.textStyle.copyWith(
              color: textColor,
              fontSize: 12,
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

  String _formatPayInfo(JobPost job) {
    final payParts = <String>[];
    if (job.hourlyRate != null) payParts.add('\€ ${job.hourlyRate}/hr');
    if (job.perDeliveryRate != null)
      payParts.add('\€ ${job.perDeliveryRate}/delivery');
    return payParts.isEmpty ? 'Pay TBD' : payParts.join(' + ');
  }
}
