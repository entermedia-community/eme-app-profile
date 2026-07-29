import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testu_cl/utils/log.dart';
import '../models/user.dart';

class AuthService {
  static const String mediaDBRoot =
      // 'https://minsur.genailabs.tech/site/mediadb';
      'http://localhost.com:8080/site/mediadb';

  static String? _token;
  static String? _userId;
  static User? _currentUser;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('entermediakey');
    _userId = prefs.getString('user');

    if (isLoggedIn) {
      try {
        await fetchUser();
      } catch (e) {
        logPrint('Error fetching user on startup');
      }
    }
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  static String? get token => _token;
  static String? get userId => _userId;
  static User? get currentUser => _currentUser;

  static Future<User?> fetchUser() async {
    if (_token == null || _token!.isEmpty) return null;

    final url = Uri.parse('$mediaDBRoot/services/authentication/user.json');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': _token!,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        logPrint("data: $data");
        final userJson = data['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        if (_currentUser!.id.isNotEmpty) {
          _userId = _currentUser!.id;
        }
        return _currentUser;
      }
    } catch (e) {
      logPrint('Failed to fetch user');
    }
    return null;
  }

  static Future<Map<String, String>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user');
    _token = prefs.getString('entermediakey');
    return {'user': _userId!, 'entermediakey': _token!};
  }

  static Future<void> saveCredentials(String userId, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', userId);
    await prefs.setString('entermediakey', key);
    _token = key;
    _userId = userId;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('entermediakey');
    _token = null;
    _userId = null;
    _currentUser = null;
  }

  static Future<void> sendMagicLink(String email) async {
    final url = Uri.parse(
      '$mediaDBRoot/services/authentication/sendmagiclink.json',
    );
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, String> body = {'email': email};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final responseObj = data['response'];
        if (responseObj != null && responseObj['status'] == 'ok') {
          return;
        } else {
          final errorMsg =
              responseObj?['message'] ?? 'Failed to send magic link';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception(
          'Failed to send magic link: Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to send magic link: $e');
    }
  }

  static Future<bool> _authenticate(Map<String, dynamic> requestBody) async {
    final url = Uri.parse('$mediaDBRoot/services/authentication/getkey.json');
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final responseObj = data['response'];
        if (responseObj != null && responseObj['status'] == 'ok') {
          final userId = responseObj['user']?.toString() ?? '';
          final results = data['results'];
          final key = results?['entermediakey']?.toString() ?? '';

          if (userId.isNotEmpty && key.isNotEmpty) {
            await saveCredentials(userId, key);

            final userJson = results?['user'];
            if (userJson is Map<String, dynamic>) {
              _currentUser = User.fromJson(userJson);
            } else {
              await fetchUser();
            }

            return true;
          } else {
            throw Exception('Authentication response missing user ID or key');
          }
        } else {
          final errorMsg = responseObj?['message'] ?? 'Authentication failed';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception(
          'Authentication failed: Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  static Future<bool> loginWithOtp(String email, String otp) async {
    return _authenticate({'email': email, 'templogincode': otp});
  }
}
