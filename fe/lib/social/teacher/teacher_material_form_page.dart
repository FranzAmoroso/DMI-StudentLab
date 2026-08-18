import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/nightTheme.dart';


class TeacherMaterialFormPage
    extends StatefulWidget {
  const TeacherMaterialFormPage({
    super.key,
  });

  @override
  State<TeacherMaterialFormPage>
      createState() =>
          _TeacherMaterialFormPageState();
}


class _TeacherMaterialFormPageState
    extends State<
        TeacherMaterialFormPage> {
  final ApiService _apiService =
      ApiService();

  final TextEditingController
      _titleController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  bool _loading =
      true;

  bool _authorized =
      false;

  bool _uploading =
      false;

  String? _error;

  List<Map<String, dynamic>>
      _subjects =
      [];

  int? _selectedSubjectId;

  String _visibility =
      'students';

  PlatformFile? _selectedFile;

  String? _selectedFilePath;


  @override
  void initState() {
    super.initState();

    _initialize();
  }


  @override
  void dispose() {
    _titleController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }


  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _loading =
            true;

        _error =
            null;
      });
    }

    try {
      final bool authorized =
          await _apiService
              .canAccessTeacherArea();

      if (!mounted) {
        return;
      }

      if (!authorized) {
        setState(() {
          _authorized =
              false;

          _loading =
              false;
        });

        return;
      }

      final List<Map<String, dynamic>>
          subjects =
          await _apiService
              .getTeacherSubjects();

      if (!mounted) {
        return;
      }

      setState(() {
        _authorized =
            true;

        _subjects =
            subjects;

        if (
          subjects.length ==
          1
        ) {
          _selectedSubjectId =
              _toInt(
            subjects.first[
              'id'
            ],
          );
        }

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _authorized =
            false;

        _loading =
            false;

        _error =
            _cleanError(
          e,
        );
      });
    }
  }


  Future<void> _pickFile() async {
    if (_uploading) {
      return;
    }

    try {
      final FilePickerResult? result =
          await FilePicker.platform
              .pickFiles(
        allowMultiple:
            false,

        type:
            FileType.custom,

        allowedExtensions: [
          'pdf',
          'txt',
          'zip',
          'docx',
          'pptx',
          'xlsx',
          'csv',
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
      );

      if (result == null) {
        return;
      }

      final PlatformFile file =
          result.files.single;

      final String? path =
          file.path;

      if (
        path == null ||
        path.trim().isEmpty
      ) {
        _showMessage(
          'Impossibile ottenere il percorso del file.',
        );

        return;
      }

      if (file.size <= 0) {
        _showMessage(
          'Il file selezionato è vuoto.',
        );

        return;
      }

      if (
        file.size >
        ApiService
            .maxMaterialFileSize
      ) {
        _showMessage(
          'Il file supera la dimensione massima consentita di 250 MB.',
        );

        return;
      }

      final File localFile =
          File(
        path,
      );

      if (
        !await localFile.exists()
      ) {
        _showMessage(
          'Il file selezionato non è disponibile.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFile =
            file;

        _selectedFilePath =
            path;

        if (
          _titleController
              .text
              .trim()
              .isEmpty
        ) {
          _titleController.text =
              _titleFromFileName(
            file.name,
          );
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Errore selezione file: '
        '${_cleanError(e)}',
      );
    }
  }


  void _removeSelectedFile() {
    if (_uploading) {
      return;
    }

    setState(() {
      _selectedFile =
          null;

      _selectedFilePath =
          null;
    });
  }


  Future<void> _submit() async {
    if (_uploading) {
      return;
    }

    final bool authorized =
        await _apiService
            .canAccessTeacherArea();

    if (!mounted) {
      return;
    }

    if (!authorized) {
      setState(() {
        _authorized =
            false;
      });

      _showMessage(
        'La sessione non è autorizzata come docente verificato.',
      );

      return;
    }

    final int? subjectId =
        _selectedSubjectId;

    final String title =
        _titleController.text
            .trim();

    final String description =
        _descriptionController
            .text
            .trim();

    final String? filePath =
        _selectedFilePath;

    if (subjectId == null) {
      _showMessage(
        'Seleziona una materia.',
      );

      return;
    }

    if (title.isEmpty) {
      _showMessage(
        'Inserisci il titolo del materiale.',
      );

      return;
    }

    if (title.length > 255) {
      _showMessage(
        'Il titolo non può superare 255 caratteri.',
      );

      return;
    }

    if (
      description.length >
      5000
    ) {
      _showMessage(
        'La descrizione non può superare 5000 caratteri.',
      );

      return;
    }

    if (
      filePath == null ||
      filePath.isEmpty
    ) {
      _showMessage(
        'Seleziona un file da caricare.',
      );

      return;
    }

    setState(() {
      _uploading =
          true;

      _error =
          null;
    });

    try {
      await _apiService
          .uploadTeacherMaterial(
        subjectId:
            subjectId,

        title:
            title,

        description:
            description,

        visibility:
            _visibility,

        filePath:
            filePath,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String message =
          _cleanError(
        e,
      );

      setState(() {
        _error =
            message;
      });

      if (
        message.contains(
          '409',
        ) ||
        message
            .toLowerCase()
            .contains(
          'già presente',
        )
      ) {
        _showMessage(
          'Questo materiale è già presente per la materia selezionata.',
        );
      } else {
        _showMessage(
          'Errore caricamento materiale: $message',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading =
              false;
        });
      }
    }
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor:
            AppColors.darkElegance,

        body:
            Center(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              CircularProgressIndicator(
                color:
                    AppColors
                        .teacherIndigo,
              ),

              SizedBox(
                height:
                    16,
              ),

              Text(
                'Verifica account docente...',

                style:
                    TextStyle(
                  color:
                      Colors.white60,

                  fontSize:
                      12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_authorized) {
      return Scaffold(
        backgroundColor:
            AppColors.darkElegance,

        appBar:
            AppBar(
          backgroundColor:
              AppColors
                  .brandNightBlue,

          foregroundColor:
              AppColors
                  .pureWhite,

          title:
              const Text(
            'Carica materiale',
          ),
        ),

        body:
            Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),

            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    500,
              ),

              child:
                  Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  26,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .eleganceMidnight,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),

                  border:
                      Border.all(
                    color:
                        Colors.redAccent
                            .withOpacity(
                      0.18,
                    ),
                  ),
                ),

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons
                          .gpp_bad_outlined,

                      color:
                          Colors.redAccent,

                      size:
                          48,
                    ),

                    const SizedBox(
                      height:
                          17,
                    ),

                    const Text(
                      'Accesso non autorizzato',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        color:
                            AppColors
                                .pureWhite,

                        fontSize:
                            19,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    const Text(
                      'Solo un docente verificato e attivo può caricare materiale didattico.',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        color:
                            Colors.white54,

                        fontSize:
                            11,

                        height:
                            1.45,
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(
                        height:
                            10,
                      ),

                      Text(
                        _error!,

                        textAlign:
                            TextAlign.center,

                        style:
                            const TextStyle(
                          color:
                              Colors.white30,

                          fontSize:
                              9,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height:
                          18,
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          _initialize,

                      icon:
                          const Icon(
                        Icons
                            .refresh_rounded,
                      ),

                      label:
                          const Text(
                        'Riprova',
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

    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        elevation:
            0,

        title:
            const Text(
          'Carica materiale',

          style:
              TextStyle(
            fontSize:
                18,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  760,
            ),

            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                40,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  _buildHeader(),

                  const SizedBox(
                    height:
                        22,
                  ),

                  _buildSection(
                    title:
                        'Materia',

                    icon:
                        Icons
                            .menu_book_outlined,

                    child:
                        _buildSubjectSelector(),
                  ),

                  const SizedBox(
                    height:
                        16,
                  ),

                  _buildSection(
                    title:
                        'Informazioni',

                    icon:
                        Icons
                            .description_outlined,

                    child:
                        Column(
                      children: [
                        TextField(
                          controller:
                              _titleController,

                          enabled:
                              !_uploading,

                          maxLength:
                              255,

                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .pureWhite,

                            fontSize:
                                13,
                          ),

                          decoration:
                              _inputDecoration(
                            label:
                                'Titolo',

                            hint:
                                'Titolo del materiale',

                            icon:
                                Icons
                                    .title_rounded,
                          ),
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        TextField(
                          controller:
                              _descriptionController,

                          enabled:
                              !_uploading,

                          minLines:
                              4,

                          maxLines:
                              7,

                          maxLength:
                              5000,

                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .pureWhite,

                            fontSize:
                                13,
                          ),

                          decoration:
                              _inputDecoration(
                            label:
                                'Descrizione',

                            hint:
                                'Descrivi brevemente il contenuto',

                            icon:
                                Icons
                                    .notes_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:
                        16,
                  ),

                  _buildSection(
                    title:
                        'File',

                    icon:
                        Icons
                            .attach_file_rounded,

                    child:
                        _buildFileSelector(),
                  ),

                  const SizedBox(
                    height:
                        16,
                  ),

                  _buildSection(
                    title:
                        'Visibilità',

                    icon:
                        Icons
                            .visibility_outlined,

                    child:
                        Column(
                      children: [
                        _VisibilityOption(
                          icon:
                              Icons
                                  .groups_outlined,

                          title:
                              'Studenti',

                          description:
                              'Il materiale sarà disponibile agli studenti della materia.',

                          selected:
                              _visibility ==
                                  'students',

                          enabled:
                              !_uploading,

                          onTap:
                              () {
                            setState(() {
                              _visibility =
                                  'students';
                            });
                          },
                        ),

                        const SizedBox(
                          height:
                              9,
                        ),

                        _VisibilityOption(
                          icon:
                              Icons
                                  .lock_outline_rounded,

                          title:
                              'Privato',

                          description:
                              'Il materiale rimane visibile soltanto a te.',

                          selected:
                              _visibility ==
                                  'private',

                          enabled:
                              !_uploading,

                          onTap:
                              () {
                            setState(() {
                              _visibility =
                                  'private';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(
                      height:
                          16,
                    ),

                    _buildError(),
                  ],

                  const SizedBox(
                    height:
                        24,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    height:
                        48,

                    child:
                        FilledButton.icon(
                      onPressed:
                          _uploading
                              ? null
                              : _submit,

                      style:
                          FilledButton
                              .styleFrom(
                        backgroundColor:
                            AppColors
                                .teacherIndigo,

                        foregroundColor:
                            AppColors
                                .pureWhite,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                      ),

                      icon:
                          _uploading
                              ? const SizedBox(
                                  width:
                                      18,

                                  height:
                                      18,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,

                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .cloud_upload_outlined,
                                ),

                      label:
                          Text(
                        _uploading
                            ? 'Caricamento in corso...'
                            : 'Carica materiale',
                      ),
                    ),
                  ),

                  if (_uploading) ...[
                    const SizedBox(
                      height:
                          12,
                    ),

                    const Center(
                      child:
                          Text(
                        'Non chiudere questa pagina durante il caricamento.',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              Colors.white38,

                          fontSize:
                              9,
                        ),
                      ),
                    ),
                  ],
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
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors
                .eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          19,
        ),

        border:
            Border.all(
          color:
              AppColors
                  .teacherIndigo
                  .withOpacity(
                0.18,
              ),
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width:
                54,

            height:
                54,

            decoration:
                BoxDecoration(
              color:
                  AppColors
                      .teacherIndigo
                      .withOpacity(
                    0.14,
                  ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child:
                const Icon(
              Icons
                  .upload_file_outlined,

              color:
                  AppColors
                      .teacherIndigo,

              size:
                  28,
            ),
          ),

          const SizedBox(
            width:
                14,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Nuovo materiale didattico',

                  style:
                      TextStyle(
                    color:
                        AppColors
                            .pureWhite,

                    fontSize:
                        17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  'Il file viene caricato direttamente su Vercel Blob e associato alla materia selezionata.',

                  style:
                      TextStyle(
                    color:
                        AppColors
                            .pureWhite
                            .withOpacity(
                          0.46,
                        ),

                    fontSize:
                        10,

                    height:
                        1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        17,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors
                .eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          17,
        ),

        border:
            Border.all(
          color:
              AppColors
                  .pureWhite
                  .withOpacity(
                0.06,
              ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,

                color:
                    AppColors
                        .teacherIndigo,

                size:
                    19,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Text(
                title,

                style:
                    const TextStyle(
                  color:
                      AppColors
                          .pureWhite,

                  fontSize:
                      14,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                15,
          ),

          child,
        ],
      ),
    );
  }


  Widget _buildSubjectSelector() {
    if (_subjects.isEmpty) {
      return Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.orangeAccent
                  .withOpacity(
            0.06,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                Colors.orangeAccent
                    .withOpacity(
              0.15,
            ),
          ),
        ),

        child:
            const Text(
          'Nessuna materia associata al tuo account docente.',

          style:
              TextStyle(
            color:
                Colors.orangeAccent,

            fontSize:
                10,
          ),
        ),
      );
    }

    return DropdownButtonFormField<
        int>(
      value:
          _selectedSubjectId,

      isExpanded:
          true,

      dropdownColor:
          AppColors
              .eleganceDeepNavy,

      style:
          const TextStyle(
        color:
            AppColors.pureWhite,

        fontSize:
            12,
      ),

      decoration:
          _inputDecoration(
        label:
            'Materia',

        hint:
            'Seleziona una materia',

        icon:
            Icons
                .school_outlined,
      ),

      items:
          _subjects.map(
        (
          Map<String, dynamic>
              subject,
        ) {
          final int? id =
              _toInt(
            subject['id'],
          );

          if (id == null) {
            return null;
          }

          final String name =
              subject['name']
                      ?.toString()
                      .trim() ??
                  'Materia';

          final String code =
              subject['code']
                      ?.toString()
                      .trim() ??
                  '';

          return DropdownMenuItem<
              int>(
            value:
                id,

            child:
                Text(
              code.isEmpty
                  ? name
                  : '$code · $name',

              maxLines:
                  1,

              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          );
        },
      )
              .whereType<
                  DropdownMenuItem<
                      int>>()
              .toList(),

      onChanged:
          _uploading
              ? null
              : (
                  int? value,
                ) {
                  setState(() {
                    _selectedSubjectId =
                        value;
                  });
                },
    );
  }


  Widget _buildFileSelector() {
    final PlatformFile? file =
        _selectedFile;

    if (file == null) {
      return InkWell(
        onTap:
            _uploading
                ? null
                : _pickFile,

        borderRadius:
            BorderRadius.circular(
          13,
        ),

        child:
            Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.symmetric(
            horizontal:
                18,

            vertical:
                24,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors
                    .brandNightBlue
                    .withOpacity(
                  0.45,
                ),

            borderRadius:
                BorderRadius.circular(
              13,
            ),

            border:
                Border.all(
              color:
                  AppColors
                      .teacherIndigo
                      .withOpacity(
                    0.22,
                  ),
            ),
          ),

          child:
              const Column(
            children: [
              Icon(
                Icons
                    .cloud_upload_outlined,

                color:
                    AppColors
                        .teacherIndigo,

                size:
                    34,
              ),

              SizedBox(
                height:
                    10,
              ),

              Text(
                'Seleziona un file',

                style:
                    TextStyle(
                  color:
                      AppColors
                          .pureWhite,

                  fontSize:
                      13,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              SizedBox(
                height:
                    5,
              ),

              Text(
                'PDF, DOCX, PPTX, XLSX, TXT, CSV, ZIP e immagini · massimo 250 MB',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      Colors.white38,

                  fontSize:
                      9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors
                .brandNightBlue
                .withOpacity(
              0.45,
            ),

        borderRadius:
            BorderRadius.circular(
          13,
        ),

        border:
            Border.all(
          color:
              AppColors
                  .teacherIndigo
                  .withOpacity(
                0.22,
              ),
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width:
                46,

            height:
                46,

            decoration:
                BoxDecoration(
              color:
                  AppColors
                      .teacherIndigo
                      .withOpacity(
                    0.12,
                  ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Icon(
              _fileIcon(
                file.name,
              ),

              color:
                  AppColors
                      .teacherIndigo,

              size:
                  23,
            ),
          ),

          const SizedBox(
            width:
                12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  file.name,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        AppColors
                            .pureWhite,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height:
                      4,
                ),

                Text(
                  _formatFileSize(
                    file.size,
                  ),

                  style:
                      const TextStyle(
                    color:
                        Colors.white38,

                    fontSize:
                        9,
                  ),
                ),
              ],
            ),
          ),

          if (!_uploading)
            IconButton(
              tooltip:
                  'Rimuovi',

              onPressed:
                  _removeSelectedFile,

              icon:
                  const Icon(
                Icons
                    .close_rounded,

                color:
                    Colors.redAccent,

                size:
                    20,
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildError() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.redAccent
                .withOpacity(
          0.06,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              Colors.redAccent
                  .withOpacity(
            0.14,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons
                .error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                17,
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Text(
              _error!,

              style:
                  const TextStyle(
                color:
                    Colors.white54,

                fontSize:
                    9,

                height:
                    1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }


  InputDecoration
      _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      prefixIcon:
          Icon(
        icon,

        color:
            AppColors
                .teacherIndigo,

        size:
            19,
      ),

      labelStyle:
          const TextStyle(
        color:
            Colors.white54,

        fontSize:
            11,
      ),

      hintStyle:
          const TextStyle(
        color:
            Colors.white30,

        fontSize:
            10,
      ),

      filled:
          true,

      fillColor:
          AppColors
              .brandNightBlue
              .withOpacity(
            0.45,
          ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(
          color:
              AppColors
                  .pureWhite
                  .withOpacity(
                0.07,
              ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors
                  .teacherIndigo,
        ),
      ),

      disabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),

        borderSide:
            BorderSide(
          color:
              AppColors
                  .pureWhite
                  .withOpacity(
                0.04,
              ),
        ),
      ),
    );
  }


  String _titleFromFileName(
    String fileName,
  ) {
    final int dot =
        fileName.lastIndexOf(
      '.',
    );

    if (dot <= 0) {
      return fileName;
    }

    return fileName.substring(
      0,
      dot,
    );
  }


  String _formatFileSize(
    int size,
  ) {
    if (size < 1024) {
      return '$size B';
    }

    if (
      size <
      1024 * 1024
    ) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }

    if (
      size <
      1024 * 1024 * 1024
    ) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }


  IconData _fileIcon(
    String fileName,
  ) {
    final String lower =
        fileName
            .trim()
            .toLowerCase();

    if (
      lower.endsWith(
        '.pdf',
      )
    ) {
      return Icons
          .picture_as_pdf_outlined;
    }

    if (
      lower.endsWith(
        '.doc',
      ) ||
      lower.endsWith(
        '.docx',
      )
    ) {
      return Icons
          .description_outlined;
    }

    if (
      lower.endsWith(
        '.ppt',
      ) ||
      lower.endsWith(
        '.pptx',
      )
    ) {
      return Icons
          .slideshow_outlined;
    }

    if (
      lower.endsWith(
        '.xls',
      ) ||
      lower.endsWith(
        '.xlsx',
      ) ||
      lower.endsWith(
        '.csv',
      )
    ) {
      return Icons
          .table_chart_outlined;
    }

    if (
      lower.endsWith(
        '.zip',
      )
    ) {
      return Icons
          .folder_zip_outlined;
    }

    if (
      lower.endsWith(
        '.jpg',
      ) ||
      lower.endsWith(
        '.jpeg',
      ) ||
      lower.endsWith(
        '.png',
      ) ||
      lower.endsWith(
        '.webp',
      )
    ) {
      return Icons
          .image_outlined;
    }

    return Icons
        .insert_drive_file_outlined;
  }


  int? _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ??
          '',
    );
  }


  String _cleanError(
    Object error,
  ) {
    String value =
        error.toString();

    if (
      value.startsWith(
        'Exception: ',
      )
    ) {
      value =
          value.substring(
        11,
      );
    }

    return value;
  }


  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
      ),
    );
  }
}


class _VisibilityOption
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String description;

  final bool selected;

  final bool enabled;

  final VoidCallback onTap;


  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          enabled
              ? onTap
              : null,

      borderRadius:
          BorderRadius.circular(
        13,
      ),

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              170,
        ),

        width:
            double.infinity,

        padding:
            const EdgeInsets.all(
          13,
        ),

        decoration:
            BoxDecoration(
          color:
              selected
                  ? AppColors
                      .teacherIndigo
                      .withOpacity(
                        0.13,
                      )
                  : AppColors
                      .brandNightBlue
                      .withOpacity(
                        0.42,
                      ),

          borderRadius:
              BorderRadius.circular(
            13,
          ),

          border:
              Border.all(
            color:
                selected
                    ? AppColors
                        .teacherIndigo
                        .withOpacity(
                          0.70,
                        )
                    : AppColors
                        .pureWhite
                        .withOpacity(
                          0.06,
                        ),
          ),
        ),

        child:
            Row(
          children: [
            Container(
              width:
                  42,

              height:
                  42,

              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .teacherIndigo
                        .withOpacity(
                      selected
                          ? 0.17
                          : 0.07,
                    ),

                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),

              child:
                  Icon(
                icon,

                color:
                    selected
                        ? AppColors
                            .teacherIndigo
                        : Colors.white38,

                size:
                    21,
              ),
            ),

            const SizedBox(
              width:
                  11,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style:
                        TextStyle(
                      color:
                          selected
                              ? AppColors
                                  .pureWhite
                              : Colors.white70,

                      fontSize:
                          12,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height:
                        3,
                  ),

                  Text(
                    description,

                    style:
                        const TextStyle(
                      color:
                          Colors.white38,

                      fontSize:
                          9,

                      height:
                          1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Icon(
              selected
                  ? Icons
                      .radio_button_checked_rounded
                  : Icons
                      .radio_button_off_rounded,

              color:
                  selected
                      ? AppColors
                          .teacherIndigo
                      : Colors.white24,

              size:
                  20,
            ),
          ],
        ),
      ),
    );
  }
}