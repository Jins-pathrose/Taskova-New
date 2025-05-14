import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/Model/api_config.dart';

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

// Business Model
class Business {
  final int id;
  final String name;
  final String? image;
  final String? logo;
  
  Business({
    required this.id,
    required this.name,
    this.image,
    this.logo,
  });
  
  factory Business.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      // If not a map, create a default business with just an ID
      if (json is int) {
        return Business(id: json, name: "Business #$json");
      }
      return Business(id: 0, name: "Unknown Business");
    }
    
    final data = _safeMap(json);
    return Business(
      id: data.get<int>('id') ?? 0,
      name: data.get<String>('name') ?? "Unnamed Business",
      image: data.get<String>('image'),
      logo: data.get<String>('logo'),
    );
  }
}

// Job Post Model
class JobPost {
  final int id;
  final String title;
  final String? description;
  final String? startTime;
  final String? endTime;
  final double? hourlyRate;
  final double? perDeliveryRate;
  final List<dynamic>? complimentaryBenefits;
  final String createdAt;
  final Business business;

  JobPost({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.hourlyRate,
    this.perDeliveryRate,
    this.complimentaryBenefits,
    required this.createdAt,
    required this.business,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    // Handle business data correctly
    final business = Business.fromJson(json['business']);
    
    // Safely parse numeric values
    double? parseDoubleValue(dynamic value) {
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
    
    return JobPost(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unnamed Job',
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      hourlyRate: parseDoubleValue(json['hourly_rate']),
      perDeliveryRate: parseDoubleValue(json['per_delivery_rate']),
      complimentaryBenefits: json['complimentary_benefits'] ?? [],
      createdAt: json['created_at'] ?? '',
      business: business,
    );
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

  @override
  void initState() {
    super.initState();
    fetchJobPosts();
  }

  // Helper method to build business image
  Widget _buildBusinessImage(Business business, {double size = 80}) {
    // Try image first, then logo, then fallback to placeholder
    String? imageUrl = business.image ?? business.logo;
    
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder(size);
        },
      );
    } else {
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
        setState(() {
          jobPosts = jsonResponse.map((job) => JobPost.fromJson(job)).toList();
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Job Posts", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
      ),
      child: SafeArea(
        child: isLoading
            ? Center(child: CupertinoActivityIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red)))
                : ListView.builder(
                    itemCount: jobPosts.length,
                    itemBuilder: (context, index) {
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
                                  child: _buildBusinessImage(job.business, size: 80),
                                ),
                                const SizedBox(width: 16),
                                // Main content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                        job.business.name,
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start Time: ${job.startTime ?? 'N/A'}',
                                        style: TextStyle(color: Colors.blue[700]),
                                      ),
                                      Text(
                                        'End Time: ${job.endTime ?? 'N/A'}',
                                        style: TextStyle(color: Colors.blue[700]),
                                      ),
                                      Text(
                                        '''Hourly Rate: ${job.hourlyRate?.toStringAsFixed(2) ?? 'N/A'}''',
                                        style: TextStyle(color: Colors.blue[700]),
                                      ),
                                      Text(
                                        '''Per Delivery Rate: ${job.perDeliveryRate?.toStringAsFixed(2) ?? 'N/A'}''',
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
                  ),
      ),
      backgroundColor: Colors.blue[50],
    );
  }
}

// Job Detail Page
class JobDetailPage extends StatelessWidget {
  final JobPost jobPost;

  const JobDetailPage({Key? key, required this.jobPost}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(jobPost.title, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Business Image
              jobPost.business.image != null
                ? Image.network(
                    jobPost.business.image!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(CupertinoIcons.building_2_fill, 
                            size: 60, 
                            color: Colors.grey[600]
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(CupertinoIcons.building_2_fill, 
                        size: 60, 
                        color: Colors.grey[600]
                      ),
                    ),
                  ),
              // Business Name
              Container(
                width: double.infinity,
                color: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(
                  jobPost.business.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Job Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Description', jobPost.description ?? 'No description available'),
                    const SizedBox(height: 16),
                    _buildDetailSection('Start Time', jobPost.startTime ?? 'N/A'),
                    const SizedBox(height: 16),
                    _buildDetailSection('End Time', jobPost.endTime ?? 'N/A'),
                    const SizedBox(height: 16),
                    _buildDetailSection('Hourly Rate', 
                      jobPost.hourlyRate != null 
                        ? '${jobPost.hourlyRate?.toStringAsFixed(2)}' 
                        : 'N/A'
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection('Per Delivery Rate', 
                      jobPost.perDeliveryRate != null 
                        ? '${jobPost.perDeliveryRate?.toStringAsFixed(2)}' 
                        : 'N/A'
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.blue[50],
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
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = jobPost.complimentaryBenefits ?? [];
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
                  children: benefits.map((benefit) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• $benefit',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 16,
                        ),
                      ),
                    )
                  ).toList(),
                ),
        ],
      ),
    );
  }
}