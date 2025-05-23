import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Homepage/detailspage.dart';

// Extension for safely accessing map values
extension SafeAccess on Map<String, dynamic> {
  T? get<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    return null;
  }
}

// Utility function to safely parse API response
Map<String, dynamic> _safeMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return {};
}

// Driver Profile Model
class DriverProfile {
  final double latitude;
  final double longitude;

  DriverProfile({
    required this.latitude,
    required this.longitude,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
    );
  }

  // Default profile if we can't fetch or parse the actual profile
  factory DriverProfile.defaultProfile() {
    return DriverProfile(
      latitude: 0.0,
      longitude: 0.0,
    );
  }
}

// Business Model
class Business {
  final int id;
  final String name;
  final String? image;

  Business({
    required this.id,
    required this.name,
    this.image,
  });
}

// Job Post Model with distance information
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
  double? distanceMiles; // Distance from driver in miles

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
  });

  Business get business => Business(
        id: businessId,
        name: businessName,
        image: businessImage,
      );

  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unnamed Job',
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      hourlyRate: _parseDouble(json['hourly_rate']),
      perDeliveryRate: _parseDouble(json['per_delivery_rate']),
      complimentaryBenefits: json['complimentary_benefits'] ?? [],
      createdAt: json['created_at'] ?? '',
      businessId: json['business'] ?? 0,
      businessName: json['business_name'] ?? 'Unknown Business',
      businessImage: json['business_image'],
      businessLatitude: _parseDouble(json['business_latitude']) ?? 0.0,
      businessLongitude: _parseDouble(json['business_longitude']) ?? 0.0,
    );
  }

  // Calculate distance from driver's location in miles
  void calculateDistanceFrom(double driverLat, double driverLng) {
    distanceMiles = calculateDistanceInMiles(
      driverLat,
      driverLng,
      businessLatitude,
      businessLongitude,
    );
  }
}

// Helper function to safely parse a double from various types
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

// Calculate distance between two points in miles using the Haversine formula
double calculateDistanceInMiles(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371; // Earth radius in kilometers
  const double kmToMiles = 0.621371; // Conversion factor from km to miles

  // Convert to radians
  final double lat1Rad = _degreesToRadians(lat1);
  final double lon1Rad = _degreesToRadians(lon1);
  final double lat2Rad = _degreesToRadians(lat2);
  final double lon2Rad = _degreesToRadians(lon2);

  // Haversine formula
  final double dLat = lat2Rad - lat1Rad;
  final double dLon = lon2Rad - lon1Rad;
  final double a = pow(sin(dLat / 2), 2) +
      cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final double distanceKm = earthRadiusKm * c;
  final double distanceMiles = distanceKm * kmToMiles;

  return distanceMiles;
}

// Helper function to convert degrees to radians
double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}

// Format distance for display in miles
String formatDistance(double? distanceMiles) {
  if (distanceMiles == null) return 'Unknown distance';

  if (distanceMiles < 1) {
    // Convert to feet if less than 0.1 miles (528 feet)
    final int feet = (distanceMiles * 5280).round();
    return '$feet ft';
  } else if (distanceMiles < 10) {
    // Show one decimal place if less than 10 miles
    return '${distanceMiles.toStringAsFixed(1)} mi';
  } else {
    // Round to nearest mile if 10 miles or more
    return '${distanceMiles.round()} mi';
  }
}

