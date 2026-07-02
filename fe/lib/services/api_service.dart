import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';

class ApiService {
  final String baseUrl = 'https://dmi-student-lab.vercel.app';

  Future<List<QuizModel>> shuffle_filter(String department, String course, String sub) async {
    final url = Uri.parse('$baseUrl/shuffle_filter').replace(
      queryParameters: {
        'department': department,
        'course': course,
        'sub': sub,
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => QuizModel.fromJson(item)).toList();
      } else {
        throw Exception('Impossibile caricare le domande: Errore del server');
      }
    } catch (e) {
      throw Exception('Impossibile caricare le domande: $e');
    }
  }

  Future<bool> validate_quest(String idQuestion, String idChoice, String sub) async {
    final url = Uri.parse('$baseUrl/validate_answer').replace(
      queryParameters: {
        'idQuestion': idQuestion,
        'idChoice': idChoice,
        'sub': sub,
      },
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) == true;
      } else {
        throw Exception('Errore validate: ${response.body}');
      }
    } catch (e) {
      throw Exception('Errore connessione validazione: $e');
    }
  }
}
