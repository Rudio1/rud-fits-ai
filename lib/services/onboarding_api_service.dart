import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rud_fits_ai/core/api_config.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/services/auth_api_service.dart';

abstract final class OnboardingApiService {
  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<AuthRequestResult> submit({
    required int goal,
    required int gender,
    required int age,
    required double height,
    required double weight,
    required double startingWeight,
    required double targetWeight,
    required int activityLevel,
    required int dailyRoutineLevel,
    required int goalIntensity,
  }) async {
    try {
      final response = await http.post(
        _uri('/onboarding'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          if (AuthSession.token != null) 'Authorization': 'Bearer ${AuthSession.token}',
        },
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
      return AuthRequestResult.fromResponse(response);
    } catch (e, st) {
      return AuthRequestResult.fromException(e, st);
    }
  }
}
