import 'package:flutter/material.dart';

import 'models/subject_notebook.dart';
import 'models/study_material.dart';

import 'widgets/subject_notebook_card.dart';
import 'widgets/material_card.dart';

import 'package:fe/theme/nightTheme.dart';

class StudentMaterialPage extends StatefulWidget {
  const StudentMaterialPage({super.key});

  @override
  State<StudentMaterialPage> createState() => _StudentMaterialPageState();
}

class _StudentMaterialPageState extends State<StudentMaterialPage> {

  SubjectNotebook? selectedSubject;

  final List<SubjectNotebook> subjects = const [

    SubjectNotebook(
      id: 'algebra',
      name: 'Algebra Lineare',
      course: 'Matematica',
      department: 'DMI',
      materialCount: 12,
    ),

    SubjectNotebook(
      id: 'programmazione1',
      name: 'Programmazione 1',
      course: 'Scienze e Tecnologie Informatiche',
      department: 'DMI',
      materialCount: 8,
    ),

    SubjectNotebook(
      id: 'architettura',
      name: 'Architettura degli Elaboratori',
      course: 'Informatica',
      department: 'DMI',
      materialCount: 5,
    ),

    SubjectNotebook(
      id: 'multimedia',
      name: 'Interazione e Multimedia',
      course: 'Informatica',
      department: 'DMI',
      materialCount: 14,
    ),
  ];

  final List<StudyMaterial> materials = const [

    StudyMaterial(
      id: '1',
      name: 'Puntatori e memoria.pdf',
      type: 'PDF',
      size: '2.4 MB',
    ),

    StudyMaterial(
      id: '2',
      name: 'Array e strutture dati.pdf',
      type: 'PDF',
      size: '1.8 MB',
    ),

    StudyMaterial(
      id: '3',
      name: 'Appunti lezione 12',
      type: 'Document',
      size: '540 KB',
    ),

    StudyMaterial(
      id: '4',
      name: 'Esercizi programmazione.pdf',
      type: 'PDF',
      size: '3.1 MB',
    ),
  ];

  @override
  Widget build(BuildContext context) {

    if (selectedSubject == null) {
      return _buildSubjectSelection();
    }

    return _buildMaterialList();
  }

  Widget _buildSubjectSelection() {

    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,

        title: const Text(
          'Materiale',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {

              final bool largeScreen =
                  constraints.maxWidth > 700;

              final double width =
                  largeScreen
                      ? 700
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: GridView.builder(
                  padding: const EdgeInsets.all(20),

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),

                  itemCount: subjects.length,

                  itemBuilder: (context, index) {

                    final subject = subjects[index];

                    return SubjectNotebookCard(
                      subject: subject,

                      onTap: () {

                        setState(() {
                          selectedSubject = subject;
                        });

                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialList() {

    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),

          onPressed: () {

            setState(() {
              selectedSubject = null;
            });

          },
        ),

        title: Text(
          selectedSubject!.name,

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

              final bool largeScreen =
                  constraints.maxWidth > 700;

              final double width =
                  largeScreen
                      ? 700
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: ListView(
                  padding: const EdgeInsets.all(20),

                  children: [

                    _buildAddMaterialButton(),

                    const SizedBox(height: 28),

                    const Text(
                      'Materiali disponibili',

                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (materials.isEmpty)

                      _buildEmptyMaterials()

                    else

                      ...materials.map(
                        (material) {

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),

                            child: MaterialCard(
                              material: material,

                              onTap: () {
                                _openMaterial(material);
                              },
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


  Widget _buildAddMaterialButton() {

    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: _addMaterial,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: AppColors.brandNightBlue,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: AppColors.skyBlue
                .withOpacity(0.25),
          ),
        ),

        child: Row(
          children: [

            Container(
              width: 45,
              height: 45,

              decoration: BoxDecoration(
                color: AppColors.skyBlue
                    .withOpacity(0.15),

                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.add_rounded,
                color: AppColors.skyBlue,
              ),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    'Aggiungi nuovo materiale',

                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'Carica un nuovo file nel quaderno',

                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMaterials() {

    return Container(
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: AppColors.materialNavy,
        borderRadius: BorderRadius.circular(16),
      ),

      child: const Column(
        children: [

          Icon(
            Icons.folder_open_rounded,
            color: Colors.white38,
            size: 45,
          ),

          SizedBox(height: 12),

          Text(
            'Nessun materiale disponibile',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMaterial() async {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'File picker: da implementare',
        ),
      ),
    );
  }

  void _openMaterial(StudyMaterial material) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Apertura: ${material.name}',
        ),
      ),
    );
  }
}