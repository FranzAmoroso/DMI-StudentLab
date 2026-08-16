import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../social_models.dart';


// =============================================================================
// TIPO RICHIESTA
// =============================================================================

enum ContactRequestType {
  general,
  help,
  privateLesson,
}


// =============================================================================
// CONTACT USER PAGE
// =============================================================================

class ContactUserPage extends StatefulWidget {
  final SocialUser user;

  const ContactUserPage({
    super.key,
    required this.user,
  });

  @override
  State<ContactUserPage> createState() =>
      _ContactUserPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _ContactUserPageState
    extends State<ContactUserPage> {

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();


  final TextEditingController
      _subjectController =
      TextEditingController();

  final TextEditingController
      _messageController =
      TextEditingController();


  ContactRequestType _requestType =
      ContactRequestType.general;


  int? _selectedSubjectId;


  bool _sending =
      false;


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _subjectController.dispose();

    _messageController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // MATERIE DISPONIBILI
  // ===========================================================================

  List<SocialSubject> get _availableSubjects {
    switch (_requestType) {
      case ContactRequestType.help:
        /*
         * Per una richiesta di aiuto mostriamo
         * soltanto le materie sulle quali l'utente
         * ha dichiarato canHelp = true.
         */
        return widget.user.subjects
            .where(
              (subject) =>
                  subject.canHelp,
            )
            .toList();

      case ContactRequestType.privateLesson:
        /*
         * Per le lezioni private possiamo mostrare
         * tutte le materie associate al profilo.
         */
        return widget.user.subjects;

      case ContactRequestType.general:
        return const [];
    }
  }


  bool get _requiresSubject {
    return _requestType ==
            ContactRequestType.help ||
        _requestType ==
            ContactRequestType.privateLesson;
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

      appBar: AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        elevation:
            0,

        title: const Text(
          'Contatta utente',

          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final double width =
                  constraints.maxWidth > 700
                      ? 650
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: Form(
                  key: _formKey,

                  child: ListView(
                    padding:
                        const EdgeInsets.all(20),

                    children: [
                      _buildUserHeader(),

                      const SizedBox(
                        height: 24,
                      ),

                      _buildSectionTitle(
                        'Tipo di richiesta',
                        'Scegli il motivo del contatto.',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _buildRequestTypeCard(),

                      if (_requiresSubject) ...[
                        const SizedBox(
                          height: 24,
                        ),

                        _buildSectionTitle(
                          'Materia',
                          _requestType ==
                                  ContactRequestType.help
                              ? 'Seleziona la materia per cui vuoi chiedere aiuto.'
                              : 'Seleziona la materia per la lezione privata.',
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildSubjectSelector(),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      _buildSectionTitle(
                        'Messaggio',
                        'Scrivi l\'oggetto e il contenuto del messaggio.',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _buildMessageCard(),

                      const SizedBox(
                        height: 24,
                      ),

                      _buildSummary(),

                      const SizedBox(
                        height: 22,
                      ),

                      _buildSendButton(),

                      const SizedBox(
                        height: 20,
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
  // HEADER UTENTE
  // ===========================================================================

  Widget _buildUserHeader() {
    final bool isTeacher =
        widget.user.type ==
            SocialUserType.teacher;


    final Color roleColor =
        isTeacher
            ? AppColors.teacherIndigo
            : AppColors.studentBlue;


    final String role =
        isTeacher
            ? 'Insegnante'
            : 'Studente';


    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              roleColor.withOpacity(0.25),
        ),
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 27,

            backgroundColor:
                roleColor,

            child: Text(
              widget.user.name.isNotEmpty
                  ? widget.user.name[0]
                      .toUpperCase()
                  : '?',

              style: const TextStyle(
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
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  widget.user.name,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        17,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  role,

                  style: TextStyle(
                    color:
                        roleColor,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  widget.user.email,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(0.45),

                    fontSize:
                        11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: const TextStyle(
            color:
                AppColors.pureWhite,

            fontSize:
                17,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          subtitle,

          style: TextStyle(
            color:
                AppColors.pureWhite
                    .withOpacity(0.48),

            fontSize:
                12,
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // TIPO RICHIESTA
  // ===========================================================================

  Widget _buildRequestTypeCard() {
    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(0.12),
        ),
      ),

      child: Column(
        children: [
          _RequestTypeTile(
            icon:
                Icons.mail_outline_rounded,

            title:
                'Messaggio generico',

            description:
                'Invia un messaggio senza richiedere assistenza specifica.',

            selected:
                _requestType ==
                    ContactRequestType.general,

            onTap: () {
              _changeRequestType(
                ContactRequestType.general,
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _RequestTypeTile(
            icon:
                Icons.support_agent_rounded,

            title:
                'Richiesta di aiuto',

            description:
                'Chiedi supporto su una materia specifica.',

            selected:
                _requestType ==
                    ContactRequestType.help,

            onTap: () {
              _changeRequestType(
                ContactRequestType.help,
              );
            },
          ),

          if (widget.user.willingToTeach) ...[
            const SizedBox(
              height: 8,
            ),

            _RequestTypeTile(
              icon:
                  Icons.school_outlined,

              title:
                  'Lezione privata',

              description:
                  'Richiedi una lezione privata su una materia.',

              selected:
                  _requestType ==
                      ContactRequestType.privateLesson,

              onTap: () {
                _changeRequestType(
                  ContactRequestType.privateLesson,
                );
              },
            ),
          ],
        ],
      ),
    );
  }


  void _changeRequestType(
    ContactRequestType type,
  ) {
    setState(() {
      _requestType =
          type;

      _selectedSubjectId =
          null;
    });
  }


  // ===========================================================================
  // MATERIA
  // ===========================================================================

  Widget _buildSubjectSelector() {
    final List<SocialSubject> subjects =
        _availableSubjects;


    if (subjects.isEmpty) {
      return Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color:
              AppColors.eleganceMidnight,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color:
                Colors.orangeAccent
                    .withOpacity(0.20),
          ),
        ),

        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,

              color:
                  Colors.orangeAccent,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                _requestType ==
                        ContactRequestType.help
                    ? 'L\'utente non ha indicato materie per cui offre aiuto.'
                    : 'L\'utente non ha materie disponibili per lezioni private.',

                style: TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(0.65),

                  fontSize:
                      12,
                ),
              ),
            ),
          ],
        ),
      );
    }


    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: DropdownButtonFormField<int>(
        value:
            _selectedSubjectId,

        dropdownColor:
            AppColors.eleganceDeepNavy,

        isExpanded:
            true,

        validator:
            (value) {
          if (_requiresSubject &&
              value == null) {
            return 'Seleziona una materia';
          }

          return null;
        },

        decoration: InputDecoration(
          prefixIcon:
              const Icon(
            Icons.menu_book_outlined,

            color:
                AppColors.skyBlue,
          ),

          hintText:
              'Seleziona materia',

          hintStyle:
              const TextStyle(
            color:
                Colors.white38,
          ),

          filled:
              true,

          fillColor:
              AppColors.brandNightBlue,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                BorderSide.none,
          ),
        ),

        items: subjects.map(
          (subject) {
            return DropdownMenuItem<int>(
              value:
                  subject.id,

              child: Text(
                subject.name,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  color:
                      AppColors.pureWhite,
                ),
              ),
            );
          },
        ).toList(),

        onChanged:
            (value) {
          setState(() {
            _selectedSubjectId =
                value;
          });
        },
      ),
    );
  }


  // ===========================================================================
  // MESSAGGIO
  // ===========================================================================

  Widget _buildMessageCard() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(0.12),
        ),
      ),

      child: Column(
        children: [
          TextFormField(
            controller:
                _subjectController,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            validator:
                (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Inserisci l\'oggetto';
              }

              return null;
            },

            decoration:
                _inputDecoration(
              label:
                  'Oggetto',

              hint:
                  'Es. Aiuto con gli esercizi',
              
              icon:
                  Icons.subject_rounded,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          TextFormField(
            controller:
                _messageController,

            maxLines:
                7,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),

            validator:
                (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Inserisci un messaggio';
              }

              return null;
            },

            decoration:
                _inputDecoration(
              label:
                  'Messaggio',

              hint:
                  'Scrivi il tuo messaggio...',

              icon:
                  Icons.chat_bubble_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }


  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      labelStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(0.55),
      ),

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(0.30),
      ),

      prefixIcon:
          Icon(
        icon,

        color:
            AppColors.skyBlue,
      ),

      filled:
          true,

      fillColor:
          AppColors.darkElegance,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),

        borderSide:
            BorderSide.none,
      ),
    );
  }


  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Widget _buildSummary() {
    final SocialSubject? selectedSubject =
        _selectedSubject;


    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Riepilogo',

            style: TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  14,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _SummaryRow(
            label:
                'Destinatario',

            value:
                widget.user.email,
          ),

          const SizedBox(
            height: 8,
          ),

          _SummaryRow(
            label:
                'Richiesta',

            value:
                _requestTypeLabel,
          ),

          if (_requiresSubject) ...[
            const SizedBox(
              height: 8,
            ),

            _SummaryRow(
              label:
                  'Materia',

              value:
                  selectedSubject
                          ?.name ??
                      'Non selezionata',
            ),
          ],
        ],
      ),
    );
  }


  SocialSubject? get _selectedSubject {
    if (_selectedSubjectId ==
        null) {
      return null;
    }


    for (final SocialSubject subject
        in widget.user.subjects) {
      if (subject.id ==
          _selectedSubjectId) {
        return subject;
      }
    }


    return null;
  }


  String get _requestTypeLabel {
    switch (_requestType) {
      case ContactRequestType.general:
        return 'Messaggio generico';

      case ContactRequestType.help:
        return 'Richiesta di aiuto';

      case ContactRequestType.privateLesson:
        return 'Lezione privata';
    }
  }


  // ===========================================================================
  // SEND BUTTON
  // ===========================================================================

  Widget _buildSendButton() {
    return SizedBox(
      width:
          double.infinity,

      height:
          52,

      child: ElevatedButton.icon(
        onPressed:
            _sending
                ? null
                : _send,

        icon:
            _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,

                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                  ),

        label: Text(
          _sending
              ? 'Invio...'
              : 'Invia richiesta',
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.skyBlue,

          foregroundColor:
              AppColors.brandNightBlue,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // INVIO
  // ===========================================================================

  Future<void> _send() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }


    if (_requestType ==
            ContactRequestType.privateLesson &&
        !widget.user.willingToTeach) {
      _showMessage(
        'Questo utente non accetta richieste di lezioni private.',
      );

      return;
    }


    if (_requiresSubject &&
        _selectedSubjectId == null) {
      _showMessage(
        'Seleziona una materia.',
      );

      return;
    }


    setState(() {
      _sending =
          true;
    });


    try {
      /*
       * AL MOMENTO:
       *
       * Non abbiamo ancora un endpoint backend
       * per inviare email.
       *
       * I dati sono però già pronti:
       *
       * destinatario:
       * widget.user.email
       *
       * tipo:
       * _requestType
       *
       * materia:
       * _selectedSubject
       *
       * oggetto:
       * _subjectController.text
       *
       * messaggio:
       * _messageController.text
       *
       *
       * In seguito potremo creare:
       *
       * POST /contact_user
       *
       * oppure
       *
       * POST /messages
       */

      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );


      if (!mounted) {
        return;
      }


      _showMessage(
        'Richiesta preparata correttamente.',
      );


      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _sending =
              false;
        });
      }
    }
  }


  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }
}


// =============================================================================
// REQUEST TYPE TILE
// =============================================================================

class _RequestTypeTile
    extends StatelessWidget {

  final IconData icon;

  final String title;

  final String description;

  final bool selected;

  final VoidCallback onTap;


  const _RequestTypeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        padding:
            const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.brandNightBlue
                  : Colors.transparent,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                selected
                    ? AppColors.skyBlue
                        .withOpacity(0.30)
                    : Colors.white
                        .withOpacity(0.05),
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,

              color:
                  selected
                      ? AppColors.skyBlue
                      : Colors.white54,

              size:
                  22,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      color:
                          AppColors.pureWhite,

                      fontSize:
                          13,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    description,

                    style: TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(0.45),

                      fontSize:
                          10,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,

              color:
                  selected
                      ? AppColors.skyBlue
                      : Colors.white30,
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// SUMMARY ROW
// =============================================================================

class _SummaryRow
    extends StatelessWidget {

  final String label;

  final String value;


  const _SummaryRow({
    required this.label,
    required this.value,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        SizedBox(
          width: 90,

          child: Text(
            label,

            style: TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(0.45),

              fontSize: 11,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,

            textAlign:
                TextAlign.right,

            style: const TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize: 11,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}