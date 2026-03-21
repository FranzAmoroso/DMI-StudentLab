import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/quiz_model.dart';

class QuizPage extends StatefulWidget{
  final String department;
  final String course;
  final String sub;

  QuizPage({required this.department, required this.course, required this.sub});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizModel> question = [];
  bool load = true;
  int idx = 0;

  @override 
  void initState() {
    super.initState();
    takeData();
  }


  void takeData() async {
    var result = await ApiService().shuffle_filter(widget.department, widget.course, widget.sub);
    setState(() {
      question = result;
      load = false;
    });
  }

  void answerValidate(String idChoice) async {
    String idQuestion = question[idx].idQuestion;

    bool isCorrect = await ApiService().validate_quest(idQuestion, idChoice);
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "Esatto! " : "Sbagliato! "),
        backgroundColor: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(Duration(seconds: 1), () {
      if (idx < question.length - 1) {
        setState(() => idx++);
      } else {
        // Fine del Quiz
        print("Quiz Terminato");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(title: Text("Quiz"), backgroundColor: Color(0xFF1B263B)
      ),
      body: load 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (idx+1) / question.length,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation( 
                    Color(0xFF5C6BC0),
                    ),
                  ),

                const SizedBox(height:12),

                Text(
                  'Domanda ${idx+1}/ ${question.length}',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B263B),
                    border: Border.all(
                      color: const Color(0xFF3949AB), // Insert opacity 0.3
                      width: 1.5,
                      ),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.black, // insert opacity 0.4
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      question[idx].text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                ),

                const SizedBox(height: 30),

                ...question[idx].option.map((option) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1B263B), 
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6
                    ),
                      onPressed: () => answerValidate(option.id),
                      child: Text(
                        option.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                       ),
                      ),
                  );
                    }).toList(),
                  ],
            ),
          ),
    );
  }
}