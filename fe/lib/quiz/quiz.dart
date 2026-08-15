import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/quiz_model.dart';
import 'package:fe/theme/nightTheme.dart';
import 'package:fe/quiz/quizResultLayer.dart';

class QuizPage extends StatefulWidget {
  final String department;
  final String course;
  final String sub;
  final List<String> arguments;
  final int numberOfQuestions;

  const QuizPage({
    super.key,
    required this.department,
    required this.course,
    required this.sub,
    required this.arguments,
    required this.numberOfQuestions,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizModel> question = [];
  List<QuizQuestionResult> results = [];

  bool load = true;
  bool isLocked = false;
  bool modalIsOpen = false;

  int idx = 0;
  int _choiceCorrect = 0;

  @override
  void initState() {
    super.initState();
    takeData();
  }


  void _showQuizResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultLayer(
          results: results,
        ),
      ),
    );
  }


  void takeData() async {
    try {
      final result = await ApiService().shuffle_filter(
        widget.department,
        widget.course,
        widget.sub,
        widget.arguments,
        widget.numberOfQuestions,
      );

      if (!mounted) return;

      setState(() {
        question = result;
        load = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        load = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore nel caricamento delle domande: $e',
          ),
        ),
      );
    }
  }


  Future<void> answerValidate(String idChoice) async {
    if (isLocked) return;

    setState(() {
      isLocked = true;
    });

    final currentQuestion = question[idx];

    final idQuestion = currentQuestion.idQuestion;

    final isCorrect = await ApiService().validate_quest(
      idQuestion,
      idChoice,
      widget.department,
      widget.sub,
    );

    if (!mounted) return;


    final selectedOption = currentQuestion.option.firstWhere(
      (option) => option.id == idChoice,
    );


    final correctOption = currentQuestion.option.firstWhere(
      (option) => option.id == currentQuestion.idCorrect,
    );


    results.add(
      QuizQuestionResult(
        question: currentQuestion.text,
        givenAnswer: selectedOption.text,
        correctAnswer: correctOption.text,
        formalExplanation:
            currentQuestion.formalExplanation,
        informalExplanation:
            currentQuestion.informalExplanation,
        questionResponseExplanation:
            currentQuestion.questionResponseExplanation,
        answerExplanations: {},
        isCorrect: isCorrect,
      ),
    );

    if (isCorrect) {
      _choiceCorrect++;
    }


    if (idx < question.length - 1) {
      setState(() {
        idx++;
        isLocked = false;
      });
    } else {
      _showQuizResult();
    }
  }


  Future<void> _showExplanation(
    BuildContext context,
    QuizModel currentQuestion,
  ) async {
    if (modalIsOpen) return;

    setState(() {
      modalIsOpen = true;
    });

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryNightBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 10,
                left: 20,
                right: 20,
                bottom: 20 +
                    MediaQuery.of(modalContext)
                        .viewInsets
                        .bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      const SizedBox(height: 24),
                      const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.skyBlue,
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text(
                          'Spiegazione',
                          style: TextStyle(
                            color:
                                AppColors.pureWhite,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            modalContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color:
                              AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

 
                  const Text(
                    'Definizione formale',
                    style: TextStyle(
                      color: AppColors.skyBlue,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    currentQuestion
                            .formalExplanation
                            .isNotEmpty
                        ? currentQuestion
                            .formalExplanation
                        : 'Nessuna definizione formale disponibile.',
                    style: TextStyle(
                      color: AppColors.pureWhite
                          .withOpacity(0.85),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),

  
                  const Text(
                    'Spiegazione informale',
                    style: TextStyle(
                      color: AppColors.skyBlue,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    currentQuestion
                            .informalExplanation
                            .isNotEmpty
                        ? currentQuestion
                            .informalExplanation
                        : 'Nessuna spiegazione informale disponibile.',
                    style: TextStyle(
                      color: AppColors.pureWhite
                          .withOpacity(0.70),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),
  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          modalContext,
                        );
                      },
                      child: const Text(
                        'Ho capito',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      modalIsOpen = false;
    });
  }


  @override
  Widget build(BuildContext context) {

    if (load) {
      return Scaffold(
        backgroundColor:
            const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor:
              const Color(0xFF1B263B),
          foregroundColor:
              Colors.white,
          title: const Text(
            'Che ansia..',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }


    if (question.isEmpty) {
      return Scaffold(
        backgroundColor:
            const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor:
              const Color(0xFF1B263B),
          foregroundColor:
              Colors.white,
          title: const Text(
            'Quiz',
          ),
        ),
        body: const Center(
          child: Text(
            'Non sono state trovate domande.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }


    final currentQuestion = question[idx];

    return Scaffold(
      backgroundColor:
          const Color(0xFF0D1B2A),


      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1B263B),

        foregroundColor:
            Colors.white,

        elevation: 0,

        title: Text(
          '${currentQuestion.metadata['sub'] ?? ''}'
          ' - '
          '${currentQuestion.metadata['argoment'] ?? ''}',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.book,
            ),

            tooltip: 'Spiegazione',

            onPressed: () {
              _showExplanation(
                context,
                currentQuestion,
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder:
                (context, constraints) {
              final isLargeScreen =
                  constraints.maxWidth > 700;

              final contentWidth =
                  isLargeScreen
                      ? 600.0
                      : constraints.maxWidth;

              return SizedBox(
                width: contentWidth,

                child: ListView(
                  padding:
                      const EdgeInsets.all(20),

                  children: [
                    LinearProgressIndicator(
                      value:
                          (idx + 1) /
                              question.length,

                      backgroundColor:
                          Colors.white
                              .withOpacity(
                                  0.1),

                      valueColor:
                          const AlwaysStoppedAnimation<
                              Color>(
                        Color(0xFF5C6BC0),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Expanded(
                          child: Text(
                            currentQuestion
                                .text,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w500,
                              height: 1.3,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 15,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                                    0xFF1B263B),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        8),
                          ),

                          child: Text(
                            '${idx + 1}/${question.length}',

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 35,
                    ),

                    ...currentQuestion.option
                        .map(
                      (option) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),

                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                      0xFF1B263B),

                              foregroundColor:
                                  Colors.white,

                              disabledBackgroundColor:
                                  const Color(
                                      0xFF1B263B),

                              disabledForegroundColor:
                                  Colors.white
                                      .withOpacity(
                                          0.50),

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 18,
                                horizontal: 16,
                              ),

                              alignment:
                                  Alignment
                                      .centerLeft,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            12),
                              ),

                              elevation: 3,
                            ),

                            onPressed:
                                isLocked
                                    ? null
                                    : () =>
                                        answerValidate(
                                          option.id,
                                        ),

                            child: Text(
                              option.text,

                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w400,
                                height: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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