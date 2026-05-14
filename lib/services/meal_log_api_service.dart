import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:rud_fits_ai/core/api_config.dart';
import 'package:rud_fits_ai/core/auth_session.dart';
import 'package:rud_fits_ai/models/analyzed_meal.dart';
import 'package:rud_fits_ai/models/daily_consumption_summary.dart';
import 'package:rud_fits_ai/models/day_meal_log.dart';
import 'package:rud_fits_ai/models/saved_meal_log.dart';

final class AnalyzedMealResult {
  const AnalyzedMealResult._({this.meal, this.error});

  final AnalyzedMeal? meal;
  final String? error;

  bool get ok => meal != null;

  static AnalyzedMealResult success(AnalyzedMeal meal) =>
      AnalyzedMealResult._(meal: meal);

  static AnalyzedMealResult failure(String error) =>
      AnalyzedMealResult._(error: error);
}

final class SavedMealLogResult {
  const SavedMealLogResult._({this.meal, this.error});

  final SavedMealLog? meal;
  final String? error;

  bool get ok => meal != null;

  static SavedMealLogResult success(SavedMealLog meal) =>
      SavedMealLogResult._(meal: meal);

  static SavedMealLogResult failure(String error) =>
      SavedMealLogResult._(error: error);
}

final class DayMealLogsResult {
  const DayMealLogsResult._({this.logs, this.error});

  final List<DayMealLogEntry>? logs;
  final String? error;

  bool get ok => logs != null;

  static DayMealLogsResult success(List<DayMealLogEntry> logs) =>
      DayMealLogsResult._(logs: logs);

  static DayMealLogsResult failure(String error) =>
      DayMealLogsResult._(error: error);
}

final class UpdateMealLogResult {
  const UpdateMealLogResult._({this.meal, this.error});

  final DayMealLogEntry? meal;
  final String? error;

  bool get ok => meal != null;

  static UpdateMealLogResult success(DayMealLogEntry meal) =>
      UpdateMealLogResult._(meal: meal);

  static UpdateMealLogResult failure(String error) =>
      UpdateMealLogResult._(error: error);
}

final class DailySummaryResult {
  const DailySummaryResult._({this.summary, this.error});

  final DailyConsumptionSummary? summary;
  final String? error;

  bool get ok => summary != null;

  static DailySummaryResult success(DailyConsumptionSummary summary) =>
      DailySummaryResult._(summary: summary);

  static DailySummaryResult failure(String error) =>
      DailySummaryResult._(error: error);
}

