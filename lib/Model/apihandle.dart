import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart'; // Your config file

class ApiService {
  static final http.Client _client = http.Client();

  // GET request example
  static Future<http.Response> getRequest(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');

    http.Response response = await _client.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    // Token expired
    if (response.statusCode == 401) {
      final newAccessToken = await _refreshToken(refreshToken!);
      if (newAccessToken != null) {
        await prefs.setString('access_token', newAccessToken);

        // Retry the original request
        response = await _client.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $newAccessToken',
            'Content-Type': 'application/json',
          },
        );
      }
    }

    return response;
  }

  // POST request (you can copy this and make PUT, DELETE etc.)
  static Future<http.Response> postRequest(String url, Map<String, dynamic> body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');

    http.Response response = await _client.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final newAccessToken = await _refreshToken(refreshToken!);
      if (newAccessToken != null) {
        await prefs.setString('access_token', newAccessToken);

        response = await _client.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $newAccessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );
      }
    }

    return response;
  }

  // Token refresh logic
  static Future<String?> _refreshToken(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['access'];
    }

    return null;
  }
}
