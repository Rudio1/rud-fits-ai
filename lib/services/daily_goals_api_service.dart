import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rud_fits_ai/core/api_config.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/models/daily_goals.dart';

final class DailyGoalsResult {
  const DailyGoalsResult._({this.goals, this.error});

  final DailyGoals? goals;
  final String? error;

  bool get ok => goals != null;

  static DailyGoalsResult success(DailyGoals goals) =>
      DailyGoalsResult._(goals: goals);

  static DailyGoalsResult failure(String error) =>
      DailyGoalsResult._(error: error);
}

abstract final class DailyGoalsApiService {
  static Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=utf-8',
    if (AuthSession.token != null)
      'Authorization': 'Bearer ${AuthSession.token}',
  };

  static Future<DailyGoalsResult> calculate() async {
    return _request(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/Onboarding/calculate-daily-goals'),
        headers: _headers(),
      ),
      genericError: 'Não foi possível calcular suas metas.',
    );
  }

  static Future<DailyGoalsResult> fetch() async {
    return _request(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/Onboarding/daily-goals'),
        headers: _headers(),
      ),
      genericError: 'Não foi possível carregar suas metas.',
    );
  }

  static Future<DailyGoalsResult> _request(
    Future<http.Response> Function() request, {
    required String genericError,
  }) async {
    try {
      final response = await request();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DailyGoalsResult.success(DailyGoals.fromJson(json));
      }

      return DailyGoalsResult.failure('$genericError (${response.statusCode})');
    } catch (e) {
      final text = e.toString();
      if (text.contains('SocketException') ||
          text.contains('Connection refused') ||
          text.contains('Failed host lookup') ||
          text.contains('Network is unreachable')) {
        return DailyGoalsResult.failure('Sem conexão com o servidor.');
      }
      return DailyGoalsResult.failure(genericError);
    }
  }
}
