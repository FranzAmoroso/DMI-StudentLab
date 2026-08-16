import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/auth_session.dart';

import '../social_models.dart';

import '../message/message_page.dart';


// =============================================================================
// SOCIAL USER PROFILE PAGE
// =============================================================================

class SocialUserProfilePage extends StatefulWidget {
  final SocialUser user;


  const SocialUserProfilePage({
    super.key,
    required this.user,
  });


  @override
  State<SocialUserProfilePage> createState() =>
      _SocialUserProfilePageState();
}


// =============================================================================
// STATE
// =============================================================================

class _SocialUserProfilePageState
    extends State<SocialUserProfilePage> {

  final AuthSession _session =
      AuthSession.instance;


  // ===========================================================================
  // GETTERS
  // ===========================================================================

  SocialUser get _user {
    return widget.user;
  }


  bool get _isAuthenticated {
    return _session.isAuthenticated;
  }


  bool get _isOwnProfile {
    return _session.currentUserId ==
        _user.id;
  }


  bool get _isTeacher {
    return _user.type ==
        SocialUserType.teacher;
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


      // =========================================================================
      // APP BAR
      // =========================================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.brandNightBlue,

        foregroundColor:
            AppColors.pureWhite,

        elevation:
            0,

        title: Text(
          _user.name,

          maxLines:
              1,

          overflow:
              TextOverflow.ellipsis,
        ),
      ),


      // =========================================================================
      // BODY
      // =========================================================================

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  800,
            ),

            child: ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              children: [
                // =============================================================
                // PROFILE HEADER
                // =============================================================

                _buildProfileHeader(),

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // ACTIONS
                // =============================================================

                if (!_isOwnProfile)
                  _buildActions(),

                if (!_isOwnProfile)
                  const SizedBox(
                    height:
                        18,
                  ),


                // =============================================================
                // ABOUT
                // =============================================================

                _buildAbout(),

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // SUBJECTS
                // =============================================================

                _buildSubjects(),

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // AVAILABILITY
                // =============================================================

                _buildAvailability(),

                const SizedBox(
                  height:
                      16,
                ),


                // =============================================================
                // REVIEWS
                // =============================================================

                _buildReviews(),

                const SizedBox(
                  height:
                      24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // PROFILE HEADER
  // ===========================================================================

  Widget _buildProfileHeader() {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.eleganceMidnight,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        border:
            Border.all(
          color:
              (_isTeacher
                      ? AppColors.teacherIndigo
                      : AppColors.socialBlue)
                  .withOpacity(
            0.25,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ===============================================================
              // AVATAR
              // ===============================================================

              Container(
                width:
                    72,

                height:
                    72,

                alignment:
                    Alignment.center,

                decoration:
                    BoxDecoration(
                  color:
                      _isTeacher
                          ? AppColors.teacherIndigo
                          : AppColors.studentBlue,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),

                child: Text(
                  _user.name.isNotEmpty
                      ? _user.name[0]
                          .toUpperCase()
                      : '?',

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        27,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    15,
              ),


              // ===============================================================
              // USER
              // ===============================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      _user.name,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            21,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Row(
                      children: [
                        Icon(
                          _isTeacher
                              ? Icons
                                  .cast_for_education_outlined
                              : Icons
                                  .school_outlined,

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
                          _isTeacher
                              ? 'Insegnante'
                              : 'Studente',

                          style:
                              const TextStyle(
                            color:
                                AppColors.materialSky,

                            fontSize:
                                11,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          6,
                    ),

                    Text(
                      _user.email,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.42,
                        ),

                        fontSize:
                            10,
                      ),
                    ),
                  ],
                ),
              ),


              // ===============================================================
              // AVAILABILITY
              // ===============================================================

              _AvailabilityBadge(
                available:
                    _user.available,
              ),
            ],
          ),

          const SizedBox(
            height:
                20,
          ),

          Divider(
            height:
                1,

            color:
                AppColors.pureWhite
                    .withOpacity(
              0.07,
            ),
          ),

          const SizedBox(
            height:
                16,
          ),


          // ===============================================================
          // UNIVERSITY DATA
          // ===============================================================

          _InfoRow(
            icon:
                Icons.account_balance_outlined,

            label:
                'Dipartimento',

            value:
                _user.department.isEmpty
                    ? 'Non specificato'
                    : _user.department,
          ),

          const SizedBox(
            height:
                12,
          ),

          _InfoRow(
            icon:
                Icons.school_outlined,

            label:
                'Corso',

            value:
                _user.course.isEmpty
                    ? 'Non specificato'
                    : _user.course,
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Widget _buildActions() {
    return Row(
      children: [
        // =====================================================================
        // CONTACT
        // =====================================================================

        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _openMessages,

            icon:
                const Icon(
              Icons.chat_bubble_outline_rounded,
            ),

            label:
                const Text(
              'Contatta',
            ),

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.socialBlue,

              foregroundColor:
                  AppColors.pureWhite,

              padding:
                  const EdgeInsets.symmetric(
                vertical:
                    13,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width:
              10,
        ),


        // =====================================================================
        // CONNECT
        // =====================================================================

        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                _requestConnection,

            icon:
                const Icon(
              Icons.person_add_alt_1_rounded,
            ),

            label:
                const Text(
              'Collegati',
            ),

            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.materialSky,

              side:
                  BorderSide(
                color:
                    AppColors.skyBlue
                        .withOpacity(
                  0.28,
                ),
              ),

              padding:
                  const EdgeInsets.symmetric(
                vertical:
                    13,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // ABOUT
  // ===========================================================================

  Widget _buildAbout() {
    return _SectionCard(
      title:
          'Profilo',

      icon:
          Icons.person_outline_rounded,

      child: Text(
        _user.description.isEmpty
            ? 'Questo utente non ha ancora aggiunto una descrizione.'
            : _user.description,

        style:
            TextStyle(
          color:
              AppColors.pureWhite
                  .withOpacity(
            0.58,
          ),

          fontSize:
              12,

          height:
              1.5,
        ),
      ),
    );
  }


  // ===========================================================================
  // SUBJECTS
  // ===========================================================================

  Widget _buildSubjects() {
    return _SectionCard(
      title:
          'Materie',

      icon:
          Icons.menu_book_outlined,

      child:
          _user.subjects.isEmpty
              ? Text(
                  'Nessuna materia aggiunta.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.40,
                    ),

                    fontSize:
                        11,
                  ),
                )
              : Column(
                  children:
                      _user.subjects
                          .map(
                            _buildSubject,
                          )
                          .toList(),
                ),
    );
  }


  // ===========================================================================
  // SUBJECT
  // ===========================================================================

  Widget _buildSubject(
    SocialSubject subject,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            9,
      ),

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

      child: Column(
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
                    16,
              ),

              const SizedBox(
                width:
                    7,
              ),

              Expanded(
                child: Text(
                  subject.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),


              // ===============================================================
              // GRADE
              // ===============================================================

              if (subject.grade !=
                  null)
                _SmallBadge(
                  label:
                      '${subject.grade}/30',

                  icon:
                      Icons.workspace_premium_outlined,
                ),


              // ===============================================================
              // HELP
              // ===============================================================

              if (subject.canHelp) ...[
                if (subject.grade !=
                    null)
                  const SizedBox(
                    width:
                        5,
                  ),

                const _SmallBadge(
                  label:
                      'Può aiutare',

                  icon:
                      Icons.volunteer_activism_outlined,
                ),
              ],
            ],
          ),

          if (subject.note.isNotEmpty) ...[
            const SizedBox(
              height:
                  8,
            ),

            Text(
              subject.note,

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.46,
                ),

                fontSize:
                    10,

                height:
                    1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ===========================================================================
  // AVAILABILITY
  // ===========================================================================

  Widget _buildAvailability() {
    return _SectionCard(
      title:
          'Disponibilità',

      icon:
          Icons.schedule_outlined,

      child: Column(
        children: [
          _AvailabilityRow(
            icon:
                Icons.circle,

            title:
                'Disponibilità generale',

            value:
                _user.available
                    ? 'Disponibile'
                    : 'Non disponibile',

            active:
                _user.available,
          ),

          if (_user.willingToTeach) ...[
            const SizedBox(
              height:
                  12,
            ),

            _AvailabilityRow(
              icon:
                  Icons.cast_for_education_outlined,

              title:
                  _isTeacher
                      ? 'Lezioni'
                      : 'Supporto allo studio',

              value:
                  _isTeacher
                      ? 'Disponibile per lezioni'
                      : 'Disponibile ad aiutare',

              active:
                  true,
            ),
          ],
        ],
      ),
    );
  }


  // ===========================================================================
  // REVIEWS
  // ===========================================================================

  Widget _buildReviews() {
    return _SectionCard(
      title:
          'Recensioni',

      icon:
          Icons.star_outline_rounded,

      trailing:
          _user.reviews.isEmpty
              ? null
              : Text(
                  '${_user.averageRating.toStringAsFixed(1)} / 5',

                  style:
                      const TextStyle(
                    color:
                        Colors.amber,

                    fontSize:
                        11,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

      child:
          _user.reviews.isEmpty
              ? _buildNoReviews()
              : Column(
                  children:
                      _user.reviews
                          .map(
                            _buildReview,
                          )
                          .toList(),
                ),
    );
  }


  // ===========================================================================
  // NO REVIEWS
  // ===========================================================================

  Widget _buildNoReviews() {
    return Row(
      children: [
        const Icon(
          Icons.star_outline_rounded,

          color:
              Colors.white30,

          size:
              25,
        ),

        const SizedBox(
          width:
              10,
        ),

        Expanded(
          child: Text(
            'Questo utente non ha ancora ricevuto recensioni.',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(
                0.42,
              ),

              fontSize:
                  11,
            ),
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // REVIEW
  // ===========================================================================

  Widget _buildReview(
    SocialReview review,
  ) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom:
            9,
      ),

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

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        11,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.star_rounded,

                color:
                    Colors.amber,

                size:
                    14,
              ),

              const SizedBox(
                width:
                    3,
              ),

              Text(
                review.rating
                    .toStringAsFixed(
                  1,
                ),

                style:
                    const TextStyle(
                  color:
                      Colors.amber,

                  fontSize:
                      10,
                ),
              ),
            ],
          ),

          if (review.comment
              .isNotEmpty) ...[
            const SizedBox(
              height:
                  7,
            ),

            Text(
              review.comment,

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
          ],
        ],
      ),
    );
  }


  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  Future<void> _openMessages() async {
    if (!_isAuthenticated) {
      _showAuthenticationRequired();

      return;
    }


    // =========================================================================
    // PER ORA
    // =========================================================================
    //
    // MessagesPage esiste già, ma nella versione attuale non riceve ancora
    // l'utente destinatario nel costruttore.
    //
    // Il prossimo aggiornamento della chat permetterà:
    //
    // MessagesPage(
    //   targetUser: _user,
    // )
    //
    // così il pulsante Contatta aprirà direttamente la conversazione.
    // =========================================================================

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                const MessagesPage(),
      ),
    );
  }


  // ===========================================================================
  // CONNECTION
  // ===========================================================================

  Future<void> _requestConnection() async {
    if (!_isAuthenticated) {
      _showAuthenticationRequired();

      return;
    }


    // =========================================================================
    // BACKEND CONNECTIONS
    // =========================================================================
    //
    // Questa azione verrà collegata al prossimo modulo:
    //
    // POST /connections/request/{user_id}
    //
    // Stati previsti:
    //
    // none
    // pending
    // connected
    //
    // Per ora NON modifichiamo localmente lo stato,
    // perché una connessione deve esistere realmente nel database.
    // =========================================================================

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Il sistema di collegamenti verrà attivato con il modulo connessioni.',
        ),
      ),
    );
  }


  // ===========================================================================
  // AUTH REQUIRED
  // ===========================================================================

  void _showAuthenticationRequired() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Accedi a StudentLab per utilizzare questa funzione.',
        ),
      ),
    );
  }
}


