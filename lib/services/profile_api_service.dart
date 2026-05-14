import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rud_fits_ai/core/api_config.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/models/daily_goals.dart';
import 'package:rud_fits_ai/models/user_profile.dart';
final class ProfileResult {
  const ProfileResult._({this.profile, this.error});

  final UserProfile? profile;
  final String? error;

  bool get ok => profile != null;

  static ProfileResult success(UserProfile profile) =>
      ProfileResult._(profile: profile);

  static ProfileResult failure(String error) => ProfileResult._(error: error);
}

final class RecalculateDailyGoalsResult {
  const RecalculateDailyGoalsResult._({this.goals, this.error});

  final DailyGoals? goals;
  final String? error;

  bool get ok => goals != null;

  static RecalculateDailyGoalsResult success(DailyGoals goals) =>
      RecalculateDailyGoalsResult._(goals: goals);

  static RecalculateDailyGoalsResult failure(String error) =>
      RecalculateDailyGoalsResult._(error: error);
}

abstract final class ProfileApiService {
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (AuthSession.token != null)
        'Authorization': 'Bearer ${AuthSession.token}',
    };
  }

  static bool _isNetworkError(String text) {
    return text.contains('SocketException') ||
        text.contains('Connection refused') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable');
  }

  static Future<ProfileResult> fetchMe() async {
    try {
      if (AuthSession.token == null) {
        return ProfileResult.failure('Faça login para ver seu perfil.');
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/profile/me');
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return ProfileResult.failure('Resposta inválida do servidor.');
        }
        return ProfileResult.success(UserProfile.fromJson(decoded));
      }

      return ProfileResult.failure(
        'Não foi possível carregar o perfil (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return ProfileResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return ProfileResult.failure('Erro ao carregar o perfil.');
    }
  }

  static Future<RecalculateDailyGoalsResult> recalculateDailyGoals({
    required int goal,
    required int gender,
    required int age,
    required int height,
    required int weight,
    required int startingWeight,
    required int targetWeight,
    required int activityLevel,
    required int dailyRoutineLevel,
    required int goalIntensity,
  }) async {
    try {
      if (AuthSession.token == null) {
        return RecalculateDailyGoalsResult.failure(
          'Faça login para recalcular suas metas.',
        );
      }
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/profile/me/recalculate-daily-goals');
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'goal': goal,
          'gender': gender,
          'age': age,
          'height': height,
          'weight': weight,
          'startingWeight': startingWeight,
          'targetWeight': targetWeight,
          'activityLevel': activityLevel,
          'dailyRoutineLevel': dailyRoutineLevel,
          'goalIntensity': goalIntensity,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return RecalculateDailyGoalsResult.failure(
            'Resposta inválida do servidor.',
          );
        }
        return RecalculateDailyGoalsResult.success(
          DailyGoals.fromJson(decoded),
        );
      }

      return RecalculateDailyGoalsResult.failure(
        'Não foi possível recalcular as metas (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return RecalculateDailyGoalsResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return RecalculateDailyGoalsResult.failure(
        'Erro ao recalcular as metas.',
      );
    }
  }
}
