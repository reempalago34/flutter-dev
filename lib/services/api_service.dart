import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente HTTP base contra la API FastAPI de DevPlay (`/api/v1`).
///
/// Maneja los tokens JWT (access + refresh) y reintenta una vez con
/// `POST /auth/refresh` si el access token expiró (30 min).
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // ----------------------------- Tokens ---------------------------------

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ----------------------------- Requests -------------------------------

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(auth: auth);
    final encoded = body != null ? jsonEncode(body) : null;

    http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: encoded);
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encoded);
      case 'PUT':
        response = await http.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
      default:
        response = await http.get(uri, headers: headers);
    }

    // Access token expirado (401): intenta refrescarlo una sola vez.
    if (response.statusCode == 401 && auth && await _tryRefresh()) {
      final retryHeaders = await _headers(auth: auth);
      switch (method) {
        case 'POST':
          response = await http.post(uri, headers: retryHeaders, body: encoded);
        case 'PATCH':
          response = await http.patch(uri, headers: retryHeaders, body: encoded);
        case 'PUT':
          response = await http.put(uri, headers: retryHeaders, body: encoded);
        case 'DELETE':
          response = await http.delete(uri, headers: retryHeaders);
        default:
          response = await http.get(uri, headers: retryHeaders);
      }
    }
    return response;
  }

  static Future<bool> _tryRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: (data['refresh_token'] as String?) ?? refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // --------------------- Respuestas tipificadas --------------------------

  static dynamic _parse(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final detail = body is Map ? body['detail'] : null;
    throw ApiException(
      response.statusCode,
      detail?.toString() ?? 'Error ${response.statusCode}',
    );
  }

  static Future<dynamic> getJson(String path, {bool auth = true}) async =>
      _parse(await _send('GET', path, auth: auth));

  static Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async =>
      _parse(await _send('POST', path, body: body, auth: auth));

  static Future<dynamic> patchJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async =>
      _parse(await _send('PATCH', path, body: body, auth: auth));

  static Future<dynamic> deleteJson(String path, {bool auth = true}) async =>
      _parse(await _send('DELETE', path, auth: auth));

  /// `POST` con `multipart/form-data` (subida de archivos).
  ///
  /// A diferencia de [_send], no fuerza `Content-Type`: `http.MultipartRequest`
  /// ya define el boundary correcto.
  static Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

    if (auth) {
      final token = await getAccessToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parse(response);
  }
}

/// Error de la API: `statusCode` + `detail` (el mensaje de FastAPI).
class ApiException implements Exception {
  final int statusCode;
  final String detail;

  ApiException(this.statusCode, this.detail);

  @override
  String toString() => detail;
}
