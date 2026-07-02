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
  String? selectedArg;
  int selectedQuiz = 10;

  final List<String> subjects = [
    'Programmazione 1',
    'Interazione e Multimedia',
    // 'Ingegneria del software'
  ];

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final contentWidth = isDesktop ? 500.0 : constraints.maxWidth;

            return SizedBox(
              width: contentWidth,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.arrow_back, size: 22),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),
                    
                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Dipartimento',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: widget.department),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Corso',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: widget.course),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Materia',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedSub,
                      items: subjects.map((sub) {
                        return DropdownMenuItem(
                          value: sub,
                          child: Text(sub),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSub = value;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Argomento',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: 'Tutti gli argomenti'),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: selectedSub == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizPage(
                                      department: widget.department,
                                      course: widget.course,
                                      sub: selectedSub!,
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'Avvia Quiz',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
}