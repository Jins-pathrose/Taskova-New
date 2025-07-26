import 'package:flutter/material.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_new/View/Homepage/homepage.dart';

class JobDetailProvider with ChangeNotifier {
  final JobPost jobPost;
  
  String? _jobRequestId;
  bool _isLoading = false;
  bool _hasApplied = false;
  String? _chatRoomId;
  String? _driverId;
  String _status = 'pending';
  bool _hasSubmittedReview = false;
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  JobDetailProvider(this.jobPost);

  // Getters
  String? get jobRequestId => _jobRequestId;
  bool get isLoading => _isLoading;
  bool get hasApplied => _hasApplied;
  String? get chatRoomId => _chatRoomId;
  String? get driverId => _driverId;
  String get status => _status;
  bool get hasSubmittedReview => _hasSubmittedReview;
  double get rating => _rating;
  TextEditingController get reviewController => _reviewController;

  // Setters with notifyListeners()
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set rating(double value) {
    _rating = value;
    notifyListeners();
  }

  Future<void> checkIfAlreadyApplied() async {
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
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final List<dynamic> jobRequests = decoded['data'];
        final appliedJob = jobRequests.firstWhere(
          (request) => request['job'] == jobPost.id,
          orElse: () => null,
        );

        if (appliedJob != null) {
          _jobRequestId = appliedJob['id'].toString();
          _status = appliedJob['status'] ?? 'pending';
          _hasApplied = true;
          await checkIfJobIsAccepted();
        } else {
          _hasApplied = false;
          _status = 'pending';
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error checking applied jobs: $e');
      _hasApplied = false;
      _status = 'pending';
      notifyListeners();
    }
  }

  Future<void> checkIfJobIsAccepted() async {
    if (_jobRequestId == null) return;

    _isLoading = true;
    notifyListeners();

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
        _status = data['status'] ?? 'pending';
        _chatRoomId = data['chat_room_id']?.toString();
        _driverId = data['driver_id']?.toString();
        notifyListeners();
      }
    } catch (e) {
      print('Error checking job status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication error: Access token is missing.');
      }

      if (jobPost.id == null || jobPost.businessId == null) {
        throw Exception('Error: Job ID or Business ID is missing.');
      }
      if (_rating <= 0) {
        throw Exception('Please provide a rating.');
      }

      final requestBody = {
        'rater_type': 'user',
        'ratee_type': 'business',
        'job': jobPost.id,
        'ratee': jobPost.businessId,
        'rating': _rating.toInt(),
        'comment': _reviewController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(ApiConfig.ratingUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final reviewKey = 'review_submitted_${jobPost.id}';
        await prefs.setBool(reviewKey, true);
        _reviewController.clear();
        _rating = 0.0;
        _hasSubmittedReview = true;
        notifyListeners();
      } else {
        String errorMessage = 'Failed to submit review. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error submitting review: $e');
      rethrow;
    }
  }

  Future<void> submitJobApplication() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final profileResponse = await http.get(
        Uri.parse(ApiConfig.profileStatusUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        if (profileData['is_approved'] != true) {
          _isLoading = false;
          notifyListeners();
          throw Exception(profileData['is_document_complete'] == true 
              ? 'DocumentVerificationPending' 
              : 'DocumentIncomplete');
        }
      } else {
        throw Exception('Failed to check profile status');
      }

      final requestBody = {
        'job': jobPost.id,
        'status': 'applied',
      };

      final response = await http.post(
        Uri.parse(ApiConfig.jobRequestUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _jobRequestId = responseData['id']?.toString();
        _status = responseData['status'] ?? 'applied';
        _hasApplied = true;
        notifyListeners();
      } else {
        String errorMessage = 'Failed to submit application. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Application error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelJob(String reason) async {
    if (_jobRequestId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse(ApiConfig.cancelJobByDriverUrl(_jobRequestId!)),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cancellation_reason': reason}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _status = 'cancelled_by_driver';
        notifyListeners();
      } else {
        String errorMessage = 'Failed to cancel job. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error cancelling job: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}