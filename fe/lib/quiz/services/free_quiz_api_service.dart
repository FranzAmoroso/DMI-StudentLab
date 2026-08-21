import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/quiz_model.dart';

class FreeQuizAnswerValidation {
  final bool isCorrect;
  final String correctOptionId;
  final String formalExplanation;
  final String informalExplanation;
  final String selectedAnswerExplanation;
  final String correctAnswerExplanation;
  final Map<String, String> answerExplanations;

  const FreeQuizAnswerValidation({
    required this.isCorrect,
    required this.correctOptionId,
    required this.formalExplanation,
    required this.informalExplanation,
    required this.selectedAnswerExplanation,
    required this.correctAnswerExplanation,
    required this.answerExplanations,
  });

  factory FreeQuizAnswerValidation.fromJson(Map<String, dynamic> json) {
    final Map<String, String> explanations = {};
    final dynamic rawExplanations = json['answer_explanations'];

    if (rawExplanations is Map) {
      for (final MapEntry<dynamic, dynamic> entry in rawExplanations.entries) {
        final String key = entry.key?.toString().trim() ?? '';
        final String value = entry.value?.toString().trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          explanations[key] = value;
        }
      }
    }

    return FreeQuizAnswerValidation(
      isCorrect: json['is_correct'] == true,
      correctOptionId: json['correct_option_id']?.toString() ?? '',
      formalExplanation: json['formal_explanation']?.toString() ?? '',
      informalExplanation: json['informal_explanation']?.toString() ?? '',
      selectedAnswerExplanation:
          json['selected_answer_explanation']?.toString() ?? '',
      correctAnswerExplanation:
          json['correct_answer_explanation']?.toString() ?? '',
      answerExplanations: explanations,
    );
  }
}

class FreeQuizApiService {
  static const String _baseUrl = 'https://dmi-student-lab.vercel.app';

  Uri _uri(String path) {
    return Uri.parse('$_baseUrl${path.startsWith('/') ? path : '/$path'}');
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  dynamic _decode(http.Response response, String fallback) {
    dynamic decoded;

    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map) {
      final dynamic detail = decoded['detail'] ?? decoded['error'];
      if (detail is String && detail.trim().isNotEmpty) {
        throw Exception(detail.trim());
      }
    }

    throw Exception(fallback);
  }

  Future<List<String>> getAvailableSubjects({
    required String department,
    required String course,
  }) async {
    final http.Response response = await http.post(
      _uri('/subjects'),
      headers: _headers,
      body: jsonEncode({
        'department': department.trim(),
        'course': course.trim(),
      }),
    );

    final dynamic decoded = _decode(
      response,
      'Non è stato possibile caricare le materie con quiz disponibili.',
    );

    if (decoded is! List) {
      throw Exception('Risposta materie quiz non valida.');
    }

    return decoded
        .map<String>((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  Future<List<String>> getArguments({
    required String department,
    required String course,
    required String subject,
  }) async {
    final http.Response response = await http.post(
      _uri('/arguments'),
      headers: _headers,
      body: jsonEncode({
        'department': department.trim(),
        'course': course.trim(),
        'subject': subject.trim(),
      }),
    );

    final dynamic decoded = _decode(
      response,
      'Non è stato possibile caricare gli argomenti.',
    );

    if (decoded is! List) {
      throw Exception('Risposta argomenti non valida.');
    }

    return decoded
        .map<String>((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  Future<int> getQuestionCount({
    required String department,
    required String course,
    required String subject,
    required List<String> arguments,
  }) async {
    final http.Response response = await http.post(
      _uri('/question_count'),
      headers: _headers,
      body: jsonEncode({
        'department': department.trim(),
        'course': course.trim(),
        'subject': subject.trim(),
        'arguments': arguments,
        'all_arguments': arguments.isEmpty,
      }),
    );

    final dynamic decoded = _decode(
      response,
      'Non è stato possibile calcolare le domande disponibili.',
    );

    if (decoded is num) {
      return decoded.toInt();
    }

    if (decoded is Map && decoded['count'] is num) {
      return (decoded['count'] as num).toInt();
    }

    throw Exception('Risposta conteggio domande non valida.');
  }

  Future<List<QuizModel>> loadQuiz({
    required String department,
    required String course,
    required String subject,
    required List<String> arguments,
    required int numberOfQuestions,
  }) async {
    final http.Response response = await http.post(
      _uri('/shuffle_filter'),
      headers: _headers,
      body: jsonEncode({
        'department': department.trim(),
        'course': course.trim(),
        'subject': subject.trim(),
        'arguments': arguments,
        'all_arguments': arguments.isEmpty,
        'number_of_questions': numberOfQuestions,
      }),
    );

    final dynamic decoded = _decode(
      response,
      'Non è stato possibile caricare le domande.',
    );

    if (decoded is! List) {
      throw Exception('Risposta quiz non valida.');
    }

    return decoded
        .whereType<Map>()
        .map<QuizModel>(
          (Map<dynamic, dynamic> item) =>
              QuizModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<FreeQuizAnswerValidation> validateAnswer({
    required String questionId,
    required String optionId,
    required String department,
    required String course,
    required String subject,
  }) async {
    final http.Response response = await http.post(
      _uri('/validate_answer'),
      headers: _headers,
      body: jsonEncode({
        'id_question': questionId,
        'id_choice': optionId,
        'department': department.trim(),
        'course': course.trim(),
        'subject': subject.trim(),
      }),
    );

    final dynamic decoded = _decode(
      response,
      'Non è stato possibile verificare la risposta.',
    );

    if (decoded is! Map) {
      throw Exception('Risposta di validazione non valida.');
    }

    return FreeQuizAnswerValidation.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}