// Home Page with Job Posts List
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<JobPost> jobPosts = [];
  List<JobPost> filteredJobPosts = []; // List for filtered job posts
  bool isLoading = true;
  String? errorMessage;
  DriverProfile? driverProfile;
  String _searchQuery = ''; // State for search query

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Load all required data
  Future<void> loadData() async {
    try {
      // First get the driver profile to get current location
      await fetchDriverProfile();

      // Then fetch job posts and calculate distances
      await fetchJobPosts();
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Refresh data method
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      jobPosts = [];
      filteredJobPosts = [];
      _searchQuery = '';
      driverProfile = null;
    });
    await loadData();
  }

  // Fetch the driver's profile including their location
  Future<void> fetchDriverProfile() async {
    try {
      // Retrieve the access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      // Check if access token exists
      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          errorMessage = 'No access token found. Please log in.';
          isLoading = false;
        });
        return;
      }

      // Make the API call with the access token in the header
      final response = await http.get(
        Uri.parse(ApiConfig.driverProfileUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      // Handle the response
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          driverProfile = DriverProfile.fromJson(jsonResponse);
        });
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be expired
        setState(() {
          errorMessage = 'Authentication failed. Please log in again.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load driver profile. Status code: ${response.statusCode}';
          // Use default profile if we can't get the actual one
          driverProfile = DriverProfile.defaultProfile();
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching driver profile: ${e.toString()}';
        // Use default profile in case of error
        driverProfile = DriverProfile.defaultProfile();
      });
    }
  }

  // Fetch job posts and calculate distance from driver
  Future<void> fetchJobPosts() async {
    try {
      // Retrieve the access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      // Check if access token exists
      if (accessToken == null || accessToken.isEmpty) {
        setState(() {
          errorMessage = 'No access token found. Please log in.';
          isLoading = false;
        });
        return;
      }

      // Make the API call with the access token in the header
      final response = await http.get(
        Uri.parse(ApiConfig.jobListUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      // Handle the response
      if (response.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> jsonResponse = json.decode(response.body);

        // Convert to JobPost objects
        final List<JobPost> posts = jsonResponse
            .map((job) => JobPost.fromJson(job))
            .toList();

        // Calculate distances if we have driver location
        if (driverProfile != null) {
          for (var post in posts) {
            post.calculateDistanceFrom(
              driverProfile!.latitude,
              driverProfile!.longitude,
            );
          }

          // Sort by distance (nearest first)
          posts.sort((a, b) {
            if (a.distanceMiles == null && b.distanceMiles == null) return 0;
            if (a.distanceMiles == null) return 1;
            if (b.distanceMiles == null) return -1;
            return a.distanceMiles!.compareTo(b.distanceMiles!);
          });
        }

        setState(() {
          jobPosts = posts;
          filteredJobPosts = posts; // Initialize filtered list
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be expired
        setState(() {
          errorMessage = 'Authentication failed. Please log in again.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load job posts. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Filter job posts based on search query
  void _filterJobPosts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredJobPosts = jobPosts;
      } else {
        filteredJobPosts = jobPosts
            .where((job) =>
                job.businessName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Helper method to build business image
  Widget _buildBusinessImage(JobPost job, {double size = 80}) {
    // Try to load the business image
    if (job.businessImage != null && job.businessImage!.isNotEmpty) {
      // Ensure the image URL is properly formatted
      String imageUrl = job.businessImage!;

      // Print the original image URL for debugging
      print('Original image URL: $imageUrl');

      if (!imageUrl.startsWith('http')) {
        // If it's a relative URL, prepend the base URL
        imageUrl = '${ApiConfig.getImageUrl}$imageUrl';

        // Print the constructed URL for debugging
        print('Constructed image URL: $imageUrl');
      }

      // Try to make a test request to see if the image exists
      try {
        final uri = Uri.parse(imageUrl);
        HttpClient().headUrl(uri).then((request) => request.close()).then((response) {
          print('Image URL status code: ${response.statusCode}');
          if (response.statusCode != 200) {
            print('Image not found at URL: $imageUrl');
          }
        });
      } catch (e) {
        print('Error checking image URL: $e');
      }

      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          print('Image loading progress: $loadingProgress');
          return _buildImagePlaceholder(size);
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image loading error: $error');
          print(stackTrace);
          return _buildImagePlaceholder(size);
        },
      );
    } else {
      print('No business image provided');
      return _buildImagePlaceholder(size);
    }
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Icon(
        CupertinoIcons.building_2_fill,
        color: Colors.grey[600],
        size: size * 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Discover Jobs",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            // Cupertino-style refresh control
            CupertinoSliverRefreshControl(
              onRefresh: _refreshData,
            ),

            // Search and header section
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CupertinoColors.systemBlue.withOpacity(0.1),
                      CupertinoColors.systemBackground,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome text with fade animation
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Text(
                              "Find your next opportunity",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.label,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8),

                    // Subtitle with delayed fade
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 15 * (1 - value)),
                            child: Text(
                              "Jobs near you, updated in real-time",
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.secondaryLabel,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),

                    // Search box with animation
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CupertinoTextField(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                placeholder: "Search jobs, companies, or locations...",
                                placeholderStyle: TextStyle(
                                  color: CupertinoColors.placeholderText,
                                  fontSize: 16,
                                ),
                                style: TextStyle(fontSize: 16),
                                decoration: BoxDecoration(),
                                prefix: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    CupertinoIcons.search,
                                    color: CupertinoColors.systemBlue,
                                    size: 20,
                                  ),
                                ),
                                onChanged: _filterJobPosts, // Call filter function on text change
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Job listings
            isLoading
                ? _buildShimmerJobList()
                : errorMessage != null
                    ? SliverToBoxAdapter(
                        child: _buildErrorState(),
                      )
                    : filteredJobPosts.isEmpty && _searchQuery.isNotEmpty
                        ? SliverToBoxAdapter(
                            child: _buildNoResultsState(),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final job = filteredJobPosts[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 600 + (index * 100)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - value)),
                                        child: _buildJobCard(job, index),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: filteredJobPosts.length,
                            ),
                          ),
          ],
        ),
      ),
    );
  }

  // No results state widget for empty search results
  Widget _buildNoResultsState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            color: CupertinoColors.systemGrey,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            "No jobs found for '$_searchQuery'",
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          CupertinoButton.filled(
            child: Text("Clear Search"),
            onPressed: () {
              _filterJobPosts('');
            },
          ),
        ],
      ),
    );
  }

  // Shimmer loading effect
  Widget _buildShimmerJobList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shimmer image placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment(-1.0 + value * 2, 0.0),
                            end: Alignment(1.0 + value * 2, 0.0),
                            colors: [
                              CupertinoColors.systemGrey5,
                              CupertinoColors.systemGrey6,
                              CupertinoColors.systemGrey5,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shimmer badge
                            Container(
                              width: 80,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment(-1.0 + value * 2, 0.0),
                                  end: Alignment(1.0 + value * 2, 0.0),
                                  colors: [
                                    CupertinoColors.systemGrey5,
                                    CupertinoColors.systemGrey6,
                                    CupertinoColors.systemGrey5,
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            // Shimmer title
                            Container(
                              width: double.infinity,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment(-1.0 + value * 2, 0.0),
                                  end: Alignment(1.0 + value * 2, 0.0),
                                  colors: [
                                    CupertinoColors.systemGrey5,
                                    CupertinoColors.systemGrey6,
                                    CupertinoColors.systemGrey5,
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Shimmer company
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment(-1.0 + value * 2, 0.0),
                                  end: Alignment(1.0 + value * 2, 0.0),
                                  colors: [
                                    CupertinoColors.systemGrey5,
                                    CupertinoColors.systemGrey6,
                                    CupertinoColors.systemGrey5,
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            // Shimmer details
                            Container(
                              width: 200,
                              height: 14,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment(-1.0 + value * 2, 0.0),
                                  end: Alignment(1.0 + value * 2, 0.0),
                                  colors: [
                                    CupertinoColors.systemGrey5,
                                    CupertinoColors.systemGrey6,
                                    CupertinoColors.systemGrey5,
                                  ],
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
            },
          );
        },
        childCount: 6, // Show 6 shimmer items
      ),
    );
  }

  // Enhanced job card with animations
  Widget _buildJobCard(JobPost job, int index) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => JobDetailPage(jobPost: job),
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[100]!, // Light blue
                Colors.blue[100]!,// Dark blue
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced business image with hero animation
                Hero(
                  tag: "job_image_${job.id}",
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemBlue.withOpacity(0.2),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildBusinessImage(job, size: 80),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Enhanced main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance badge with glow effect
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CupertinoColors.systemGreen.withOpacity(0.2),
                              CupertinoColors.systemGreen.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CupertinoColors.systemGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.location_solid,
                              color: CupertinoColors.systemGreen,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              formatDistance(job.distanceMiles),
                              style: TextStyle(
                                color: CupertinoColors.systemGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // Job title with enhanced typography
                      Text(
                        job.title,
                        style: TextStyle(
                          color: CupertinoColors.label,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),

                      // Business name with icon
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.building_2_fill,
                            color: CupertinoColors.systemBlue,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              job.businessName,
                              style: TextStyle(
                                color: CupertinoColors.systemBlue,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Time info with enhanced styling
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            color: CupertinoColors.secondaryLabel,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${job.startTime ?? 'N/A'} - ${job.endTime ?? 'N/A'}',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),

                      // Pay info with enhanced styling
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.money_dollar_circle,
                            color: CupertinoColors.systemGreen,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '''${job.hourlyRate != null ? '\$${job.hourlyRate}/hr' : ''} ${job.hourlyRate != null && job.perDeliveryRate != null ? ' + ' : ''} ${job.perDeliveryRate != null ? '\$${job.perDeliveryRate}/delivery' : ''}''',
                              style: TextStyle(
                                color: CupertinoColors.systemGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Enhanced arrow with subtle animation
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 2000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(2 * math.sin(value * 2 * math.pi), 0),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemBlue,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }

  // Error state widget
  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            errorMessage!,
            style: TextStyle(
              color: CupertinoColors.systemRed,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          CupertinoButton.filled(
            child: Text("Try Again"),
            onPressed: _refreshData,
          ),
        ],
      ),
    );
  }
}