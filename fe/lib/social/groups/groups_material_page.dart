import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../../services/api_service.dart';


// =============================================================================
// GROUP MATERIALS PAGE
// =============================================================================

class GroupMaterialsPage extends StatefulWidget {
  final int groupId;

  final String groupName;

  final int? subjectId;

  final String subjectName;


  const GroupMaterialsPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.subjectId,
    required this.subjectName,
  });


  @override
  State<GroupMaterialsPage> createState() =>
      _GroupMaterialsPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _GroupMaterialsPageState
    extends State<GroupMaterialsPage> {

  final ApiService _apiService =
      ApiService();


  List<GroupMaterialModel> _materials =
      [];


  bool _loading =
      true;


  String? _error;


  int? _downloadingMaterialId;


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadMaterials();
  }


  // ===========================================================================
  // CARICA MATERIALI
  // ===========================================================================

  Future<void> _loadMaterials() async {
    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final List<Map<String, dynamic>>
          response =
          await _apiService
              .getGroupMaterials(
        widget.groupId,
      );


      final List<GroupMaterialModel>
          materials =
          response
              .map(
                GroupMaterialModel.fromJson,
              )
              .toList();


      if (!mounted) {
        return;
      }


      setState(() {
        _materials =
            materials;

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
            e.toString();
      });
    }
  }


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
          'Materiali',

          style:
              TextStyle(
            fontSize:
                19,

            fontWeight:
                FontWeight.w500,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            onPressed:
                _loading
                    ? null
                    : _loadMaterials,
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
                          700
                      ? 700
                      : constraints
                          .maxWidth;


              return SizedBox(
                width:
                    width,

                child:
                    _buildBody(),
              );
            },
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }


    if (_error != null) {
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
            _buildHeader(),

            const SizedBox(
              height:
                  20,
            ),

            _buildError(),
          ],
        ),
      );
    }


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
          _buildHeader(),

          const SizedBox(
            height:
                20,
          ),

          _buildSectionHeader(),

          const SizedBox(
            height:
                14,
          ),

          if (_materials.isEmpty)
            _buildEmpty()
          else
            ..._materials.map(
              (
                material,
              ) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom:
                        12,
                  ),

                  child:
                      _buildMaterialCard(
                    context,
                    material,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }


  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,

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
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
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
                    15,
                  ),
                ),

                child:
                    const Icon(
                  Icons.folder_rounded,

                  color:
                      AppColors.skyBlue,

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
                    Text(
                      widget.groupName,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      _subjectText(),

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            AppColors.materialSky,

                        fontSize:
                            13,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          Text(
            'Materiali condivisi nel gruppo.',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.60,
              ),

              fontSize:
                  13,

              height:
                  1.4,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          Row(
            children: [
              const Icon(
                Icons.folder_outlined,

                color:
                    AppColors.materialSky,

                size:
                    16,
              ),

              const SizedBox(
                width:
                    6,
              ),

              Text(
                '${_materials.length} materiali',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.55,
                  ),

                  fontSize:
                      11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child:
              Text(
            'File condivisi',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                9,

            vertical:
                5,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors.brandNightBlue,

            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),

          child:
              Text(
            '${_materials.length}',

            style:
                const TextStyle(
              color:
                  AppColors.materialSky,

              fontSize:
                  11,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // MATERIAL CARD
  // ===========================================================================

  Widget _buildMaterialCard(
    BuildContext context,
    GroupMaterialModel material,
  ) {
    final bool downloading =
        _downloadingMaterialId ==
            material.id;


    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.charcoalGrey,

        borderRadius:
            BorderRadius.circular(
          16,
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
                  AppColors.brandNightBlue,

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                Icon(
              _materialIcon(
                material.type,
              ),

              color:
                  AppColors.skyBlue,

              size:
                  24,
            ),
          ),

          const SizedBox(
            width:
                13,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  material.originalName,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        14,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  '${material.type} • ${material.formattedSize}',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.50,
                    ),

                    fontSize:
                        12,
                  ),
                ),

                if (material.createdAt !=
                    null) ...[
                  const SizedBox(
                    height:
                        4,
                  ),

                  Text(
                    _formatDate(
                      material.createdAt!,
                    ),

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(
                        0.32,
                      ),

                      fontSize:
                          10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width:
                10,
          ),

          IconButton(
            tooltip:
                'Scarica',

            onPressed:
                downloading
                    ? null
                    : () {
                        _downloadMaterial(
                          context,
                          material,
                        );
                      },

            icon:
                downloading
                    ? const SizedBox(
                        width:
                            20,

                        height:
                            20,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,

                        color:
                            AppColors.materialSky,
                      ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // DOWNLOAD
  // ===========================================================================

  Future<void> _downloadMaterial(
    BuildContext context,
    GroupMaterialModel material,
  ) async {
    setState(() {
      _downloadingMaterialId =
          material.id;
    });


    try {
      final bytes =
          await _apiService
              .downloadGroupMaterial(
        material.id,
      );


      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            '${material.originalName} scaricato '
            '(${bytes.length} byte).',
          ),
        ),
      );


      /*
       * PROSSIMO PASSAGGIO
       *
       * Qui abbiamo già i byte reali ricevuti da FastAPI.
       *
       * Dovremo:
       *
       * 1. scegliere una directory locale;
       * 2. salvare i bytes su disco;
       * 3. registrare il percorso in SQLite;
       *
       * downloaded_materials:
       *
       * material_id
       * local_path
       * downloaded_at
       */
    } catch (e) {
      if (!mounted) {
        return;
      }


      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            'Errore download: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingMaterialId =
              null;
        });
      }
    }
  }


  // ===========================================================================
  // ICONA
  // ===========================================================================

  IconData _materialIcon(
    String type,
  ) {
    switch (
        type.toUpperCase()) {
      case 'PDF':
        return Icons
            .picture_as_pdf_outlined;

      case 'DOC':
      case 'DOCX':
        return Icons
            .description_outlined;

      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_outlined;

      case 'ZIP':
        return Icons
            .archive_outlined;

      case 'TXT':
        return Icons
            .text_snippet_outlined;

      default:
        return Icons
            .insert_drive_file_outlined;
    }
  }


  // ===========================================================================
  // SUBJECT
  // ===========================================================================

  String _subjectText() {
    if (widget.subjectName
        .trim()
        .isNotEmpty) {
      return widget.subjectName;
    }


    if (widget.subjectId != null) {
      return 'Materia #${widget.subjectId}';
    }


    return 'Materia non specificata';
  }


  // ===========================================================================
  // DATA
  // ===========================================================================

  String _formatDate(
    DateTime date,
  ) {
    final String day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );


    final String month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );


    return '$day/$month/${date.year}';
  }


  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.charcoalGrey,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              Colors.redAccent
                  .withOpacity(
            0.20,
          ),
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                42,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'Impossibile caricare i materiali',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            _error ??
                'Errore sconosciuto.',

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
                  1.4,
            ),
          ),

          const SizedBox(
            height:
                16,
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


  // ===========================================================================
  // EMPTY
  // ===========================================================================

  Widget _buildEmpty() {
    return Container(
      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.charcoalGrey,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Column(
        children: [
          Icon(
            Icons.folder_off_outlined,

            size:
                45,

            color:
                AppColors.pureWhite
                    .withOpacity(
              0.35,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          Text(
            'Nessun materiale',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.80,
              ),

              fontSize:
                  16,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                6,
          ),

          Text(
            'Il gruppo non ha ancora condiviso materiale.',

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
                  13,
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// GROUP MATERIAL MODEL
// =============================================================================

class GroupMaterialModel {
  final int id;

  final int groupId;

  final int uploadedBy;

  final String originalName;

  final String storedName;

  final String filePath;

  final String mimeType;

  final int size;

  final DateTime? createdAt;


  const GroupMaterialModel({
    required this.id,
    required this.groupId,
    required this.uploadedBy,
    required this.originalName,
    required this.storedName,
    required this.filePath,
    required this.mimeType,
    required this.size,
    required this.createdAt,
  });


  factory GroupMaterialModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupMaterialModel(
      id:
          _toInt(
            json['id'],
          ) ??
          0,

      groupId:
          _toInt(
            json['group_id'],
          ) ??
          0,

      uploadedBy:
          _toInt(
            json['uploaded_by'],
          ) ??
          0,

      originalName:
          json['original_name']
                  ?.toString() ??
              '',

      storedName:
          json['stored_name']
                  ?.toString() ??
              '',

      filePath:
          json['file_path']
                  ?.toString() ??
              '',

      mimeType:
          json['mime_type']
                  ?.toString() ??
              'application/octet-stream',

      size:
          _toInt(
            json['size'],
          ) ??
          0,

      createdAt:
          DateTime.tryParse(
        json['created_at']
                ?.toString() ??
            '',
      ),
    );
  }


  // ===========================================================================
  // TIPO
  // ===========================================================================

  String get type {
    final String mime =
        mimeType.toLowerCase();


    if (mime.contains(
      'pdf',
    )) {
      return 'PDF';
    }


    if (mime.contains(
      'wordprocessingml',
    ) ||
        mime.contains(
          'msword',
        )) {
      return 'DOCX';
    }


    if (mime.contains(
      'presentationml',
    ) ||
        mime.contains(
          'powerpoint',
        )) {
      return 'PPTX';
    }


    if (mime.contains(
      'zip',
    )) {
      return 'ZIP';
    }


    if (mime.contains(
      'text/plain',
    )) {
      return 'TXT';
    }


    return 'FILE';
  }


  // ===========================================================================
  // DIMENSIONE
  // ===========================================================================

  String get formattedSize {
    if (size <
        1024) {
      return '$size B';
    }


    if (size <
        1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }


    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }


  // ===========================================================================
  // UTILITY
  // ===========================================================================

  static int? _toInt(
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
}