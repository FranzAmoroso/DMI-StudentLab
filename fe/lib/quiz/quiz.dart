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
    String idQuestion = question[idx].idQuestion;

    bool isCorrect = await ApiService().validate_quest(idQuestion, idChoice, widget.sub);
    if (!mounted) return;

    setState(() {
      isLocked = true;
      if (isCorrect) _choiceCorrect++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "Esatto! " : "Sbagliato! "),
        backgroundColor: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('${question[idx].metadata['argoment']}'),
                      content: const Text('~o~\nspiegazione formale/infomale dell\'argomento\n~o~'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('chiudi'),
                        )
                      ],
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
