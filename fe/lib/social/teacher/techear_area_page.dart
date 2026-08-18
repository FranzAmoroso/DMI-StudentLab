import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../theme/nightTheme.dart';


class TeacherAreaPage
    extends StatefulWidget {
  const TeacherAreaPage({
    super.key,
  });

  @override
  State<TeacherAreaPage> createState() =>
      _TeacherAreaPageState();
}


class _TeacherAreaPageState
    extends State<TeacherAreaPage> {
  final ApiService _apiService =
      ApiService();

  bool _loading =
      true;

  bool _authorized =
      false;

  String? _error;


  @override
  void initState() {
    super.initState();

    _verifyAccess();
  }


  Future<void> _verifyAccess() async {
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

      setState(() {
        _authorized =
            authorized;

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
            e.toString();
      });
    }
  }


  Future<bool>
      _verifyBeforeAction() async {
    try {
      final bool authorized =
          await _apiService
              .canAccessTeacherArea();

      if (!mounted) {
        return false;
      }

      if (!authorized) {
        setState(() {
          _authorized =
              false;
        });

        return false;
      }

      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Impossibile verificare i permessi docente.',
          ),
        ),
      );

      return false;
    }
  }


  Future<void>
      _openMaterials() async {
    final bool authorized =
        await _verifyBeforeAction();

    if (!authorized) {
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Gestione materiali docente pronta per il prossimo modulo.',
        ),
      ),
    );
  }


  Future<void>
      _openSubjects() async {
    final bool authorized =
        await _verifyBeforeAction();

    if (!authorized) {
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Gestione materie docente pronta per il prossimo modulo.',
        ),
      ),
    );
  }


  Future<void>
      _openStudents() async {
    final bool authorized =
        await _verifyBeforeAction();

    if (!authorized) {
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Distribuzione agli studenti pronta per il prossimo modulo.',
        ),
      ),
    );
  }


  Future<void>
      _openSharedContent() async {
    final bool authorized =
        await _verifyBeforeAction();

    if (!authorized) {
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Contenuti condivisi pronti per il prossimo modulo.',
        ),
      ),
    );
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
                    AppColors.teacherIndigo,
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
      return _TeacherAccessDeniedPage(
        error:
            _error,

        onRetry:
            _verifyAccess,
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
          'Area Docenti',

          style:
              TextStyle(
            fontSize:
                18,

            fontWeight:
                FontWeight.w500,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Verifica accesso',

            onPressed:
                _verifyAccess,

            icon:
                const Icon(
              Icons.verified_user_outlined,
            ),
          ),
        ],
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
                  1000,
            ),

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              children: [
                _buildHeader(),

                const SizedBox(
                  height:
                      28,
                ),

                const _TeacherSectionTitle(
                  title:
                      'Didattica',

                  subtitle:
                      'Gestisci e condividi contenuti didattici attraverso il tuo account docente verificato.',
                ),

                const SizedBox(
                  height:
                      14,
                ),

                _buildTeachingGrid(),

                const SizedBox(
                  height:
                      30,
                ),

                const _TeacherSectionTitle(
                  title:
                      'Distribuzione',

                  subtitle:
                      'Organizza il materiale pubblicato e la sua distribuzione agli studenti.',
                ),

                const SizedBox(
                  height:
                      14,
                ),

                _buildDistributionGrid(),

                const SizedBox(
                  height:
                      30,
                ),
              ],
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
        22,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              AppColors.teacherIndigo
                  .withOpacity(
            0.25,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          Container(
            width:
                64,

            height:
                64,

            decoration:
                BoxDecoration(
              color:
                  AppColors.teacherIndigo
                      .withOpacity(
                0.14,
              ),

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              border:
                  Border.all(
                color:
                    AppColors.teacherIndigo
                        .withOpacity(
                  0.30,
                ),
              ),
            ),

            child:
                const Icon(
              Icons
                  .cast_for_education_outlined,

              color:
                  AppColors.teacherIndigo,

              size:
                  32,
            ),
          ),

          const SizedBox(
            width:
                15,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Area Docenti StudentLab',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        19,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  'Pubblica materiale, gestisci le tue materie e condividi contenuti con gli studenti.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.52,
                    ),

                    fontSize:
                        11,

                    height:
                        1.4,
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        8,

                    vertical:
                        5,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.greenAccent
                            .withOpacity(
                      0.08,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child:
                      const Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      Icon(
                        Icons
                            .verified_rounded,

                        color:
                            Colors.greenAccent,

                        size:
                            12,
                      ),

                      SizedBox(
                        width:
                            5,
                      ),

                      Text(
                        'Docente verificato dal server',

                        style:
                            TextStyle(
                          color:
                              Colors.greenAccent,

                          fontSize:
                              8,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTeachingGrid() {
    return LayoutBuilder(
      builder:
          (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final int columns =
            constraints.maxWidth >=
                    760
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount:
              columns,

          shrinkWrap:
              true,

          physics:
              const NeverScrollableScrollPhysics(),

          crossAxisSpacing:
              12,

          mainAxisSpacing:
              12,

          childAspectRatio:
              columns == 1
                  ? 2.65
                  : 1.85,

          children: [
            _TeacherModuleCard(
              icon:
                  Icons
                      .folder_copy_outlined,

              title:
                  'Materiali',

              description:
                  'Carica, organizza e gestisci il materiale didattico da condividere.',

              onTap:
                  _openMaterials,
            ),

            _TeacherModuleCard(
              icon:
                  Icons.menu_book_outlined,

              title:
                  'Materie',

              description:
                  'Visualizza le materie associate al tuo profilo docente.',

              onTap:
                  _openSubjects,
            ),
          ],
        );
      },
    );
  }


  Widget _buildDistributionGrid() {
    return LayoutBuilder(
      builder:
          (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final int columns =
            constraints.maxWidth >=
                    760
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount:
              columns,

          shrinkWrap:
              true,

          physics:
              const NeverScrollableScrollPhysics(),

          crossAxisSpacing:
              12,

          mainAxisSpacing:
              12,

          childAspectRatio:
              columns == 1
                  ? 2.65
                  : 1.85,

          children: [
            _TeacherModuleCard(
              icon:
                  Icons.groups_outlined,

              title:
                  'Studenti',

              description:
                  'Distribuisci il materiale agli studenti e ai corsi autorizzati.',

              onTap:
                  _openStudents,
            ),

            _TeacherModuleCard(
              icon:
                  Icons
                      .published_with_changes_outlined,

              title:
                  'Contenuti condivisi',

              description:
                  'Controlla il materiale pubblicato e la relativa visibilità.',

              onTap:
                  _openSharedContent,
            ),
          ],
        );
      },
    );
  }
}


class _TeacherSectionTitle
    extends StatelessWidget {
  final String title;

  final String subtitle;


  const _TeacherSectionTitle({
    required this.title,
    required this.subtitle,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

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
              4,
        ),

        Text(
          subtitle,

          style:
              TextStyle(
            color:
                AppColors.pureWhite
                    .withOpacity(
              0.45,
            ),

            fontSize:
                11,

            height:
                1.4,
          ),
        ),
      ],
    );
  }
}