abstract final class MealLogApiService {
  static String? _extractErrorMessage(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] as String? ??
            decoded['title'] as String? ??
            decoded['detail'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          final parts = <String>[];
          for (final entry in errors.entries) {
            final value = entry.value;
            if (value is List) {
              for (final item in value) {
                final text = item?.toString().trim();
                if (text != null && text.isNotEmpty) {
                  parts.add(text);
                }
              }
            } else {
              final text = value?.toString().trim();
              if (text != null && text.isNotEmpty) {
                parts.add(text);
              }
            }
          }
          if (parts.isNotEmpty) {
            return parts.join(' ');
          }
        }
      }
    } catch (_) {}

    return raw;
  }

  static Map<String, String> _jsonHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = AuthSession.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static bool _isNetworkError(String text) {
    return text.contains('SocketException') ||
        text.contains('Connection refused') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable');
  }

  static Future<AnalyzedMealResult> analyzePhoto(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/meal-logs/analyze-photo');
      final request = http.MultipartRequest('POST', uri);

      if (AuthSession.token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthSession.token}';
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final meal = AnalyzedMeal.fromJson(json);
        if (meal.foods.isEmpty) {
          return AnalyzedMealResult.failure(
            'Não conseguimos identificar alimentos nessa foto. Tente outra com melhor iluminação.',
          );
        }
        return AnalyzedMealResult.success(meal);
      }

      return AnalyzedMealResult.failure(
        'Não foi possível analisar a foto (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return AnalyzedMealResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return AnalyzedMealResult.failure('Erro ao analisar a foto.');
    }
  }

  static Future<AnalyzedMealResult> estimateDetectedFoodsNutrition(
    AnalyzedMeal meal,
  ) async {
    try {
      if (AuthSession.token == null) {
        return AnalyzedMealResult.failure(
          'Faça login para calcular a nutrição da refeição.',
        );
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/meal-logs/estimate-detected-foods-nutrition',
      );
      final body = jsonEncode(meal.toEstimateRequestJson());
      final response = await http.post(
        uri,
        headers: _jsonHeaders(),
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final estimated = AnalyzedMeal.fromJson(json);
        if (estimated.foods.isEmpty) {
          return AnalyzedMealResult.failure(
            'Não foi possível estimar a nutrição. Tente novamente.',
          );
        }
        return AnalyzedMealResult.success(estimated);
      }

      return AnalyzedMealResult.failure(
        'Não foi possível estimar a nutrição (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return AnalyzedMealResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return AnalyzedMealResult.failure('Erro ao estimar a nutrição.');
    }
  }

  static Future<SavedMealLogResult> saveFromDetectedFoods({
    required int mealType,
    required DateTime consumedAtUtc,
    required List<AnalyzedFood> foodsWithIds,
  }) async {
    try {
      if (AuthSession.token == null) {
        return SavedMealLogResult.failure(
          'Faça login para registrar a refeição.',
        );
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/meal-logs/from-detected-foods',
      );
      final payload = {
        'mealType': mealType,
        'consumedAtUtc': consumedAtUtc.toUtc().toIso8601String(),
        'foods': foodsWithIds
            .map(
              (f) => {
                'foodId': f.foodId,
                'estimatedQuantityGrams': f.estimatedQuantityGrams,
              },
            )
            .toList(),
      };
      final response = await http.post(
        uri,
        headers: _jsonHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SavedMealLogResult.success(SavedMealLog.fromJson(json));
      }

      return SavedMealLogResult.failure(
        'Não foi possível salvar a refeição (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return SavedMealLogResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return SavedMealLogResult.failure('Erro ao salvar a refeição.');
    }
  }

  static String _dateQueryParam(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<DailySummaryResult> fetchDailySummary(DateTime date) async {
    try {
      if (AuthSession.token == null) {
        return DailySummaryResult.failure(
          'Faça login para ver seu consumo do dia.',
        );
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/meal-logs/daily-summary',
      ).replace(queryParameters: {'date': _dateQueryParam(date)});
      final response = await http.get(uri, headers: _jsonHeaders());

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return DailySummaryResult.failure('Resposta inválida do servidor.');
        }
        return DailySummaryResult.success(
          DailyConsumptionSummary.fromJson(decoded),
        );
      }

      return DailySummaryResult.failure(
        'Não foi possível carregar o resumo do dia (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return DailySummaryResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return DailySummaryResult.failure('Erro ao carregar o resumo do dia.');
    }
  }

  static Future<DayMealLogsResult> fetchLogsForDate(DateTime date) async {
    try {
      if (AuthSession.token == null) {
        return DayMealLogsResult.failure('Faça login para ver suas refeições.');
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/meal-logs',
      ).replace(queryParameters: {'date': _dateQueryParam(date)});
      final response = await http.get(uri, headers: _jsonHeaders());

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          return DayMealLogsResult.failure('Resposta inválida do servidor.');
        }
        final logs = decoded
            .map((e) => DayMealLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return DayMealLogsResult.success(logs);
      }

      return DayMealLogsResult.failure(
        'Não foi possível carregar as refeições (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return DayMealLogsResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return DayMealLogsResult.failure('Erro ao carregar as refeições.');
    }
  }

  static Future<UpdateMealLogResult> updateMealLog({
    required String mealLogId,
    required int mealType,
    required List<Map<String, dynamic>> items,
    required DayMealLogEntry previous,
  }) async {
    try {
      if (AuthSession.token == null) {
        return UpdateMealLogResult.failure(
          'Faça login para editar a refeição.',
        );
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/meal-logs/$mealLogId');
      final payload = <String, dynamic>{'mealType': mealType, 'items': items};
      final response = await http.put(
        uri,
        headers: _jsonHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = response.body.trim();
        if (raw.isEmpty) {
          final day = previous.consumedAt ?? DateTime.now();
          final logsResult = await fetchLogsForDate(day);
          if (!logsResult.ok || logsResult.logs == null) {
            return UpdateMealLogResult.failure(
              'Alterações salvas, mas não foi possível recarregar a refeição.',
            );
          }
          DayMealLogEntry? found;
          for (final e in logsResult.logs!) {
            if (e.id == mealLogId) {
              found = e;
              break;
            }
          }
          if (found == null) {
            return UpdateMealLogResult.failure(
              'Alterações salvas, mas a refeição não apareceu na lista do dia.',
            );
          }
          return UpdateMealLogResult.success(found);
        }
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          return UpdateMealLogResult.failure('Resposta inválida do servidor.');
        }
        return UpdateMealLogResult.success(DayMealLogEntry.fromJson(decoded));
      }

      final errorMessage = _extractErrorMessage(response);
      return UpdateMealLogResult.failure(
        errorMessage ??
            'Não foi possível salvar as alterações (${response.statusCode}).',
      );
    } catch (e) {
      final text = e.toString();
      if (_isNetworkError(text)) {
        return UpdateMealLogResult.failure(
          'Sem conexão com o servidor. Verifique sua internet.',
        );
      }
      return UpdateMealLogResult.failure('Erro ao salvar as alterações.');
    }
  }
}
