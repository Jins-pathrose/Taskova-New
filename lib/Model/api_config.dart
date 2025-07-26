import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'http://default-fallback-url.com';
  }
  
  static String get forgotPasswordUrl {
    return '$baseUrl/api/forgot-password/';
  }
  
  static String get loginUrl {
    return '$baseUrl/api/login/';
  }

  static String get registerUrl {
    return '$baseUrl/api/register/';
  }
  static String get verifyOtpUrl {
    return '$baseUrl/api/verify-otp/';
  }
  static String get resetPasswordUrl {
    return '$baseUrl/api/reset-password/';
  }
  static String get driverProfileUrl {
    return '$baseUrl/api/driver-profile/';
  }
  
  static String get driverDocumentUrl {
    return '$baseUrl/api/driver-documents/';
  }
  static String get logoutUrl {
    return '$baseUrl/api/logout/';
  }
  static String get resendOtpUrl {
    return '$baseUrl/api/resend-otp/';
  }
  static String get profileStatusUrl {
    return '$baseUrl/api/profile-status/';
  }
  static String get googleLoginUrl {
    return '$baseUrl/social_auth/google-login/';
  }
  static String get jobListUrl {
    return '$baseUrl/api/job-posts/';
  }
  static String get jobRequestUrl {
    return '$baseUrl/api/job-requests/';
  }
  static String get jobRequestsAcceptedUrl {
    return '$baseUrl/api/job-requests/accepted/';
  }
  static String get notificaionUrl {
    return '$baseUrl/api/notifications/';
  }
  static String get ratingUrl {
    return '$baseUrl/api/ratings/';
  }
  static String get jobRequestsListUrl {
    return '$baseUrl/api/job-requests/list/';
  }
  static String get getImageUrl {
    return baseUrl;
  }
  static String cancelJobByDriverUrl(String jobRequestId) {
  return '$baseUrl/api/job-request/$jobRequestId/cancel-by-driver/';
}
  static String jobApplicationUrl(String driverId) {
  return '$baseUrl/api/job-application/driver/$driverId/requests/';
}
  static String updateRequestStatusUrl(String requestId) {
  return '$baseUrl/api/job-application/request/$requestId/update-status/';
}
static String get driverMonthlyJobCountUrl {
    return '$baseUrl/api/driver/monthly-job-count/';
  }

}