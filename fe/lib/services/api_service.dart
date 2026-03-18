import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.2:8000";

  Future<List<QuizModel>> takeQuestion(String dip, String cor, String mat) async {
    final url = Uri.parse('$baseUrl/$dip$cor$mat');

      final response = await http.post (
        url,
        headers : {
          "Content-Type":"application/json",
          "X-Custom-Secret":"ChiaveAcesso",
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
}