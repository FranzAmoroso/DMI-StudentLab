import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quiz_model.dart';

class ApiService {
  final String baseUrl =
      'https://dmi-student-lab.vercel.app';

  Future<List<String>> getArguments(
    String department,
    String course,
    String sub,
  ) async {
    final url = Uri.parse('$baseUrl/arguments');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'department': department,
          'course': course,
          'sub': sub,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);

        if (body is! List) {
          throw Exception(
            'Risposta non valida dal server.',
          );
        }

        return body
            .map<String>(
              (item) => item.toString(),
            )
            .toList();
      }

      throw Exception(
        'Errore caricamento argomenti: '
        '${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione argomenti: $e',
      );
    }
  }

  Future<int> getQuestionCount(
    String department,
    String course,
    String sub,
    List<String> arguments,
  ) async {
    final url = Uri.parse('$baseUrl/question_count');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'department': department,
          'course': course,
          'sub': sub,
          'arguments': arguments,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);

        // Il backend può restituire direttamente:
        // 25
        if (body is int) {
          return body;
        }

        // Oppure:
        // {"count": 25}
        if (body is Map<String, dynamic> &&
            body['count'] is int) {
          return body['count'] as int;
        }

        throw Exception(
          'Risposta non valida per il conteggio.',
        );
      }

      throw Exception(
        'Errore conteggio domande: '
        '${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione conteggio: $e',
      );
    }
  }

  Future<List<QuizModel>> shuffle_filter(
    String department,
    String course,
    String sub,
    List<String> selectedArguments,
    int numberOfQuestions,
  ) async {
    final url = Uri.parse('$baseUrl/shuffle_filter');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'department': department,
          'course': course,
          'sub': sub,
          'arguments': selectedArguments,
          'number_of_questions': numberOfQuestions,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);

        if (body is! List) {
          throw Exception(
            'Risposta quiz non valida.',
          );
        }

        return body
            .map<QuizModel>(
              (item) => QuizModel.fromJson(item),
            )
            .toList();
      }

      throw Exception(
        'Impossibile caricare le domande: '
        '${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore caricamento quiz: $e',
      );
    }
  }

Future<bool> validate_quest(
  String idQuestion,
  String idChoice,
  String department,
  String sub,
) async {
  final url = Uri.parse(
    '$baseUrl/validate_answer',
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idQuestion': idQuestion,
        'idChoice': idChoice,
        'department': department,
        'sub': sub,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) == true;
    }

    throw Exception(
      'Errore validate: '
      '${response.statusCode} - ${response.body}',
    );
  } catch (e) {
    throw Exception(
      'Errore connessione validazione: $e',
    );
  }
}

    Future<List<String>> getSubjects(
    String department,
    String course,
  ) async {
    final url = Uri.parse('$baseUrl/subjects');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'department': department,
          'course': course,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);

        return body.map((item) => item.toString()).toList();
      }

      throw Exception(
        'Errore caricamento materie: ${response.body}',
      );
    } catch (e) {
      throw Exception(
        'Errore connessione materie: $e',
      );
    }
  }
}