class _TeacherModuleCard
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String description;

  final Future<void> Function()
      onTap;


  const _TeacherModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,

      child:
          InkWell(
        onTap:
            () {
          onTap();
        },

        borderRadius:
            BorderRadius.circular(
          17,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            17,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors.eleganceMidnight,

            borderRadius:
                BorderRadius.circular(
              17,
            ),

            border:
                Border.all(
              color:
                  AppColors.teacherIndigo
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
                        45,

                    height:
                        45,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors
                              .teacherIndigo
                              .withOpacity(
                            0.13,
                          ),

                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),

                    child:
                        Icon(
                      icon,

                      color:
                          AppColors
                              .teacherIndigo,

                      size:
                          23,
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,

                    color:
                        Colors.white30,

                    size:
                        14,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    13,
              ),

              Text(
                title,

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

              Expanded(
                child:
                    Text(
                  description,

                  style:
                      const TextStyle(
                    color:
                        Colors.white54,

                    fontSize:
                        10,

                    height:
                        1.4,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    8,
              ),

              const Text(
                'Apri',

                style:
                    TextStyle(
                  color:
                      AppColors.materialSky,

                  fontSize:
                      9,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TeacherAccessDeniedPage
    extends StatelessWidget {
  final String? error;

  final Future<void> Function()
      onRetry;


  const _TeacherAccessDeniedPage({
    required this.error,
    required this.onRetry,
  });


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

        title:
            const Text(
          'Area Docenti',
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
                  480,
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
                    0.16,
                  ),
                ),
              ),

              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Container(
                    width:
                        68,

                    height:
                        68,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.redAccent
                              .withOpacity(
                        0.08,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        19,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons
                          .gpp_bad_outlined,

                      color:
                          Colors.redAccent,

                      size:
                          35,
                    ),
                  ),

                  const SizedBox(
                    height:
                        18,
                  ),

                  const Text(
                    'Accesso docente non autorizzato',

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
                        9,
                  ),

                  const Text(
                    'Il server non riconosce questa sessione come appartenente a un docente verificato e attivo.',

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

                  if (error != null) ...[
                    const SizedBox(
                      height:
                          10,
                    ),

                    Text(
                      error!,

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
                        () {
                      onRetry();
                    },

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
            ),
          ),
        ),
      ),
    );
  }
}