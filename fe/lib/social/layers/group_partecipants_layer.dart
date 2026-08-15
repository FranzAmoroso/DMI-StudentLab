import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../social_models.dart';

class GroupParticipantsLayer extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String subjectId;
  final List<SocialUser> users;

  const GroupParticipantsLayer({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.subjectId,
    required this.users,
  });

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      // =======================================================================
      // APP BAR
      // =======================================================================

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,

        foregroundColor: AppColors.pureWhite,

        elevation: 0,

        title: const Text(
          'Partecipanti',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // =======================================================================
      // BODY
      // =======================================================================

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width =
                  constraints.maxWidth > 900
                      ? 900
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: users.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(context),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTENUTO
  // ===========================================================================

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),

      children: [
        // =====================================================================
        // SCHEDA GRUPPO / MATERIA
        // =====================================================================

        _buildGroupCard(),

        const SizedBox(
          height: 24,
        ),

        // =====================================================================
        // HEADER PARTECIPANTI
        // =====================================================================

        Row(
          children: [
            const Expanded(
              child: Text(
                'Partecipanti',

                style: TextStyle(
                  color: AppColors.pureWhite,

                  fontSize: 20,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),

              decoration: BoxDecoration(
                color: AppColors.brandNightBlue,

                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Text(
                '${users.length}',

                style: const TextStyle(
                  color:
                      AppColors.materialSky,

                  fontSize: 12,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          'Studenti e membri del gruppo di studio.',

          style: TextStyle(
            color:
                AppColors.pureWhite
                    .withOpacity(0.55),

            fontSize: 13,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        // =====================================================================
        // GRIGLIA PARTECIPANTI
        // =====================================================================

        _buildParticipantsGrid(
          context,
        ),
      ],
    );
  }

  // ===========================================================================
  // SCHEDA GRUPPO
  // ===========================================================================

  Widget _buildGroupCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            AppColors.eleganceDeepNavy,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(0.15),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.12),

            blurRadius: 8,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ===================================================================
          // HEADER
          // ===================================================================

          Row(
            children: [
              Container(
                width: 56,
                height: 56,

                decoration: BoxDecoration(
                  color:
                      AppColors.brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.menu_book_rounded,

                  color:
                      AppColors.skyBlue,

                  size: 30,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      groupName,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize: 20,

                        fontWeight:
                            FontWeight.bold,

                        height: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      _subjectName,

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        color:
                            AppColors.materialSky
                                .withOpacity(0.9),

                        fontSize: 13,

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
            height: 18,
          ),

          // ===================================================================
          // INFORMAZIONI
          // ===================================================================

          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,

                color:
                    AppColors.materialSky,

                size: 17,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                '${users.length} partecipanti',

                style: TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(0.60),

                  fontSize: 12,

                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.groups_outlined,

                color:
                    AppColors.materialSky,

                size: 17,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                'Gruppo di studio',

                style: TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(0.60),

                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NOME MATERIA
  // ===========================================================================

  String get _subjectName {
    switch (subjectId) {
      case 'programmazione1':
      case 'programmazione_1':
        return 'Programmazione 1';

      case 'algebra':
      case 'algebra_lineare':
        return 'Algebra Lineare';

      case 'architettura':
      case 'architettura_elaboratori':
        return 'Architettura degli Elaboratori';

      case 'multimedia':
      case 'interazione_multimedia':
        return 'Interazione e Multimedia';

      default:
        return groupName;
    }
  }

  // ===========================================================================
  // GRIGLIA PARTECIPANTI
  // ===========================================================================

  Widget _buildParticipantsGrid(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool singleColumn =
            constraints.maxWidth < 560;

        return GridView.builder(
          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              users.length,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                singleColumn ? 1 : 2,

            crossAxisSpacing: 14,

            mainAxisSpacing: 14,

            // ===============================================================
            // IMPORTANTE:
            // usiamo un'altezza fissa sufficiente per evitare
            // RenderFlex overflow.
            // ===============================================================

            mainAxisExtent:
                singleColumn ? 116 : 140,
          ),

          itemBuilder: (
            context,
            index,
          ) {
            final SocialUser user =
                users[index];

            return _ParticipantCard(
              user: user,

              onTap: () {
                _openUser(
                  context,
                  user,
                );
              },
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // APERTURA PROFILO
  // ===========================================================================

  void _openUser(
    BuildContext context,
    SocialUser user,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Apertura profilo di ${user.name}: da implementare.',
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration:
                  BoxDecoration(
                color:
                    AppColors.brandNightBlue,

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.people_outline_rounded,

                color:
                    AppColors.skyBlue,

                size: 38,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Nessun partecipante',

              style: TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize: 20,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Non ci sono ancora partecipanti da mostrare.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(0.55),

                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CARD PARTECIPANTE
// =============================================================================

class _ParticipantCard
    extends StatelessWidget {
  final SocialUser user;

  final VoidCallback onTap;

  const _ParticipantCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(16),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(14),

        decoration:
            BoxDecoration(
          color:
              AppColors.eleganceMidnight,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color:
                AppColors.skyBlue
                    .withOpacity(0.12),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withOpacity(0.10),

              blurRadius: 6,

              offset:
                  const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            // =================================================================
            // AVATAR
            // =================================================================

            Container(
              width: 48,
              height: 48,

              decoration:
                  const BoxDecoration(
                color:
                    AppColors.brandNightBlue,

                shape:
                    BoxShape.circle,
              ),

              child: Center(
                child: Text(
                  _initials(
                    user.name,
                  ),

                  style:
                      const TextStyle(
                    color:
                        AppColors.skyBlue,

                    fontSize: 15,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // =================================================================
            // INFORMAZIONI
            // =================================================================

            Expanded(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // =============================================================
                  // NOME
                  // =============================================================

                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            color:
                                AppColors.pureWhite,

                            fontSize: 14,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      if (user.available) ...[
                        const SizedBox(
                          width: 7,
                        ),

                        Container(
                          width: 7,
                          height: 7,

                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.greenAccent,

                            shape:
                                BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // =============================================================
                  // CORSO
                  // =============================================================

                  Text(
                    user.course,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(0.50),

                      fontSize: 11,
                    ),
                  ),

                  // =============================================================
                  // MATERIE
                  // =============================================================

                  if (user.subjects.isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      user.subjects
                          .map(
                            (subject) =>
                                subject.name,
                          )
                          .join(' • '),

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        color:
                            AppColors.materialSky
                                .withOpacity(0.85),

                        fontSize: 10,

                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // =================================================================
            // FRECCIA
            // =================================================================

            const Icon(
              Icons.chevron_right_rounded,

              color:
                  Colors.white38,

              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INIZIALI
  // ===========================================================================

  String _initials(
    String name,
  ) {
    final String trimmed =
        name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    final List<String> parts =
        trimmed.split(
      RegExp(r'\s+'),
    );

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return (
      parts.first.substring(0, 1) +
      parts.last.substring(0, 1)
    ).toUpperCase();
  }
}