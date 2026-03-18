import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QuizPage extends StatefulWidget{
  final String dip;
  final String cor;
  final String mat;

  QuizPage({required this.dip, required this.cor, required this.mat});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage {
  List<dynamic> question = [];
  bool load = true;
  int idx = 0;

  @override 
  void initState() {
    super.initState();
    takeData();
  }


  void takeData() async {
    var result = await ApiService().takeQuestion(widget.dip, widget.cor, widget.mat);
    setState(() {
      question = result;
      load = false;
    });
  }

  void answerValidate(String idChoice) async {
    String idQuestion = question[idx]['id_domanda'];

    bool eCorretta = await ApiService().validate_quest(idQuestion, idChoice);
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(eCorretta ? "Esatto! " : "Sbagliato! "),
        backgroundColor: eCorretta ? Colors.green : Colors.red,
        duration: Duration(seconds: 1),
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
      backgroundColor: Color(0xFF121212), // Sfondo Notturno
      appBar: AppBar(title: Text("Quiz"), backgroundColor: Color(0xFF1F1F1F)),
      body: load 
        ? Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Text(
                  question[idx]['testo'],
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),

                ...(question[idx]['opzioni'] as List).map((option) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2C2C2C), // Grigio scuro
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () => answerValidate(option['id']),
                      child: Text(option['testo']),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
    );
  }
}