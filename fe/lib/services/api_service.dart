import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000';

  Future<List<QuizModel>> shuffle_filter(String department, String course, String sub) async {
    final url = Uri.parse('$baseUrl/send');

      final response = await http.post(
        url,
        headers : {
          'Content-Type':'application/json',
          // 'X-Custom-Secret':'ChiaveAcesso',
        },
        body: jsonEncode ({
          'department':department,
          'course':course,
          'sub':sub
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body)['question'];
        return body.map((dynamic item) => QuizModel.fromJson(item)).toList();
      } else {
        throw Exception('Impossibile caricare le domande');
      }
  }
    Future<bool> validate_quest(String idQuestion, String idChoice) async {
    final response = await http.post(
    Uri.parse('$baseUrl/validate'),
    headers :{
      'content-Type':'application/json'
    },
    body: jsonEncode({'idQuestion':idQuestion,'idChoice':idChoice}),
    );
    if(response.statusCode == 200) {
          return jsonDecode(response.body)['correct'];
    } else {
      throw Exception('Errore validate: ${response.body}');
    }
  }
}