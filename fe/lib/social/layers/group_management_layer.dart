import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../social_models.dart';
import '../groups/models/study_group.dart';

class GroupManagementPage extends StatefulWidget {
  final StudyGroup group;
  final List<SocialUser> participants;

  const GroupManagementPage({
    super.key,
    required this.group,
    required this.participants,
  });

  @override
  State<GroupManagementPage> createState() =>
      _GroupManagementPageState();
}

class _GroupManagementPageState
    extends State<GroupManagementPage> {

  // ===========================================================================
  // MOCK RICHIESTE
  // ===========================================================================

  final List<_JoinRequest> _requests = [
    const _JoinRequest(
      id: 'request_1',
      name: 'Luca',
      course: 'Scienze e Tecnologie Informatiche',
    ),
    const _JoinRequest(
      id: 'request_2',
      name: 'Giulia',
      course: 'Scienze e Tecnologie Informatiche',
    ),
  ];

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,

        title: const Text(
          'Amministrazione gruppo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Modifica gruppo',
            icon: const Icon(
              Icons.edit_outlined,
            ),
            onPressed: _editGroup,
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {

              final double width =
                  constraints.maxWidth > 800
                      ? 800
                      : constraints.maxWidth;

              return SizedBox(
                width: width,

                child: ListView(
                  padding: const EdgeInsets.all(20),

                  children: [

                    // =========================================================
                    // GRUPPO
                    // =========================================================

                    _buildGroupHeader(),

                    const SizedBox(height: 20),

                    // =========================================================
                    // RICHIESTE
                    // =========================================================

                    _buildRequestsSection(),

                    const SizedBox(height: 20),

                    // =========================================================
                    // PARTECIPANTI
                    // =========================================================

                    _buildParticipantsSection(),

                    const SizedBox(height: 20),

                    // =========================================================
                    // MATERIALE
                    // =========================================================

                    _buildMaterialSection(),

                    const SizedBox(height: 20),

                    // =========================================================
                    // AZIONI
                    // =========================================================

                    _buildActionsSection(),
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
  // HEADER GRUPPO
  // ===========================================================================

  Widget _buildGroupHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.eleganceMidnight,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.skyBlue.withOpacity(0.16),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Container(
                width: 56,
                height: 56,

                decoration: BoxDecoration(
                  color: AppColors.brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.groups_rounded,

                  color: AppColors.skyBlue,

                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      widget.group.name,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize: 19,

                        fontWeight:
                            FontWeight.bold,

                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      widget.group.subject,

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

          const SizedBox(height: 18),

          Text(
            widget.group.description,

            style: TextStyle(
              color:
                  AppColors.pureWhite
                      .withOpacity(0.60),

              fontSize: 13,

              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [

              _InfoItem(
                icon:
                    Icons.people_outline_rounded,

                label:
                    '${widget.group.memberCount} partecipanti',
              ),

              const SizedBox(width: 18),

              _InfoItem(
                icon:
                    Icons.folder_outlined,

                label:
                    '${widget.group.materialCount} materiali',
              ),

              const Spacer(),

              if (widget.group.isPrivate)
                const Icon(
                  Icons.lock_outline_rounded,

                  color: Colors.white38,

                  size: 18,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RICHIESTE
  // ===========================================================================

  Widget _buildRequestsSection() {
    return _ManagementSection(
      title: 'Richieste di partecipazione',

      icon:
          Icons.person_add_alt_1_outlined,

      counter:
          '${_requests.length}',

      child: _requests.isEmpty
          ? _buildEmptyRequests()
          : Column(
              children: [
                for (int i = 0;
                    i < _requests.length;
                    i++) ...[
                  _RequestCard(
                    request:
                        _requests[i],

                    onAccept: () {
                      _acceptRequest(
                        _requests[i],
                      );
                    },

                    onReject: () {
                      _rejectRequest(
                        _requests[i],
                      );
                    },
                  ),

                  if (i <
                      _requests.length - 1)
                    const SizedBox(
                      height: 10,
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyRequests() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
      ),

      child: Column(
        children: [

          Icon(
            Icons.person_search_outlined,

            color:
                Colors.white
                    .withOpacity(0.30),

            size: 36,
          ),

          const SizedBox(height: 8),

          Text(
            'Nessuna richiesta',

            style: TextStyle(
              color:
                  Colors.white
                      .withOpacity(0.65),

              fontSize: 13,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PARTECIPANTI
  // ===========================================================================

  Widget _buildParticipantsSection() {
    return _ManagementSection(
      title: 'Partecipanti',

      icon:
          Icons.people_outline_rounded,

      counter:
          '${widget.participants.length}',

      child: widget.participants.isEmpty
          ? _buildEmptyParticipants()
          : Column(
              children: [

                for (int i = 0;
                    i < widget.participants.length;
                    i++) ...[

                  _ParticipantManagementCard(
                    user:
                        widget.participants[i],

                    isOwner:
                        i == 0,

                    onRemove:
                        i == 0
                            ? null
                            : () {
                                _removeParticipant(
                                  widget.participants[i],
                                );
                              },
                  ),

                  if (i <
                      widget.participants.length - 1)
                    const SizedBox(
                      height: 10,
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyParticipants() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
      ),

      child: Text(
        'Nessun partecipante nel gruppo.',

        textAlign:
            TextAlign.center,

        style: TextStyle(
          color:
              Colors.white
                  .withOpacity(0.45),

          fontSize: 13,
        ),
      ),
    );
  }

  // ===========================================================================
  // MATERIALE
  // ===========================================================================

  Widget _buildMaterialSection() {
    return _ManagementSection(
      title: 'Materiale del gruppo',

      icon:
          Icons.folder_outlined,

      counter:
          '${widget.group.materialCount}',

      child: Column(
        children: [

          _ManagementActionCard(
            icon:
                Icons.folder_open_outlined,

            title:
                'Gestisci materiale',

            description:
                'Visualizza, aggiungi o rimuovi i file condivisi con il gruppo.',

            onTap:
                _manageMaterials,
          ),

          const SizedBox(height: 10),

          _ManagementActionCard(
            icon:
                Icons.add_rounded,

            title:
                'Aggiungi materiale',

            description:
                'Carica un nuovo documento da condividere con i partecipanti.',

            onTap:
                _addMaterial,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AZIONI
  // ===========================================================================

  Widget _buildActionsSection() {
    return _ManagementSection(
      title: 'Gestione',

      icon:
          Icons.settings_outlined,

      child: Column(
        children: [

          _ManagementActionCard(
            icon:
                Icons.person_add_outlined,

            title:
                'Aggiungi partecipanti',

            description:
                'Cerca studenti o insegnanti e invitali nel gruppo.',

            onTap:
                _addParticipants,
          ),

          const SizedBox(height: 10),

          _ManagementActionCard(
            icon:
                Icons.share_outlined,

            title:
                'Condividi gruppo',

            description:
                'Condividi il gruppo con altri studenti.',

            onTap:
                _shareGroup,
          ),

          const SizedBox(height: 10),

          _ManagementActionCard(
            icon:
                Icons.delete_outline_rounded,

            title:
                'Elimina gruppo',

            description:
                'Elimina definitivamente il gruppo.',

            destructive:
                true,

            onTap:
                _deleteGroup,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AZIONI RICHIESTE
  // ===========================================================================

  void _acceptRequest(
    _JoinRequest request,
  ) {
    setState(() {
      _requests.removeWhere(
        (item) => item.id == request.id,
      );
    });

    _showMessage(
      '${request.name} è stato aggiunto al gruppo.',
    );
  }

  void _rejectRequest(
    _JoinRequest request,
  ) {
    setState(() {
      _requests.removeWhere(
        (item) => item.id == request.id,
      );
    });

    _showMessage(
      'Richiesta di ${request.name} rifiutata.',
    );
  }

  // ===========================================================================
  // AZIONI PARTECIPANTI
  // ===========================================================================

  void _removeParticipant(
    SocialUser user,
  ) {
    _showMessage(
      'Rimozione di ${user.name}: da implementare.',
    );
  }

  void _addParticipants() {
    _showMessage(
      'Ricerca partecipanti: da implementare.',
    );
  }

  // ===========================================================================
  // MATERIALE
  // ===========================================================================

  void _manageMaterials() {
    _showMessage(
      'Gestione materiale: da implementare.',
    );
  }

  void _addMaterial() {
    _showMessage(
      'Aggiunta materiale: da implementare.',
    );
  }

  // ===========================================================================
  // GRUPPO
  // ===========================================================================

  void _editGroup() {
    _showMessage(
      'Modifica gruppo: da implementare.',
    );
  }

  void _shareGroup() {
    _showMessage(
      'Condivisione gruppo: da implementare.',
    );
  }

  void _deleteGroup() {
    _showMessage(
      'Eliminazione gruppo: da implementare.',
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// =============================================================================
// MANAGEMENT SECTION
// =============================================================================

class _ManagementSection
    extends StatelessWidget {

  final String title;
  final IconData icon;
  final String? counter;
  final Widget child;

  const _ManagementSection({
    required this.title,
    required this.icon,
    required this.child,
    this.counter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Row(
          children: [

            Icon(
              icon,

              color:
                  AppColors.skyBlue,

              size: 20,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  color:
                      AppColors.pureWhite,

                  fontSize: 18,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            if (counter != null)
              Text(
                counter!,

                style: const TextStyle(
                  color:
                      AppColors.materialSky,

                  fontSize: 13,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        child,
      ],
    );
  }
}

// =============================================================================
// REQUEST CARD
// =============================================================================

class _RequestCard
    extends StatelessWidget {

  final _JoinRequest request;

  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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

      child: Row(
        children: [

          _UserAvatar(
            name:
                request.name,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  request.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize: 14,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  request.course,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(0.48),

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Rifiuta',

            onPressed:
                onReject,

            icon:
                const Icon(
              Icons.close_rounded,

              color:
                  Colors.redAccent,

              size: 21,
            ),
          ),

          IconButton(
            tooltip: 'Accetta',

            onPressed:
                onAccept,

            icon:
                const Icon(
              Icons.check_rounded,

              color:
                  AppColors.materialSky,

              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PARTICIPANT CARD
// =============================================================================

class _ParticipantManagementCard
    extends StatelessWidget {

  final SocialUser user;

  final bool isOwner;

  final VoidCallback? onRemove;

  const _ParticipantManagementCard({
    required this.user,
    required this.isOwner,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
                  .withOpacity(0.10),
        ),
      ),

      child: Row(
        children: [

          _UserAvatar(
            name:
                user.name,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  user.name,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize: 14,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user.course,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(0.48),

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (isOwner)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),

              decoration: BoxDecoration(
                color:
                    AppColors.brandNightBlue,

                borderRadius:
                    BorderRadius.circular(8),
              ),

              child: const Text(
                'Amministratore',

                style: TextStyle(
                  color:
                      AppColors.materialSky,

                  fontSize: 9,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              tooltip:
                  'Rimuovi partecipante',

              onPressed:
                  onRemove,

              icon:
                  const Icon(
                Icons.person_remove_outlined,

                color:
                    Colors.white38,

                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// MANAGEMENT ACTION CARD
// =============================================================================

class _ManagementActionCard
    extends StatelessWidget {

  final IconData icon;

  final String title;
  final String description;

  final bool destructive;

  final VoidCallback onTap;

  const _ManagementActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {

    final Color iconColor =
        destructive
            ? Colors.redAccent
            : AppColors.skyBlue;

    return InkWell(
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(16),

      child: Container(
        width:
            double.infinity,

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
                destructive
                    ? Colors.redAccent
                        .withOpacity(0.12)
                    : AppColors.skyBlue
                        .withOpacity(0.10),
          ),
        ),

        child: Row(
          children: [

            Container(
              width: 46,
              height: 46,

              decoration:
                  BoxDecoration(
                color:
                    destructive
                        ? Colors.redAccent
                            .withOpacity(0.10)
                        : AppColors
                            .brandNightBlue,

                borderRadius:
                    BorderRadius.circular(13),
              ),

              child: Icon(
                icon,

                color:
                    iconColor,

                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    title,

                    style:
                        TextStyle(
                      color:
                          destructive
                              ? Colors.redAccent
                              : AppColors.pureWhite,

                      fontSize: 14,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    description,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      color:
                          AppColors.pureWhite
                              .withOpacity(0.48),

                      fontSize: 11,

                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
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
}

// =============================================================================
// USER AVATAR
// =============================================================================

class _UserAvatar
    extends StatelessWidget {

  final String name;

  const _UserAvatar({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {

    final String initial =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Container(
      width: 44,
      height: 44,

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(13),
      ),

      alignment:
          Alignment.center,

      child: Text(
        initial,

        style:
            const TextStyle(
          color:
              AppColors.skyBlue,

          fontSize: 17,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}

// =============================================================================
// INFO ITEM
// =============================================================================

class _InfoItem
    extends StatelessWidget {

  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [

        Icon(
          icon,

          color:
              AppColors.materialSky,

          size: 16,
        ),

        const SizedBox(width: 5),

        Text(
          label,

          style: TextStyle(
            color:
                AppColors.pureWhite
                    .withOpacity(0.55),

            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// JOIN REQUEST MODEL
// =============================================================================

class _JoinRequest {

  final String id;
  final String name;
  final String course;

  const _JoinRequest({
    required this.id,
    required this.name,
    required this.course,
  });
}