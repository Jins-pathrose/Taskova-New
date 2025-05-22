import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  double? distanceMiles;  // Distance from driver in miles

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
      driverLat, driverLng, 
      businessLatitude, businessLongitude
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
  bool isLoading = true;
  String? errorMessage;
  DriverProfile? driverProfile;

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
              driverProfile!.longitude
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
      navigationBar: CupertinoNavigationBar(
        middle: Text("Nearby Jobs"),
        backgroundColor: Colors.blue[700],
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Add Cupertino-style refresh control
            CupertinoSliverRefreshControl(
              onRefresh: _refreshData,
            ),
            SliverToBoxAdapter(
              child: isLoading
                  ? Center(child: CupertinoActivityIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red)))
                      : Column(
                          children: [
                            // Location info banner
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              color: Colors.blue[100],
                              child: Text(
                                driverProfile != null
                                    ? 'Your location: ${driverProfile!.latitude.toStringAsFixed(4)}, ${driverProfile!.longitude.toStringAsFixed(4)}'
                                    : 'Location not available',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
            ),
            // Job list as a SliverList
            isLoading || errorMessage != null
                ? SliverToBoxAdapter(child: Container())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = jobPosts[index];
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
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Business Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildBusinessImage(job, size: 80),
                                  ),
                                  const SizedBox(width: 16),
                                  // Main content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Distance badge
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            formatDistance(job.distanceMiles),
                                            style: TextStyle(
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          job.title,
                                          style: TextStyle(
                                            color: Colors.blue[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          job.businessName,
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Start: ${job.startTime ?? 'N/A'} - End: ${job.endTime ?? 'N/A'}',
                                          style: TextStyle(color: Colors.blue[700]),
                                        ),
                                        Text(
                                          '''Pay: ${job.hourlyRate != null ? '\$${job.hourlyRate}/hr' : ''} ${job.hourlyRate != null && job.perDeliveryRate != null ? ' + ' : ''} ${job.perDeliveryRate != null ? '\$${job.perDeliveryRate}/delivery' : ''}''',
                                          style: TextStyle(color: Colors.blue[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Arrow icon
                                  Icon(CupertinoIcons.forward, color: Colors.blue[700]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: jobPosts.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
