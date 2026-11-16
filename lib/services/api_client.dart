import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);

  @override
  String toString() => message;
}

/// Thin JSON client for the Lick It Laravel API. Adds the bearer token,
/// turns validation errors into readable messages and signs the user out when
/// the server says the token is no longer valid.
class Api {
  static const _tokenKey = 'lickit_token';
  static String? _token;
  static final http.Client _client = http.Client();

  /// Called when the server answers 401 (token expired / account disabled).
  static void Function()? onUnauthorized;

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_tokenKey);
  }

  static Future<void> saveToken(String? token) async {
    _token = token;
    final p = await SharedPreferences.getInstance();
    if (token == null) {
      await p.remove(_tokenKey);
    } else {
      await p.setString(_tokenKey, token);
    }
  }

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<Map<String, dynamic>> get(String path) =>
      _send('GET', path);
  static Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send('POST', path, body: body);
  static Future<Map<String, dynamic>> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);
  static Future<Map<String, dynamic>> delete(String path) =>
      _send('DELETE', path);

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final req = http.Request(method, _uri(path))
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';
    if (hasToken) req.headers['Authorization'] = 'Bearer $_token';
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _client.send(req).timeout(ApiConfig.timeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('The server took too long to answer. Please try again.');
    } on SocketException {
      throw ApiException("Can't reach the server. Check your connection.");
    } on http.ClientException {
      throw ApiException("Can't reach the server. Check your connection.");
    }

    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      try {
        final d = jsonDecode(res.body);
        if (d is Map<String, dynamic>) json = d;
      } catch (_) {
        if (res.statusCode >= 400) {
          throw ApiException('Unexpected server response (${res.statusCode}).', res.statusCode);
        }
      }
    }

    if (res.statusCode == 401) {
      await saveToken(null);
      onUnauthorized?.call();
      throw ApiException('Please sign in again.', 401);
    }
    if (res.statusCode >= 400) {
      var msg = (json['message'] as String?) ?? 'Something went wrong (${res.statusCode}).';
      final errors = json['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) msg = first.first.toString();
      }
      throw ApiException(msg, res.statusCode);
    }
    return json;
  }
}
