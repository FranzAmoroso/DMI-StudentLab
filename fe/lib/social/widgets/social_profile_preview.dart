import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../../services/auth_service.dart';

import '../social_models.dart';


// =============================================================================
// SOCIAL PROFILE PREVIEW
// =============================================================================

class SocialProfilePreview extends StatefulWidget {
  final SocialProfileDraft draft;


  const SocialProfilePreview({
    super.key,
    required this.draft,
  });


  @override
  State<SocialProfilePreview> createState() =>
      _SocialProfilePreviewState();
}


// =============================================================================
// STATE
// =============================================================================

class _SocialProfilePreviewState
    extends State<SocialProfilePreview> {

  final AuthService _authService =
      AuthService();


  bool _publishing =
      false;


  String? _error;


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final SocialProfileDraft draft =
        widget.draft;


    final bool isTeacher =
        draft.type ==
            SocialUserType.teacher;


    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,


      // =========================================================================
      // APP BAR
      // =========================================================================

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
          'Anteprima profilo',

          style:
              TextStyle(
            fontSize:
                18,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),


      // =========================================================================
      // BODY
      // =========================================================================

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
                      ? 650
                      : constraints
                          .maxWidth;


              return SizedBox(
                width:
                    width,

                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Così apparirà il tuo profilo',

                        textAlign:
                            TextAlign.center,

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
                            8,
                      ),

                      Text(
                        'Controlla le informazioni prima di creare '
                        'il tuo account StudentLab.',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.55,
                          ),

                          fontSize:
                              13,
                        ),
                      ),

                      const SizedBox(
                        height:
                            24,
                      ),


                      // =======================================================
                      // PREVIEW CARD
                      // =======================================================

                      _ProfileCard(
                        draft:
                            draft,

                        isTeacher:
                            isTeacher,
                      ),


                      // =======================================================
                      // ERROR
                      // =======================================================

                      if (_error !=
                          null) ...[
                        const SizedBox(
                          height:
                              18,
                        ),

                        _buildError(),
                      ],


                      const SizedBox(
                        height:
                            28,
                      ),


                      // =======================================================
                      // REGISTER
                      // =======================================================

                      SizedBox(
                        height:
                            54,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _publishing
                                  ? null
                                  : _publishProfile,

                          icon:
                              _publishing
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
                                            AppColors.pureWhite,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_rounded,
                                    ),

                          label:
                              Text(
                            _publishing
                                ? 'Creazione account...'
                                : 'Conferma e registrati',

                            style:
                                const TextStyle(
                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                isTeacher
                                    ? AppColors.teacherIndigo
                                    : AppColors.socialBlue,

                            foregroundColor:
                                AppColors.pureWhite,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),


                      // =======================================================
                      // MODIFICA
                      // =======================================================

                      SizedBox(
                        height:
                            50,

                        child:
                            OutlinedButton.icon(
                          onPressed:
                              _publishing
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                      );
                                    },

                          icon:
                              const Icon(
                            Icons.edit_outlined,
                          ),

                          label:
                              const Text(
                            'Modifica profilo',
                          ),

                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                AppColors.pureWhite,

                            side:
                                BorderSide(
                              color:
                                  AppColors.pureWhite
                                      .withOpacity(
                                0.20,
                              ),
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            20,
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


  // ===========================================================================
  // PUBBLICA / REGISTRA
  // ===========================================================================

  Future<void> _publishProfile() async {
    if (_publishing) {
      return;
    }


    setState(() {
      _publishing =
          true;

      _error =
          null;
    });


    try {
      // =======================================================================
      // AuthService.register() esegue:
      //
      // 1. POST /register
      // 2. riceve JWT
      // 3. GET /me
      // 4. salva AuthSession
      // 5. prepara LocalStorageService
      // 6. associa le materie
      // 7. ricarica /me
      // 8. aggiorna currentUser
      // =======================================================================

      final SocialUser user =
          await _authService.register(
        widget.draft,
      );


      if (!mounted) {
        return;
      }


      // =======================================================================
      // RESTITUISCE L'UTENTE AUTENTICATO
      // =======================================================================

      Navigator.pop(
        context,
        user,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      setState(() {
        _error =
            _cleanErrorMessage(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _publishing =
              false;
        });
      }
    }
  }


  // ===========================================================================
  // PULIZIA ERRORE
  // ===========================================================================

  String _cleanErrorMessage(
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


  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.redAccent
                .withOpacity(
          0.08,
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
            0.20,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                20,
          ),

          const SizedBox(
            width:
                9,
          ),

          Expanded(
            child:
                Text(
              _error ??
                  'Errore durante la registrazione.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.75,
                ),

                fontSize:
                    11,

                height:
                    1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// PROFILE CARD
// =============================================================================

class _ProfileCard
    extends StatelessWidget {

  final SocialProfileDraft draft;

  final bool isTeacher;


  const _ProfileCard({
    required this.draft,
    required this.isTeacher,
  });


  @override
  Widget build(
    BuildContext context,
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
            AppColors.eleganceDeepNavy,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              isTeacher
                  ? AppColors.teacherIndigo
                      .withOpacity(
                    0.35,
                  )
                  : AppColors.socialBlue
                      .withOpacity(
                    0.35,
                  ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ===================================================================
          // USER
          // ===================================================================

          Row(
            children: [
              CircleAvatar(
                radius:
                    25,

                backgroundColor:
                    isTeacher
                        ? AppColors.teacherIndigo
                        : AppColors.studentBlue,

                child:
                    Text(
                  draft.name.isNotEmpty
                      ? draft.name[0]
                          .toUpperCase()
                      : '?',

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontWeight:
                        FontWeight.bold,

                    fontSize:
                        18,
                  ),
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
                      draft.name.isNotEmpty
                          ? draft.name
                          : 'Nome non inserito',

                      maxLines:
                          1,

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
                          2,
                    ),

                    Text(
                      isTeacher
                          ? 'Insegnante'
                          : 'Studente',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.55,
                        ),

                        fontSize:
                            12,
                      ),
                    ),

                    const SizedBox(
                      height:
                          3,
                    ),

                    Text(
                      draft.email,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.40,
                        ),

                        fontSize:
                            10,
                      ),
                    ),
                  ],
                ),
              ),

              if (draft.available)
                const _AvailableBadge(),
            ],
          ),

          const SizedBox(
            height:
                18,
          ),


          // ===================================================================
          // CAPABILITIES
          // ===================================================================

          Wrap(
            spacing:
                8,

            runSpacing:
                8,

            children: [
              if (draft.available)
                const _ProfileChip(
                  icon:
                      Icons.support_agent_rounded,

                  label:
                      'Disponibile',
                ),

              if (draft.willingToTeach)
                _ProfileChip(
                  icon:
                      Icons.school_outlined,

                  label:
                      isTeacher
                          ? 'Lezioni private'
                          : 'Disponibile ad aiutare',
                ),
            ],
          ),


          // ===================================================================
          // SUBJECTS
          // ===================================================================

          if (draft.subjects.isNotEmpty) ...[
            const SizedBox(
              height:
                  18,
            ),

            const Text(
              'Materie',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  9,
            ),

            ...draft.subjects.map(
              (
                SocialSubject subject,
              ) =>
                  _SubjectPreview(
                subject:
                    subject,

                isTeacher:
                    isTeacher,
              ),
            ),
          ] else
            Padding(
              padding:
                  const EdgeInsets.only(
                top:
                    14,
              ),

              child:
                  Text(
                'Nessuna materia inserita.',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.45,
                  ),

                  fontSize:
                      13,
                ),
              ),
            ),


          // ===================================================================
          // DESCRIPTION
          // ===================================================================

          if (draft.description.isNotEmpty) ...[
            const SizedBox(
              height:
                  12,
            ),

            Text(
              draft.description,

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.70,
                ),

                fontSize:
                    14,

                height:
                    1.4,
              ),
            ),
          ],


          const SizedBox(
            height:
                12,
          ),


          // ===================================================================
          // DEPARTMENT / COURSE
          // ===================================================================

          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    15,
              ),

              const SizedBox(
                width:
                    6,
              ),

              Expanded(
                child:
                    Text(
                  '${draft.department} • ${draft.course}',

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.45,
                    ),

                    fontSize:
                        12,
                  ),
                ),
              ),
            ],
          ),


          // ===================================================================
          // REVIEWS
          // ===================================================================

          const SizedBox(
            height:
                14,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.brandNightBlue,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Row(
              children: [
                Icon(
                  Icons.star_rounded,

                  color:
                      Colors.amber,

                  size:
                      20,
                ),

                SizedBox(
                  width:
                      6,
                ),

                Text(
                  'Nessuna recensione',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// AVAILABLE BADGE
// =============================================================================

class _AvailableBadge
    extends StatelessWidget {

  const _AvailableBadge();


  @override
  Widget build(
    BuildContext context,
  ) {
    return const Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Icon(
          Icons.circle,

          color:
              Colors.green,

          size:
              9,
        ),

        SizedBox(
          width:
              5,
        ),

        Text(
          'Disponibile',

          style:
              TextStyle(
            color:
                Colors.green,

            fontSize:
                11,
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// PROFILE CHIP
// =============================================================================

class _ProfileChip
    extends StatelessWidget {

  final IconData icon;

  final String label;


  const _ProfileChip({
    required this.icon,
    required this.label,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            9,

        vertical:
            6,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.skyBlue
                .withOpacity(
          0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          9,
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
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            color:
                AppColors.materialSky,

            size:
                15,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.materialSky,

              fontSize:
                  10,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// SUBJECT PREVIEW
// =============================================================================

class _SubjectPreview
    extends StatelessWidget {

  final SocialSubject subject;

  final bool isTeacher;


  const _SubjectPreview({
    required this.subject,
    required this.isTeacher,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            8,
      ),

      padding:
          const EdgeInsets.all(
        11,
      ),

      decoration:
          BoxDecoration(
        color:
            isTeacher
                ? AppColors.teacherIndigo
                    .withOpacity(
                  0.08,
                )
                : AppColors.socialBlue
                    .withOpacity(
                  0.08,
                ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              isTeacher
                  ? AppColors.teacherIndigo
                      .withOpacity(
                    0.18,
                  )
                  : AppColors.socialBlue
                      .withOpacity(
                    0.18,
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
              const Icon(
                Icons.menu_book_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    17,
              ),

              const SizedBox(
                width:
                    7,
              ),

              Expanded(
                child:
                    Text(
                  subject.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.skyBlue,

                    fontSize:
                        13,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),


              // ===============================================================
              // CAN HELP
              // ===============================================================

              if (subject.canHelp)
                Container(
                  margin:
                      const EdgeInsets.only(
                    right:
                        6,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        7,

                    vertical:
                        4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.skyBlue
                            .withOpacity(
                      0.10,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child:
                      const Text(
                    'AIUTO',

                    style:
                        TextStyle(
                      color:
                          AppColors.materialSky,

                      fontSize:
                          8,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),


              // ===============================================================
              // VOTO STUDENTE
              // ===============================================================

              if (subject.grade !=
                  null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        8,

                    vertical:
                        4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green
                            .withOpacity(
                      0.12,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child:
                      Text(
                    '${subject.grade}/30',

                    style:
                        const TextStyle(
                      color:
                          Colors.green,

                      fontSize:
                          11,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),


          if (subject.note.isNotEmpty) ...[
            const SizedBox(
              height:
                  5,
            ),

            Text(
              subject.note,

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.55,
                ),

                fontSize:
                    12,

                height:
                    1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}