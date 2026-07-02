import 'package:fe/layers/home.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/quiz_model.dart';

class QuizPage extends StatefulWidget {
  final String department;
  final String course;
  final String sub;

  const QuizPage({super.key, required this.department, required this.course, required this.sub});

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
    if (mounted) {
      setState(() {
        question = result;
        load = false;
      });
    }
  }

  void answerValidate(String idChoice) async {

    setState(() => isLocked = true);
    String idQuestion = question[idx].idQuestion;

    bool isCorrect = await ApiService().validate_quest(idQuestion, idChoice, widget.sub);
    if (!mounted) return;

    setState(() {
      if (isCorrect) _choiceCorrect++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "Genio! " : "Ripassa! "),
        backgroundColor: isCorrect ? const Color.fromARGB(255, 4, 89, 8) : const Color.fromARGB(255, 68, 1, 1),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (idx < question.length - 1) {
        setState(() {
          idx++;
          isLocked = false;
        });
      } else {
        showDialog(
          context: context,
          barrierDismissible: false, 
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1B263B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  SizedBox(width: 10),
                  Text('Quiz Completato!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ottimo lavoro! Ecco il tuo risultato:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '$_choiceCorrect / ${question.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    Navigator.of(context).pop(); 
                  },
                  child: const Text(
                    'Torna alle Materie',
                    style: TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
        title: Text(
          load 
              ? "Che ansia.." 
              : '${question[idx].metadata['sub'] ?? ''} - ${question[idx].metadata['argoment'] ?? ''}',
          style: const TextStyle(fontSize: 16),
        ), 
        actions: [
          if (!load)
            IconButton(
              icon: const Icon(Icons.book),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1B263B),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) {
                    final meta = question[idx].metadata;

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Definizione Formale: ${meta['formal_explanation']}",
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 10),
                          Text("Definizione Informale: ${meta['informal_explanation']}",
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          Text("Capire la Risposta: ${meta['question_response_explanation']}",
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  },
                );
              },
            )
        ],
      ),
      body: load 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLargeScreen = constraints.maxWidth > 700;
                  final contentWidth = isLargeScreen ? 600.0 : constraints.maxWidth;

                  return SizedBox(
                    width: contentWidth,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        LinearProgressIndicator(
                          value: question.isEmpty ? 0 : (idx + 1) / question.length,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5C6BC0)),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                question[idx].text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B263B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${idx + 1}/${question.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),

                        ...question[idx].option.map((option) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B263B), 
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                alignment: Alignment.centerLeft, 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              onPressed: isLocked ? null : () => answerValidate(option.id),
                              child: Text(
                                option.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }
}
