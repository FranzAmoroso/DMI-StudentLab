import 'package:flutter/material.dart';

import '../theme/nightTheme.dart';
import 'package:fe/material/models/study_material.dart';

class OnlineSubjectMaterialsPage extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final String course;

  const OnlineSubjectMaterialsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.course,
  });

  // ===========================================================================
  // MOCK
  // ===========================================================================

  List<StudyMaterial> get materials {
    return const [
      StudyMaterial(
        id: 'material_1',
        name: 'Puntatori e memoria.pdf',
        type: 'PDF',
        size: '2.4 MB',
      ),
      StudyMaterial(
        id: 'material_2',
        name: 'Array e strutture dati.pdf',
        type: 'PDF',
        size: '3.1 MB',
      ),
      StudyMaterial(
        id: 'material_3',
        name: 'Ricorsione.pdf',
        type: 'PDF',
        size: '1.7 MB',
      ),
    ];
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
          subjectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width =
                  constraints.maxWidth > 700
                      ? 700
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: ListView(
                  padding: const EdgeInsets.all(20),

                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    if (materials.isEmpty)
                      _buildEmpty()
                    else
                      ...materials.map(
                        (material) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: _buildMaterialTile(
                            context,
                            material,
                          ),
                        ),
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

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subjectName,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          course,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.55),
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(
              Icons.folder_outlined,
              color: AppColors.materialSky,
              size: 18,
            ),

            const SizedBox(width: 6),

            Text(
              '${materials.length} materiali',
              style: TextStyle(
                color: AppColors.materialSky.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // MATERIAL TILE
  // ===========================================================================

  Widget _buildMaterialTile(
    BuildContext context,
    StudyMaterial material,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoalGrey,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: AppColors.skyBlue.withOpacity(0.10),
        ),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),

        leading: Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: AppColors.brandNightBlue,
            borderRadius: BorderRadius.circular(11),
          ),

          child: const Icon(
            Icons.picture_as_pdf_outlined,
            color: AppColors.skyBlue,
            size: 22,
          ),
        ),

        title: Text(
          material.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Text(
            '${material.type} • ${material.size}',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.50),
              fontSize: 12,
            ),
          ),
        ),

        trailing: IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white54,
          ),

          onPressed: () {
            _showMaterialOptions(
              context,
              material,
            );
          },
        ),

        onTap: () {
          _openMaterial(
            context,
            material,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MATERIAL OPTIONS
  // ===========================================================================

  void _showMaterialOptions(
    BuildContext context,
    StudyMaterial material,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor: AppColors.eleganceDeepNavy,

      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(
                leading: const Icon(
                  Icons.open_in_new,
                  color: AppColors.pureWhite,
                ),

                title: const Text(
                  'Apri materiale online',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                  ),
                ),

                onTap: () {
                  Navigator.pop(sheetContext);

                  _openMaterial(
                    context,
                    material,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color: AppColors.skyBlue,
                ),

                title: const Text(
                  'Scarica offline',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                  ),
                ),

                onTap: () {
                  Navigator.pop(sheetContext);

                  _downloadMaterial(
                    context,
                    material,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // APRI ONLINE
  // ===========================================================================

  void _openMaterial(
    BuildContext context,
    StudyMaterial material,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Apertura online: ${material.name}',
        ),
      ),
    );

    // Successivamente:
    //
    // GET /subjects/{subjectId}/materials/{materialId}
    //
    // oppure URL firmato restituito dal backend.
  }

  // ===========================================================================
  // DOWNLOAD OFFLINE
  // ===========================================================================

  void _downloadMaterial(
    BuildContext context,
    StudyMaterial material,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${material.name} verrà scaricato offline.',
        ),
      ),
    );

    // Successivamente:
    //
    // 1. download dal server
    // 2. salvataggio locale
    // 3. registrazione nel database SQLite
    //
    // Il materiale apparirà quindi nella sezione
    // "Materiale offline".
  }

  // ===========================================================================
  // EMPTY
  // ===========================================================================

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: AppColors.charcoalGrey,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 45,
            color: AppColors.pureWhite.withOpacity(0.35),
          ),

          const SizedBox(height: 12),

          Text(
            'Nessun materiale',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}