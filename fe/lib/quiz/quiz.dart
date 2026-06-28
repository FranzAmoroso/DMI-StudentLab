import 'package:fe/home.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/quiz_model.dart';

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
  bool isLocked = false;
  int idx = 0;
  int _choiceCorrect = 0;

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
    setState(() {
      isLocked = true;
      isCorrect ? _choiceCorrect++ : null; // Insert of condition topic explanation (pop-up)

    });
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "Esatto! " : "Sbagliato! "),
        backgroundColor: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(Duration(seconds: 1), () {
      if (idx < question.length - 1) {
        setState(() {
          idx++;
          isLocked = false;
        });
      } else {
        print('Quiz terminato');
        final int choiceCorrect = _choiceCorrect;
        print('Risposte corrette: $choiceCorrect');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B263B),
        
        title: Text(
          load ? 
          "Che ansia.."
          : '${question[idx].metadata['sub']} - ${question[idx].metadata['argoment']}',
          ), 
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: (){
              showDialog(
                context: context,
                builder: (context){
                  return AlertDialog(
                    title: Text('${question[idx].metadata['argoment']}'),
                    content : const Text('~o~\nspiegazione formale/infomale dell\'argomento\n~o~'),
                    actions : [
                      TextButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: const Text('chiudi'),
                      )
                    ] 
                  );
                }
              );
            }
          )
        ]

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

                SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                        RichText(text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                        text: question[idx].text,
                      )),
                      RichText(
                        text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        text: '${idx+1}/ ${question.length}',
                        )
                      )
                        ]
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
                     onPressed: isLocked ? null : () => answerValidate(option.id),
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