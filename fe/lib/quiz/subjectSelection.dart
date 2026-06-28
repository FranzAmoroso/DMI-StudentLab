import "package:flutter/animation.dart";
import 'package:flutter/material.dart';
import "quiz.dart";

class SubjectSelection extends StatefulWidget {

  final String  department;
  final String course;

  const SubjectSelection({
    super.key,
    required this.department,
    required this.course
  });

  @override
  State<SubjectSelection> createState() => _SubjectSelectionState();
}

class _SubjectSelectionState extends State<SubjectSelection> {

  String? selectedSub;
  int selectedQuiz = 10;

  final List<String> subjects = [
    'Interazione e Multimedia',
    // 'Ingegneria del software'
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
    body: Padding(
      padding : EdgeInsets.all(20),

    child: Column(

      children: [

        const SizedBox(height: 20),

        TextField(
          enabled: false,
          decoration: InputDecoration(
                      labelText: 'Dipartimento',
                      border: OutlineInputBorder(),
          ),
          controller: TextEditingController(
            text : widget.department
          ),
        ),

        const SizedBox(height:20),

        TextField(
          enabled: false,
          decoration : InputDecoration(
                        labelText: 'Corso',
                        border: OutlineInputBorder()
          ),
          controller: TextEditingController(
            text: widget.course
          ),
        ),

        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          decoration : const  InputDecoration(
                        labelText: 'Materia',
                        border: OutlineInputBorder()
          ),
          items: subjects.map((sub) {
            return DropdownMenuItem(
              value: sub,
              child: Text(sub),
            );
          }).toList(),

          onChanged: (value){
            setState((){
              selectedSub = value;
            });
          }
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: selectedSub == null ? null : (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => QuizPage(department: widget.department, course: widget.course, sub: selectedSub!)));
          },
          child: const Text('Avvia Quiz'),
        )
      ]

  

    )

    )
    );
  }
  

}