// =============================================================================
// SECTION CARD
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;

  final IconData icon;

  final Widget child;

  final Widget? trailing;


  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,

    this.trailing,
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
        17,
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

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,

                color:
                    AppColors.skyBlue,

                size:
                    19,
              ),

              const SizedBox(
                width:
                    8,
              ),

              Expanded(
                child: Text(
                  title,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        14,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              if (trailing !=
                  null)
                trailing!,
            ],
          ),

          const SizedBox(
            height:
                14,
          ),

          child,
        ],
      ),
    );
  }
}


// =============================================================================
// INFO ROW
// =============================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;

  final String label;

  final String value;


  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,

          color:
              AppColors.materialSky,

          size:
              18,
        ),

        const SizedBox(
          width:
              9,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style:
                    const TextStyle(
                  color:
                      Colors.white38,

                  fontSize:
                      9,
                ),
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(
                value,

                style:
                    const TextStyle(
                  color:
                      Colors.white70,

                  fontSize:
                      11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// AVAILABILITY BADGE
// =============================================================================

class _AvailabilityBadge
    extends StatelessWidget {

  final bool available;


  const _AvailabilityBadge({
    required this.available,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            7,

        vertical:
            5,
      ),

      decoration:
          BoxDecoration(
        color:
            available
                ? Colors.green
                    .withOpacity(
                    0.10,
                  )
                : AppColors
                    .brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          9,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            Icons.circle,

            color:
                available
                    ? Colors.greenAccent
                    : Colors.white30,

            size:
                7,
          ),

          const SizedBox(
            width:
                4,
          ),

          Text(
            available
                ? 'Disponibile'
                : 'Offline',

            style:
                TextStyle(
              color:
                  available
                      ? Colors.greenAccent
                      : Colors.white38,

              fontSize:
                  8,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// AVAILABILITY ROW
// =============================================================================

class _AvailabilityRow
    extends StatelessWidget {

  final IconData icon;

  final String title;

  final String value;

  final bool active;


  const _AvailabilityRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.active,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,

          color:
              active
                  ? Colors.greenAccent
                  : Colors.white30,

          size:
              15,
        ),

        const SizedBox(
          width:
              9,
        ),

        Expanded(
          child: Column(
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
                      11,

                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(
                value,

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.42,
                  ),

                  fontSize:
                      9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// SMALL BADGE
// =============================================================================

class _SmallBadge extends StatelessWidget {
  final String label;

  final IconData icon;


  const _SmallBadge({
    required this.label,
    required this.icon,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            color:
                AppColors.materialSky,

            size:
                11,
          ),

          const SizedBox(
            width:
                4,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppColors.materialSky,

              fontSize:
                  8,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}