import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'package:fe/theme/nightTheme.dart';

import 'package:fe/material/models/subject_notebook.dart';
import 'package:fe/material/models/study_material.dart';

import 'package:fe/material/widgets/subject_notebook_card.dart';
import 'package:fe/material/widgets/material_card.dart';

import 'package:fe/local_storage/models/downloaded_material_local.dart';
import 'package:fe/local_storage/services/material_download_service.dart';


class StudentMaterialPage extends StatefulWidget {
  const StudentMaterialPage({
    super.key,
  });

  @override
  State<StudentMaterialPage> createState() =>
      _StudentMaterialPageState();
}


class _StudentMaterialPageState
    extends State<StudentMaterialPage> {

  final MaterialDownloadService _downloadService =
      MaterialDownloadService();

  List<DownloadedMaterialLocal> _downloadedMaterials =
      [];

  List<SubjectNotebook> _subjects =
      [];

  SubjectNotebook? _selectedSubject;

  bool _loading =
      true;

  String? _error;


  @override
  void initState() {
    super.initState();

    _loadMaterials();
  }


  Future<void> _loadMaterials() async {
    if (mounted) {
      setState(() {
        _loading =
            true;

        _error =
            null;
      });
    }

    try {
      final List<DownloadedMaterialLocal> materials =
          await _downloadService
              .getDownloadedMaterials();

      final List<SubjectNotebook> subjects =
          _buildSubjects(
        materials,
      );

      if (!mounted) {
        return;
      }

      SubjectNotebook? selectedSubject =
          _selectedSubject;

      if (selectedSubject != null) {
        final SubjectNotebook? updatedSubject =
            _findSubject(
          subjects,
          selectedSubject.id,
        );

        selectedSubject =
            updatedSubject;
      }

      setState(() {
        _downloadedMaterials =
            materials;

        _subjects =
            subjects;

        _selectedSubject =
            selectedSubject;

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading =
            false;

        _error =
            _cleanError(
          e,
        );
      });
    }
  }


  SubjectNotebook? _findSubject(
    List<SubjectNotebook> subjects,
    String id,
  ) {
    for (final SubjectNotebook subject
        in subjects) {
      if (subject.id ==
          id) {
        return subject;
      }
    }

    return null;
  }


  List<SubjectNotebook> _buildSubjects(
    List<DownloadedMaterialLocal> materials,
  ) {
    final Map<String, List<DownloadedMaterialLocal>>
        grouped =
        {};

    for (final DownloadedMaterialLocal material
        in materials) {

      final String subjectName =
          material.subjectName
                  ?.trim() ??
              '';

      if (material.subjectId ==
              null &&
          subjectName.isEmpty) {
        continue;
      }

      final String key;

      if (material.subjectId !=
          null) {
        key =
            'id:${material.subjectId}';
      } else {
        key =
            'name:${subjectName.toLowerCase()}';
      }

      grouped.putIfAbsent(
        key,
        () =>
            [],
      );

      grouped[key]!.add(
        material,
      );
    }

    final List<SubjectNotebook> subjects =
        [];

    for (final MapEntry<
            String,
            List<DownloadedMaterialLocal>>
        entry in grouped.entries) {

      if (entry.value.isEmpty) {
        continue;
      }

      final DownloadedMaterialLocal first =
          entry.value.first;

      final String subjectName;

      if (first.subjectName !=
              null &&
          first.subjectName!
              .trim()
              .isNotEmpty) {
        subjectName =
            first.subjectName!
                .trim();
      } else if (first.subjectId !=
          null) {
        subjectName =
            'Materia #${first.subjectId}';
      } else {
        subjectName =
            'Materia';
      }

      final String course;

      if (first.course !=
              null &&
          first.course!
              .trim()
              .isNotEmpty) {
        course =
            first.course!
                .trim();
      } else {
        course =
            'Corso non specificato';
      }

      final String department;

      if (first.department !=
              null &&
          first.department!
              .trim()
              .isNotEmpty) {
        department =
            first.department!
                .trim();
      } else {
        department =
            'Dipartimento non specificato';
      }

      subjects.add(
        SubjectNotebook(
          id:
              entry.key,

          name:
              subjectName,

          course:
              course,

          department:
              department,

          materialCount:
              entry.value.length,
        ),
      );
    }

    subjects.sort(
      (
        SubjectNotebook a,
        SubjectNotebook b,
      ) =>
          a.name
              .toLowerCase()
              .compareTo(
                b.name
                    .toLowerCase(),
              ),
    );

    return subjects;
  }


  List<DownloadedMaterialLocal>
      get _selectedMaterials {

    final SubjectNotebook? subject =
        _selectedSubject;

    if (subject ==
        null) {
      return [];
    }

    final List<DownloadedMaterialLocal>
        materials =
        _downloadedMaterials.where(
      (
        DownloadedMaterialLocal material,
      ) {
        if (subject.id.startsWith(
          'id:',
        )) {
          final int? subjectId =
              int.tryParse(
            subject.id.substring(
              3,
            ),
          );

          return material.subjectId ==
              subjectId;
        }

        if (subject.id.startsWith(
          'name:',
        )) {
          final String subjectName =
              subject.id
                  .substring(
                    5,
                  )
                  .trim()
                  .toLowerCase();

          final String materialSubject =
              material.subjectName
                      ?.trim()
                      .toLowerCase() ??
                  '';

          return materialSubject ==
              subjectName;
        }

        return false;
      },
    ).toList();

    materials.sort(
      (
        DownloadedMaterialLocal a,
        DownloadedMaterialLocal b,
      ) =>
          b.downloadedAt.compareTo(
            a.downloadedAt,
          ),
    );

    return materials;
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    if (_selectedSubject ==
        null) {
      return _buildSubjectSelection();
    }

    return _buildMaterialList();
  }


  Widget _buildSubjectSelection() {
    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        title:
            const Text(
          'Materiale',

          style:
              TextStyle(
            fontSize:
                20,

            fontWeight:
                FontWeight.w500,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            onPressed:
                _loading
                    ? null
                    : _loadMaterials,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            _buildSubjectBody(),
      ),
    );
  }


  Widget _buildSubjectBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error !=
        null) {
      return Center(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            20,
          ),

          child:
              _buildErrorCard(),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            _loadMaterials,

        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(
            20,
          ),

          children: [
            const SizedBox(
              height:
                  80,
            ),

            _buildEmptyLibrary(),
          ],
        ),
      );
    }

    return Center(
      child:
          LayoutBuilder(
        builder:
            (
          context,
          constraints,
        ) {

          final double width =
              constraints.maxWidth >
                      900
                  ? 900
                  : constraints
                      .maxWidth;

          int columns =
              2;

          if (width <
              430) {
            columns =
                1;
          } else if (width >=
              750) {
            columns =
                3;
          }

          return SizedBox(
            width:
                width,

            child:
                RefreshIndicator(
              onRefresh:
                  _loadMaterials,

              child:
                  GridView.builder(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                itemCount:
                    _subjects.length,

                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      columns,

                  crossAxisSpacing:
                      14,

                  mainAxisSpacing:
                      14,

                  mainAxisExtent:
                      205,
                ),

                itemBuilder:
                    (
                  context,
                  index,
                ) {

                  final SubjectNotebook subject =
                      _subjects[index];

                  return SubjectNotebookCard(
                    subject:
                        subject,

                    onTap:
                        () {
                      setState(() {
                        _selectedSubject =
                            subject;
                      });
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildMaterialList() {
    final SubjectNotebook subject =
        _selectedSubject!;

    final List<DownloadedMaterialLocal>
        materials =
        _selectedMaterials;

    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,

      appBar:
          AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        leading:
            IconButton(
          icon:
              const Icon(
            Icons.arrow_back_rounded,
          ),

          onPressed:
              () {
            setState(() {
              _selectedSubject =
                  null;
            });
          },
        ),

        title:
            Text(
          subject.name,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            fontSize:
                18,

            fontWeight:
                FontWeight.w500,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            onPressed:
                _loading
                    ? null
                    : _loadMaterials,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {

              final double width =
                  constraints.maxWidth >
                          750
                      ? 750
                      : constraints
                          .maxWidth;

              return SizedBox(
                width:
                    width,

                child:
                    _loading
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : RefreshIndicator(
                            onRefresh:
                                _loadMaterials,

                            child:
                                ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),

                              padding:
                                  const EdgeInsets.all(
                                20,
                              ),

                              children: [
                                _buildSubjectHeader(
                                  subject,
                                  materials.length,
                                ),

                                const SizedBox(
                                  height:
                                      26,
                                ),

                                const Text(
                                  'Disponibili offline',

                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.pureWhite,

                                    fontSize:
                                        20,

                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      6,
                                ),

                                Text(
                                  materials.length ==
                                          1
                                      ? '1 materiale salvato in StudentLab.'
                                      : '${materials.length} materiali salvati in StudentLab.',

                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.pureWhite
                                            .withOpacity(
                                      0.48,
                                    ),

                                    fontSize:
                                        11,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      14,
                                ),

                                if (materials.isEmpty)
                                  _buildEmptyMaterials()
                                else
                                  ...materials.map(
                                    (
                                      DownloadedMaterialLocal
                                          localMaterial,
                                    ) {

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          bottom:
                                              10,
                                        ),

                                        child:
                                            MaterialCard(
                                          material:
                                              _toStudyMaterial(
                                            localMaterial,
                                          ),

                                          onTap:
                                              () {
                                            _openMaterial(
                                              localMaterial,
                                            );
                                          },
                                        ),
                                      );
                                    },
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


  Widget _buildSubjectHeader(
    SubjectNotebook subject,
    int count,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.15,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width:
                52,

            height:
                52,

            decoration:
                BoxDecoration(
              color:
                  AppColors.brandNightBlue,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child:
                const Icon(
              Icons.menu_book_rounded,

              color:
                  AppColors.skyBlue,

              size:
                  27,
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
                Text(
                  subject.name,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      4,
                ),

                Text(
                  subject.course,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white60,

                    fontSize:
                        11,
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  subject.department,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white38,

                    fontSize:
                        10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  10,

              vertical:
                  7,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.skyBlue
                      .withOpacity(
                0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child:
                Text(
              '$count',

              style:
                  const TextStyle(
                color:
                    AppColors.materialSky,

                fontSize:
                    12,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  StudyMaterial _toStudyMaterial(
    DownloadedMaterialLocal material,
  ) {
    return StudyMaterial(
      id:
          material.materialId
              .toString(),

      name:
          material.originalName,

      type:
          _materialType(
        material,
      ),

      size:
          _formatSize(
        material.size,
      ),
    );
  }


  String _materialType(
    DownloadedMaterialLocal material,
  ) {
    final String mimeType =
        material.mimeType
                ?.trim()
                .toLowerCase() ??
            '';

    final String name =
        material.originalName
            .trim()
            .toLowerCase();

    if (mimeType ==
            'application/pdf' ||
        name.endsWith(
          '.pdf',
        )) {
      return 'PDF';
    }

    if (mimeType.contains(
          'wordprocessingml',
        ) ||
        name.endsWith(
          '.docx',
        ) ||
        name.endsWith(
          '.doc',
        )) {
      return 'Document';
    }

    if (mimeType.contains(
          'presentationml',
        ) ||
        name.endsWith(
          '.pptx',
        ) ||
        name.endsWith(
          '.ppt',
        )) {
      return 'PPTX';
    }

    if (mimeType ==
            'text/plain' ||
        name.endsWith(
          '.txt',
        )) {
      return 'Document';
    }

    if (mimeType.contains(
          'zip',
        ) ||
        name.endsWith(
          '.zip',
        )) {
      return 'ZIP';
    }

    if (mimeType.startsWith(
          'image/',
        ) ||
        name.endsWith(
          '.png',
        ) ||
        name.endsWith(
          '.jpg',
        ) ||
        name.endsWith(
          '.jpeg',
        ) ||
        name.endsWith(
          '.webp',
        )) {
      return 'Image';
    }

    return 'File';
  }


  String _formatSize(
    int? size,
  ) {
    if (size ==
            null ||
        size <=
            0) {
      return 'Dimensione sconosciuta';
    }

    if (size <
        1024) {
      return '$size B';
    }

    if (size <
        1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }

    if (size <
        1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }


  Future<void> _openMaterial(
    DownloadedMaterialLocal material,
  ) async {
    try {
      final File? file =
          await _downloadService
              .getFile(
        materialId:
            material.materialId,
      );

      if (!mounted) {
        return;
      }

      if (file ==
          null) {
        await _loadMaterials();

        _showMessage(
          'Il file non è più disponibile sul dispositivo.',
        );

        return;
      }

      final bool exists =
          await file.exists();

      if (!exists) {
        await _loadMaterials();

        _showMessage(
          'Il file non è più disponibile sul dispositivo.',
        );

        return;
      }

      final OpenResult result =
          await OpenFilex.open(
        file.path,
      );

      if (!mounted) {
        return;
      }

      switch (result.type) {
        case ResultType.done:
          return;

        case ResultType.noAppToOpen:
          _showMessage(
            'Nessuna applicazione installata può aprire questo tipo di file.',
          );

          return;

        case ResultType.fileNotFound:
          await _loadMaterials();

          _showMessage(
            'Il file non è stato trovato sul dispositivo.',
          );

          return;

        case ResultType.permissionDenied:
          _showMessage(
            'StudentLab non ha il permesso di aprire il file.',
          );

          return;

        case ResultType.error:
          _showMessage(
            result.message.isNotEmpty
                ? result.message
                : 'Impossibile aprire il file.',
          );

          return;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Errore apertura file: ${_cleanError(e)}',
      );
    }
  }


  Widget _buildEmptyLibrary() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.10,
          ),
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons
                .download_for_offline_outlined,

            color:
                AppColors.skyBlue,

            size:
                46,
          ),

          const SizedBox(
            height:
                14,
          ),

          const Text(
            'Nessun materiale offline',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  16,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            'I materiali che scarichi dai gruppi StudentLab '
            'compariranno automaticamente qui, organizzati per materia.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.50,
              ),

              fontSize:
                  11,

              height:
                  1.45,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyMaterials() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.materialNavy,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.folder_open_rounded,

            color:
                Colors.white38,

            size:
                45,
          ),

          SizedBox(
            height:
                12,
          ),

          Text(
            'Nessun materiale disponibile offline',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.white70,

              fontSize:
                  14,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildErrorCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        24,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                40,
          ),

          const SizedBox(
            height:
                12,
          ),

          Text(
            _error ??
                'Errore sconosciuto',

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white60,

              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height:
                15,
          ),

          OutlinedButton.icon(
            onPressed:
                _loadMaterials,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            label:
                const Text(
              'Riprova',
            ),
          ),
        ],
      ),
    );
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


  String _cleanError(
    Object error,
  ) {
    String message =
        error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
}