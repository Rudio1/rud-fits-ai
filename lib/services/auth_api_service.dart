import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rud_fits_ai/core/api_config.dart';

final class AuthRequestResult {
  const AuthRequestResult({
    required this.ok,
    required this.statusCode,
    this.message,
    this.body,
  });

  final bool ok;
  final int statusCode;
  final String? message;
  final Map<String, dynamic>? body;

  static AuthRequestResult fromResponse(http.Response response) {
    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } catch (_) {}
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    String? msg;
    if (!ok) {
      msg =
          json?['message'] as String? ??
          json?['title'] as String? ??
          json?['detail'] as String? ??
          (json?.values.isNotEmpty == true ? response.body : null) ??
          'Erro ${response.statusCode}';
    }

    return AuthRequestResult(
      ok: ok,
      statusCode: response.statusCode,
      message: msg,
      body: json,
    );
  }

  static AuthRequestResult fromException(Object e, StackTrace st) {
    final text = e.toString();
    if (e is http.ClientException ||
        text.contains('SocketException') ||
        text.contains('Connection refused') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable')) {
      return AuthRequestResult(
        ok: false,
        statusCode: 0,
        message:
            'Sem conexão com a API (${ApiConfig.baseUrl})',
      );
    }
    return AuthRequestResult(ok: false, statusCode: 0, message: text);
  }
}

abstract final class AuthApiService {
  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<AuthRequestResult> register({
    required String fullName,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _uri('/Auth/register'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'username': username,
          'password': password,
        }),
      );
      return AuthRequestResult.fromResponse(response);
    } catch (e, st) {
      return AuthRequestResult.fromException(e, st);
    }
  }

  static Future<AuthRequestResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _uri('/Auth/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return AuthRequestResult.fromResponse(response);
    } catch (e, st) {
      return AuthRequestResult.fromException(e, st);
    }
  }
}
