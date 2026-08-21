import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

enum PublicNewsPublisherMode {
  teacher,
  admin,
}

enum PublicNewsTargetType {
  all,
  university,
  department,
  course,
  subject,
}

class PublicNewsDraft {
  final String title;
  final String content;
  final PublicNewsTargetType targetType;
  final String city;
  final String university;
  final String department;
  final String course;
  final int? subjectId;
  final String subjectName;

  const PublicNewsDraft({
    required this.title,
    required this.content,
    required this.targetType,
    required this.city,
    required this.university,
    required this.department,
    required this.course,
    required this.subjectId,
    required this.subjectName,
  });
}

class PublicNewsEditorPage extends StatefulWidget {
  final PublicNewsPublisherMode mode;
  final List<Map<String, dynamic>> subjects;

  const PublicNewsEditorPage.teacher({
    super.key,
    required this.subjects,
  }) : mode = PublicNewsPublisherMode.teacher;

  const PublicNewsEditorPage.admin({
    super.key,
    this.subjects = const [],
  }) : mode = PublicNewsPublisherMode.admin;

  @override
  State<PublicNewsEditorPage> createState() => _PublicNewsEditorPageState();
}

class _PublicNewsEditorPageState extends State<PublicNewsEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();

  PublicNewsTargetType _targetType = PublicNewsTargetType.subject;
  int? _subjectId;

  bool get _isAdmin => widget.mode == PublicNewsPublisherMode.admin;

  @override
  void initState() {
    super.initState();

    if (!_isAdmin) {
      _targetType = PublicNewsTargetType.subject;

      if (widget.subjects.length == 1) {
        _subjectId = _toInt(widget.subjects.first['id']);
        _fillAcademicContext(widget.subjects.first);
      }
    } else {
      _targetType = PublicNewsTargetType.all;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _cityController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  void _fillAcademicContext(Map<String, dynamic> subject) {
    _cityController.text = _firstNonEmpty([
      subject['city'],
    ]);
    _universityController.text = _firstNonEmpty([
      subject['university'],
    ]);
    _departmentController.text = _firstNonEmpty([
      subject['department'],
    ]);
    _courseController.text = _firstNonEmpty([
      subject['course'],
    ]);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_targetType == PublicNewsTargetType.subject && _subjectId == null) {
      _showMessage('Seleziona una materia.');
      return;
    }

    final Map<String, dynamic>? subject = _selectedSubject;

    Navigator.of(context).pop(
      PublicNewsDraft(
        title: _normalizeSingleLine(_titleController.text),
        content: _contentController.text.trim(),
        targetType: _targetType,
        city: _cityController.text.trim(),
        university: _universityController.text.trim(),
        department: _departmentController.text.trim(),
        course: _courseController.text.trim(),
        subjectId: _subjectId,
        subjectName: subject?['name']?.toString().trim() ?? '',
      ),
    );
  }

  Map<String, dynamic>? get _selectedSubject {
    final int? id = _subjectId;

    if (id == null) {
      return null;
    }

    for (final Map<String, dynamic> subject in widget.subjects) {
      if (_toInt(subject['id']) == id) {
        return subject;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        title: Text(
          _isAdmin ? 'Pubblica news' : 'Nuova news docente',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 160,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Titolo',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (String? value) {
                      final String text = _normalizeSingleLine(value ?? '');

                      if (text.isEmpty) {
                        return 'Inserisci il titolo';
                      }

                      if (text.length > 160) {
                        return 'Il titolo è troppo lungo';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_isAdmin) ...[
                    DropdownButtonFormField<PublicNewsTargetType>(
                      initialValue: _targetType,
                      dropdownColor: AppColors.eleganceDeepNavy,
                      decoration: const InputDecoration(
                        labelText: 'Destinazione',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PublicNewsTargetType.all,
                          child: Text('Tutta StudentLab'),
                        ),
                        DropdownMenuItem(
                          value: PublicNewsTargetType.university,
                          child: Text('Ateneo'),
                        ),
                        DropdownMenuItem(
                          value: PublicNewsTargetType.department,
                          child: Text('Dipartimento'),
                        ),
                        DropdownMenuItem(
                          value: PublicNewsTargetType.course,
                          child: Text('Corso'),
                        ),
                        DropdownMenuItem(
                          value: PublicNewsTargetType.subject,
                          child: Text('Materia'),
                        ),
                      ],
                      onChanged: (PublicNewsTargetType? value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _targetType = value;

                          if (value != PublicNewsTargetType.subject) {
                            _subjectId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (!_isAdmin || _targetType == PublicNewsTargetType.subject)
                    DropdownButtonFormField<int>(
                      initialValue: _subjectId,
                      isExpanded: true,
                      dropdownColor: AppColors.eleganceDeepNavy,
                      decoration: const InputDecoration(
                        labelText: 'Materia',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: widget.subjects
                          .map(
                            (Map<String, dynamic> subject) {
                              final int? id = _toInt(subject['id']);

                              if (id == null) {
                                return null;
                              }

                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  subject['name']?.toString().trim().isNotEmpty ==
                                          true
                                      ? subject['name'].toString().trim()
                                      : 'Materia #$id',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          )
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: (int? value) {
                        setState(() {
                          _subjectId = value;

                          final Map<String, dynamic>? subject = _selectedSubject;

                          if (subject != null) {
                            _fillAcademicContext(subject);
                          }
                        });
                      },
                    ),
                  if (!_isAdmin || _targetType != PublicNewsTargetType.all) ...[
                    const SizedBox(height: 14),
                    _buildAcademicFields(),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contentController,
                    minLines: 7,
                    maxLines: 14,
                    maxLength: 5000,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Contenuto',
                      alignLabelWithHint: true,
                      hintText: 'Scrivi la comunicazione...',
                    ),
                    validator: (String? value) {
                      final String text = value?.trim() ?? '';

                      if (text.isEmpty) {
                        return 'Inserisci il contenuto';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildBackendNotice(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Prepara pubblicazione'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.teacherIndigo.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: AppColors.teacherIndigo,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isAdmin
                  ? 'L’admin può preparare comunicazioni globali o indirizzate a uno specifico contesto accademico.'
                  : 'Il docente può preparare comunicazioni soltanto nel contesto delle proprie materie verificate.',
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.58),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cityController,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Città',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _universityController,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Ateneo',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
          validator: (String? value) {
            if (_targetType != PublicNewsTargetType.all &&
                (value?.trim().isEmpty ?? true)) {
              return 'Inserisci l’ateneo';
            }

            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _departmentController,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Dipartimento',
            prefixIcon: Icon(Icons.domain_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _courseController,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Corso',
            prefixIcon: Icon(Icons.school_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildBackendNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.14),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.amber,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Il form frontend è pronto. L’invio effettivo verrà abilitato quando saranno disponibili gli endpoint PublicNews e i relativi controlli server.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeSingleLine(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .join(' ');
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final dynamic value in values) {
      final String normalized = value?.toString().trim() ?? '';

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}