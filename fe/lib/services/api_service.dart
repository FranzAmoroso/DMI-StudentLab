import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<QuizModel>> shuffle_filter(String dip, String cor, String mat) async {
    final url = Uri.parse('$baseUrl');

      final response = await http.post(
        url,
        headers : {
          "Content-Type":"application/json",
          // "X-Custom-Secret":"ChiaveAcesso",
        },
        body: jsonEncode ({
          "dipartimento":dip,
          "corso":cor,
          "materia":mat
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body)['domande'];
        return body.map((dynamic item) => QuizModel.fromJson(item)).toList();
      } else {
        throw Exception("Impossibile caricare le domande");
      }
  }
    Future<bool> validate_quest(String idQuesition, String idChoice) async {
    final response = await http.post(
    Uri.parse('$baseUrl/validate'),
    body: jsonEncode({"id_domanda":idQuesition,"id_scelta":idChoice}),
    );

    return jsonDecode(response.body)['corretto'];
  }
}