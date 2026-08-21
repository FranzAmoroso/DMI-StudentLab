import 'package:flutter/material.dart';

import 'quiz.dart';
import 'assigned_quizzes_page.dart';

import '../services/api_service.dart';
import '../services/auth_session.dart';

class SubjectSelection extends StatefulWidget {
  final String department;
  final String course;

  const SubjectSelection({
    super.key,
    required this.department,
    required this.course,
  });

  @override
  State<SubjectSelection> createState() => _SubjectSelectionState();
}

class _SubjectSelectionState extends State<SubjectSelection> {
  final AuthSession _authSession = AuthSession.instance;

  String? selectedSub;
  final List<String> selectedArguments = [];
  List<String> subjects = [];
  List<String> availableArguments = [];
  int selectedQuiz = 10;
  int availableQuestions = 0;
  bool loadingSubjects = false;
  bool isLoadingArguments = false;
  bool isLoadingQuestions = false;

  final TextEditingController _questionController =
      TextEditingController(text: '10');

  bool get _isAuthenticated => _authSession.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _authSession.addListener(_onAuthChanged);
    _loadSubjects();
  }

  @override
  void dispose() {
    _authSession.removeListener(_onAuthChanged);
    _questionController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadSubjects() async {
    setState(() {
      loadingSubjects = true;
    });

    try {
      final result = await ApiService().getSubjects(
        widget.department,
        widget.course,
      );

      if (!mounted) return;

      setState(() {
        subjects = result;
        loadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingSubjects = false;
      });

      _showMessage(
        'Impossibile caricare le materie.',
      );
    }
  }

  Future<void> _openAssignedQuizzes() async {
    if (!_isAuthenticated) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AssignedQuizzesPage(),
      ),
    );
  }

  Future<void> _selectSubject() async {
    if (loadingSubjects) return;

    final String? result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Seleziona materia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: subjects.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessuna materia disponibile.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            final bool isSelected =
                                selectedSub == subject;

                            return ListTile(
                              title: Text(subject),
                              selected: isSelected,
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  subject,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      selectedSub = result;
      selectedArguments.clear();
      availableArguments.clear();
      availableQuestions = 0;
      selectedQuiz = 10;
      _questionController.text = '10';
      isLoadingArguments = true;
    });

    try {
      final arguments = await ApiService().getArguments(
        widget.department,
        widget.course,
        selectedSub!,
      );

      if (!mounted) return;

      setState(() {
        availableArguments = arguments;
        isLoadingArguments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingArguments = false;
        availableArguments.clear();
      });

      _showMessage(
        'Errore caricamento argomenti.',
      );
    }
  }

  Future<void> _selectArguments() async {
    if (selectedSub == null) return;

    final List<String> temporarySelection =
        List<String>.from(selectedArguments);

    final List<String>? result =
        await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Seleziona argomenti',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Puoi selezionare più argomenti.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: availableArguments.isEmpty
                          ? const Center(
                              child: Text(
                                'Nessun argomento disponibile.',
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableArguments.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final argument =
                                    availableArguments[index];
                                final bool selected =
                                    temporarySelection.contains(
                                  argument,
                                );

                                return CheckboxListTile(
                                  value: selected,
                                  title: Text(argument),
                                  onChanged: (value) {
                                    setModalState(
                                      () {
                                        if (value == true) {
                                          if (!temporarySelection
                                              .contains(argument)) {
                                            temporarySelection.add(
                                              argument,
                                            );
                                          }
                                        } else {
                                          temporarySelection.remove(
                                            argument,
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            temporarySelection,
                          );
                        },
                        child: const Text(
                          'Conferma',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      selectedArguments
        ..clear()
        ..addAll(result);
    });

    await _updateQuestionCount();
  }

  Future<void> _updateQuestionCount() async {
    if (selectedSub == null ||
        selectedArguments.isEmpty) {
      setState(() {
        availableQuestions = 0;
        selectedQuiz = 10;
        _questionController.text = '10';
      });
      return;
    }

    setState(() {
      isLoadingQuestions = true;
    });

    try {
      final count = await ApiService().getQuestionCount(
        widget.department,
        widget.course,
        selectedSub!,
        selectedArguments,
      );

      if (!mounted) return;

      setState(() {
        availableQuestions = count;

        if (count == 0) {
          selectedQuiz = 0;
        } else if (selectedQuiz > count) {
          selectedQuiz = count;
        } else if (selectedQuiz == 0) {
          selectedQuiz = count >= 10 ? 10 : count;
        }

        _questionController.text =
            selectedQuiz.toString();

        isLoadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingQuestions = false;
        availableQuestions = 0;
        selectedQuiz = 0;
        _questionController.clear();
      });

      _showMessage(
        'Impossibile calcolare le domande disponibili.',
      );
    }
  }

  void _changeQuestionNumber(int value) {
    if (availableQuestions == 0) return;

    int newValue = selectedQuiz + value;

    if (newValue < 1) {
      newValue = 1;
    }

    if (newValue > availableQuestions) {
      newValue = availableQuestions;
    }

    setState(() {
      selectedQuiz = newValue;
      _questionController.text =
          newValue.toString();
      _questionController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: _questionController.text.length,
        ),
      );
    });
  }

  void _onQuestionNumberChanged(
    String value,
  ) {
    final int? number =
        int.tryParse(value);

    if (number == null) {
      return;
    }

    if (number > availableQuestions) {
      _questionController.text =
          availableQuestions.toString();
      _questionController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: _questionController.text.length,
        ),
      );

      setState(() {
        selectedQuiz = availableQuestions;
      });

      return;
    }

    if (number >= 1) {
      setState(() {
        selectedQuiz = number;
      });
    }
  }

  void _startQuiz() {
    if (selectedSub == null) return;

    if (selectedArguments.isEmpty) {
      _showMessage(
        'Seleziona almeno un argomento.',
      );
      return;
    }

    if (availableQuestions == 0) {
      _showMessage(
        'Non ci sono domande disponibili.',
      );
      return;
    }

    if (selectedQuiz < 1 ||
        selectedQuiz > availableQuestions) {
      _showMessage(
        'Numero di domande non valido.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          department: widget.department,
          course: widget.course,
          sub: selectedSub!,
          arguments: selectedArguments,
          numberOfQuestions: selectedQuiz,
        ),
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop =
                  constraints.maxWidth > 600;
              final double contentWidth =
                  isDesktop
                      ? 500.0
                      : constraints.maxWidth;

              return SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.all(
                    20.0,
                  ),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              size: 22,
                            ),
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (_isAuthenticated) ...[
                        _AssignedQuizEntryCard(
                          onTap: _openAssignedQuizzes,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _InfoField(
                        label: 'Dipartimento',
                        value: widget.department,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      _InfoField(
                        label: 'Corso',
                        value: widget.course,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: loadingSubjects
                            ? null
                            : _selectSubject,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Materia',
                            border:
                                const OutlineInputBorder(),
                            suffixIcon: loadingSubjects
                                ? const Padding(
                                    padding:
                                        EdgeInsets.all(
                                      12,
                                    ),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .keyboard_arrow_down,
                                  ),
                          ),
                          child: Text(
                            loadingSubjects
                                ? 'Caricamento...'
                                : selectedSub ??
                                    'Seleziona una materia',
                            style: TextStyle(
                              color: selectedSub == null
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      GestureDetector(
                        onTap: selectedSub == null ||
                                isLoadingArguments
                            ? null
                            : _selectArguments,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Argomenti',
                            border:
                                const OutlineInputBorder(),
                            suffixIcon: isLoadingArguments
                                ? const Padding(
                                    padding:
                                        EdgeInsets.all(
                                      12,
                                    ),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .keyboard_arrow_down,
                                  ),
                          ),
                          child: Text(
                            selectedSub == null
                                ? 'Seleziona prima una materia'
                                : selectedArguments.isEmpty
                                    ? 'Seleziona gli argomenti'
                                    : selectedArguments.join(
                                        ', ',
                                      ),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selectedSub == null ||
                                      selectedArguments
                                          .isEmpty
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: const EdgeInsets.all(
                          16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(
                                0.35,
                              ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.quiz_outlined,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text(
                                    'Domande disponibili',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  if (isLoadingQuestions)
                                    const Text(
                                      'Calcolo in corso...',
                                      style: TextStyle(
                                        color:
                                            Colors.grey,
                                        fontSize: 12,
                                      ),
                                    )
                                  else
                                    Text(
                                      selectedArguments
                                              .isEmpty
                                          ? 'Seleziona almeno un argomento'
                                          : '$availableQuestions domande',
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (availableQuestions > 0) ...[
                        const Text(
                          'Numero di domande',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey
                                  .withOpacity(
                                0.3,
                              ),
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                ),
                                onPressed:
                                    selectedQuiz <= 1
                                        ? null
                                        : () {
                                            _changeQuestionNumber(
                                              -1,
                                            );
                                          },
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                width: 75,
                                child: TextField(
                                  controller:
                                      _questionController,
                                  textAlign:
                                      TextAlign.center,
                                  keyboardType:
                                      TextInputType
                                          .number,
                                  decoration:
                                      const InputDecoration(
                                    border:
                                        OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets
                                            .symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onChanged:
                                      _onQuestionNumberChanged,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                ),
                                onPressed: selectedQuiz >=
                                        availableQuestions
                                    ? null
                                    : () {
                                        _changeQuestionNumber(
                                          1,
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Center(
                          child: Text(
                            'Massimo: $availableQuestions',
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: 30,
                      ),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                            ),
                          ),
                          onPressed: selectedSub ==
                                      null ||
                                  selectedArguments
                                      .isEmpty ||
                                  availableQuestions == 0 ||
                                  isLoadingQuestions
                              ? null
                              : _startQuiz,
                          child: const Text(
                            'Avvia Quiz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
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

class _AssignedQuizEntryCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _AssignedQuizEntryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer
                .withOpacity(0.35),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary
                  .withOpacity(0.18),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 28,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz assegnati',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Visualizza i quiz ricevuti dai docenti.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField
    extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border:
            const OutlineInputBorder(),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }
}