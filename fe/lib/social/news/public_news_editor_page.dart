import 'package:flutter/material.dart';

import '../../services/public_news_api_service.dart';
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
  final PublicNewsApiService _apiService = PublicNewsApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();

  PublicNewsTargetType _targetType = PublicNewsTargetType.subject;
  int? _subjectId;
  bool _sending = false;
  String? _error;

  bool get _isAdmin => widget.mode == PublicNewsPublisherMode.admin;

  @override
  void initState() {
    super.initState();

    if (_isAdmin) {
      _targetType = PublicNewsTargetType.all;
    } else {
      _targetType = PublicNewsTargetType.subject;
      if (widget.subjects.length == 1) {
        _subjectId = _toInt(widget.subjects.first['id']);
        _fillAcademicContext(widget.subjects.first);
      }
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

  void _fillAcademicContext(Map<String, dynamic> subject) {
    _cityController.text = _firstNonEmpty([subject['city']]);
    _universityController.text = _firstNonEmpty([subject['university']]);
    _departmentController.text = _firstNonEmpty([subject['department']]);
    _courseController.text = _firstNonEmpty([subject['course']]);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_sending || !_formKey.currentState!.validate()) {
      return;
    }

    if (_targetType == PublicNewsTargetType.subject && _subjectId == null) {
      _showMessage('Seleziona una materia.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final Map<String, dynamic>? subject = _selectedSubject;

      await _apiService.create(
        targetType: _targetValue(_targetType),
        title: _titleController.text,
        content: _contentController.text,
        subjectId: _subjectId,
        city: _cityController.text,
        university: _isAdmin
            ? _universityController.text
            : _firstNonEmpty([subject?['university']]),
        universityCode: _firstNonEmpty([
          subject?['university_code'],
          subject?['universityCode'],
        ]),
        department: _isAdmin
            ? _departmentController.text
            : _firstNonEmpty([subject?['department']]),
        departmentCode: _firstNonEmpty([
          subject?['department_code'],
          subject?['departmentCode'],
        ]),
        course: _isAdmin
            ? _courseController.text
            : _firstNonEmpty([subject?['course']]),
        courseCode: _firstNonEmpty([
          subject?['course_code'],
          subject?['courseCode'],
        ]),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('News pubblicata correttamente.'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
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
                    enabled: !_sending,
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
                      final String text =
                          (value ?? '').trim().split(RegExp(r'\s+')).join(' ');

                      if (text.isEmpty) {
                        return 'Inserisci il titolo';
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
                      onChanged: _sending
                          ? null
                          : (PublicNewsTargetType? value) {
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

                              final String name =
                                  subject['name']?.toString().trim() ?? '';

                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  name.isEmpty ? 'Materia #$id' : name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          )
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: _sending
                          ? null
                          : (int? value) {
                              setState(() {
                                _subjectId = value;
                                final Map<String, dynamic>? selected =
                                    _selectedSubject;
                                if (selected != null) {
                                  _fillAcademicContext(selected);
                                }
                              });
                            },
                    ),
                  if (_isAdmin &&
                      _targetType != PublicNewsTargetType.all) ...[
                    const SizedBox(height: 14),
                    _buildAcademicFields(),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contentController,
                    enabled: !_sending,
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
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'Inserisci il contenuto';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _buildError(),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _submit,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _sending ? 'Pubblicazione...' : 'Pubblica news',
                      ),
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
                  ? 'Pubblica una comunicazione globale o indirizzata a uno specifico contesto accademico.'
                  : 'Puoi pubblicare soltanto per una materia verificata associata al tuo profilo docente.',
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
          enabled: !_sending,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Città',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _universityController,
          enabled: !_sending,
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
          enabled: !_sending,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Dipartimento',
            prefixIcon: Icon(Icons.domain_outlined),
          ),
          validator: (String? value) {
            if ((_targetType == PublicNewsTargetType.department ||
                    _targetType == PublicNewsTargetType.course) &&
                (value?.trim().isEmpty ?? true)) {
              return 'Inserisci il dipartimento';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _courseController,
          enabled: !_sending,
          style: const TextStyle(color: AppColors.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Corso',
            prefixIcon: Icon(Icons.school_outlined),
          ),
          validator: (String? value) {
            if (_targetType == PublicNewsTargetType.course &&
                (value?.trim().isEmpty ?? true)) {
              return 'Inserisci il corso';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    final String value = error.toString().toLowerCase();

    if (value.contains('401') || value.contains('non autenticato')) {
      return 'La sessione non è più valida. Accedi nuovamente.';
    }
    if (value.contains('403')) {
      return 'Non hai i permessi necessari per pubblicare in questo contesto.';
    }
    if (value.contains('404')) {
      return 'La materia o il contesto selezionato non è più disponibile.';
    }
    if (value.contains('socket') ||
        value.contains('connection') ||
        value.contains('network') ||
        value.contains('host lookup')) {
      return 'Non è stato possibile connettersi a StudentLab. Controlla la connessione e riprova.';
    }
    return 'Non è stato possibile pubblicare la news. Controlla i dati e riprova.';
  }

  String _targetValue(PublicNewsTargetType value) {
    switch (value) {
      case PublicNewsTargetType.all:
        return 'all';
      case PublicNewsTargetType.university:
        return 'university';
      case PublicNewsTargetType.department:
        return 'department';
      case PublicNewsTargetType.course:
        return 'course';
      case PublicNewsTargetType.subject:
        return 'subject';
    }
  }

  int? _toInt(dynamic value) {
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
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
