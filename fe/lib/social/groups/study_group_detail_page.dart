import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';
import '../../services/auth_session.dart';

import '../social_models.dart';

import '../layers/group_chat_layer.dart';
import '../layers/group_partecipants_layer.dart';
import '../layers/group_management_layer.dart';

import 'models/study_group.dart';


// =============================================================================
// STUDY GROUP DETAIL PAGE
// =============================================================================

class StudyGroupDetailPage extends StatefulWidget {
  final StudyGroup group;


  const StudyGroupDetailPage({
    super.key,
    required this.group,
  });


  @override
  State<StudyGroupDetailPage> createState() =>
      _StudyGroupDetailPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _StudyGroupDetailPageState
    extends State<StudyGroupDetailPage> {

  final ApiService _apiService =
      ApiService();


  final AuthSession _session =
      AuthSession.instance;


  // ===========================================================================
  // DATA
  // ===========================================================================

  List<SocialUser> _participants =
      [];


  List<_GroupMaterial> _materials =
      [];


  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _loading =
      true;


  bool _loadingMaterials =
      false;


  bool _leavingGroup =
      false;


  String? _error;


  // ===========================================================================
  // GETTERS
  // ===========================================================================

  StudyGroup get group {
    return widget.group;
  }


  SocialUser? get currentUser {
    return _session.currentUser;
  }


  int? get currentUserId {
    return _session.currentUserId;
  }


  bool get isAuthenticated {
    return _session.isAuthenticated;
  }


  bool get isGuest {
    return _session.isGuest;
  }


  bool get isCurrentUserMember {
    final int? userId =
        currentUserId;


    if (userId == null) {
      return false;
    }


    return _participants.any(
      (
        participant,
      ) =>
          participant.id ==
          userId,
    );
  }


  bool get canUseGroupChat {
    return isAuthenticated &&
        (
          isCurrentUserMember ||
              group.isOwner
        );
  }


  bool get canUploadMaterial {
    // Manteniamo la regola già presente
    // nella vecchia pagina:
    // soltanto l'owner può caricare.
    //
    // Se successivamente vorremo permettere
    // l'upload a tutti i membri,
    // basta modificare questo getter.
    return isAuthenticated &&
        group.isOwner;
  }


  bool get canDeleteMaterial {
    return isAuthenticated &&
        group.isOwner;
  }


  bool get canLeaveGroup {
    return isAuthenticated &&
        isCurrentUserMember &&
        !group.isOwner;
  }


  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();


    _session.addListener(
      _onSessionChanged,
    );


    _loadGroupData();
  }


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _session.removeListener(
      _onSessionChanged,
    );


    super.dispose();
  }


  // ===========================================================================
  // SESSION CHANGED
  // ===========================================================================

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }


    setState(() {});
  }


  // ===========================================================================
  // CARICAMENTO DATI GRUPPO
  // ===========================================================================

  Future<void> _loadGroupData() async {
    if (mounted) {
      setState(() {
        _loading =
            true;

        _error =
            null;
      });
    }


    try {
      final Map<String, dynamic>
          groupData =
          await _apiService.getGroup(
        group.id,
      );


      final List<SocialUser> participants =
          await _loadParticipants(
        groupData,
      );


      final List<_GroupMaterial> materials =
          await _loadMaterials();


      if (!mounted) {
        return;
      }


      setState(() {
        _participants =
            participants;

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
            _cleanError(
          e,
        );
      });
    }
  }


  // ===========================================================================
  // PARTECIPANTI
  // ===========================================================================

  Future<List<SocialUser>> _loadParticipants(
    Map<String, dynamic> groupData,
  ) async {
    final dynamic membersData =
        groupData['members'];


    if (membersData is! List) {
      return [];
    }


    final List<SocialUser> users =
        [];


    for (final dynamic member
        in membersData) {

      if (member is! Map) {
        continue;
      }


      final Map<String, dynamic>
          memberData =
          Map<String, dynamic>.from(
        member,
      );


      final int? userId =
          _toInt(
        memberData['user_id'],
      );


      if (userId ==
          null) {
        continue;
      }


      try {
        final SocialUser user =
            await _apiService
                .getSocialUser(
          userId,
        );


        users.add(
          user,
        );
      } catch (_) {
        // Se un singolo profilo non è caricabile
        // continuiamo con gli altri membri.
      }
    }


    return users;
  }


  // ===========================================================================
  // MATERIALI
  // ===========================================================================

  Future<List<_GroupMaterial>>
      _loadMaterials() async {

    final List<Map<String, dynamic>>
        data =
        await _apiService
            .getGroupMaterials(
      group.id,
    );


    return data
        .map(
          _GroupMaterial.fromJson,
        )
        .toList();
  }


  // ===========================================================================
  // REFRESH MATERIALI
  // ===========================================================================

  Future<void> _refreshMaterials() async {
    if (_loadingMaterials) {
      return;
    }


    setState(() {
      _loadingMaterials =
          true;
    });


    try {
      final List<_GroupMaterial> materials =
          await _loadMaterials();


      if (!mounted) {
        return;
      }


      setState(() {
        _materials =
            materials;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore aggiornamento materiali: '
        '${_cleanError(e)}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingMaterials =
              false;
        });
      }
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
          group.name,

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

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),

            onPressed:
                _loading
                    ? null
                    : _loadGroupData,
          ),


          // ===================================================================
          // OWNER MANAGEMENT
          // ===================================================================

          if (isAuthenticated &&
              group.isOwner)
            IconButton(
              tooltip:
                  'Gestisci gruppo',

              icon:
                  const Icon(
                Icons
                    .admin_panel_settings_outlined,
              ),

              onPressed:
                  _openGroupManagement,
            ),


          // ===================================================================
          // MEMBER OPTIONS
          // ===================================================================

          if (canLeaveGroup)
            IconButton(
              tooltip:
                  'Opzioni gruppo',

              icon:
                  const Icon(
                Icons.more_vert_rounded,
              ),

              onPressed:
                  _showOptions,
            ),
        ],
      ),


      // =========================================================================
      // BODY
      // =========================================================================

      body: SafeArea(
        child:
            _buildBody(),
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


    if (_error !=
        null) {
      return Center(
        child:
            ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth:
                600,
          ),

          child:
              Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),

            child:
                _GroupErrorCard(
              message:
                  _error!,

              onRetry:
                  _loadGroupData,
            ),
          ),
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


          return SizedBox(
            width:
                width,

            child:
                RefreshIndicator(
              onRefresh:
                  _loadGroupData,

              child:
                  ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                children: [
                  // ===========================================================
                  // HEADER
                  // ===========================================================

                  _buildGroupHeader(),

                  const SizedBox(
                    height:
                        16,
                  ),


                  // ===========================================================
                  // GUEST INFO
                  // ===========================================================

                  if (isGuest) ...[
                    _buildGuestInfo(),

                    const SizedBox(
                      height:
                          16,
                    ),
                  ],


                  // ===========================================================
                  // NON MEMBER INFO
                  // ===========================================================

                  if (isAuthenticated &&
                      !isCurrentUserMember &&
                      !group.isOwner) ...[
                    _buildNonMemberInfo(),

                    const SizedBox(
                      height:
                          16,
                    ),
                  ],


                  // ===========================================================
                  // CHAT
                  // ===========================================================

                  _buildChatCard(),

                  const SizedBox(
                    height:
                        12,
                  ),


                  // ===========================================================
                  // PARTECIPANTI
                  // ===========================================================

                  _buildParticipantsCard(),

                  const SizedBox(
                    height:
                        28,
                  ),


                  // ===========================================================
                  // MATERIALI
                  // ===========================================================

                  GroupMaterialSection(
                    group:
                        group,

                    materials:
                        _materials,

                    loading:
                        _loadingMaterials,

                    canAddMaterial:
                        canUploadMaterial,

                    canDeleteMaterial:
                        canDeleteMaterial,

                    onRefresh:
                        _refreshMaterials,

                    onAddMaterial:
                        _addMaterial,

                    onOpenMaterial:
                        _openMaterial,

                    onDownloadMaterial:
                        _downloadMaterial,

                    onDeleteMaterial:
                        _deleteMaterial,
                  ),

                  const SizedBox(
                    height:
                        24,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ===========================================================================
  // HEADER GRUPPO
  // ===========================================================================

  Widget _buildGroupHeader() {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {

        final double width =
            constraints.maxWidth;


        final bool compact =
            width <
                380;


        final bool medium =
            width >=
                    380 &&
                width <
                    600;


        final double padding =
            compact
                ? 14
                : medium
                    ? 17
                    : 20;


        final double iconSize =
            compact
                ? 44
                : medium
                    ? 50
                    : 56;


        final double icon =
            compact
                ? 23
                : medium
                    ? 27
                    : 30;


        return Container(
          width:
              double.infinity,

          padding:
              EdgeInsets.all(
            padding,
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
                0.18,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.15,
                ),

                blurRadius:
                    8,

                offset:
                    const Offset(
                  0,
                  4,
                ),
              ),
            ],
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
                        iconSize,

                    height:
                        iconSize,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors
                              .brandNightBlue,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child:
                        Icon(
                      Icons.groups_rounded,

                      color:
                          AppColors.skyBlue,

                      size:
                          icon,
                    ),
                  ),

                  const Spacer(),


                  // ===========================================================
                  // OWNER
                  // ===========================================================

                  if (group.isOwner)
                    _GroupHeaderBadge(
                      icon:
                          Icons
                              .admin_panel_settings_outlined,

                      label:
                          'Owner',

                      compact:
                          compact,
                    ),


                  if (group.isOwner &&
                      group.isPrivate)
                    const SizedBox(
                      width:
                          7,
                    ),


                  // ===========================================================
                  // PRIVATE
                  // ===========================================================

                  if (group.isPrivate)
                    _GroupHeaderBadge(
                      icon:
                          Icons
                              .lock_outline_rounded,

                      label:
                          'Privato',

                      compact:
                          compact,
                    ),
                ],
              ),

              SizedBox(
                height:
                    compact
                        ? 12
                        : 16,
              ),

              Text(
                group.name,

                maxLines:
                    2,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite,

                  fontSize:
                      compact
                          ? 16
                          : medium
                              ? 18
                              : 20,

                  fontWeight:
                      FontWeight.bold,

                  height:
                      1.2,
                ),
              ),

              SizedBox(
                height:
                    compact
                        ? 4
                        : 6,
              ),

              Text(
                group.subject.isNotEmpty
                    ? group.subject
                    : group.subjectId !=
                            null
                        ? 'Materia #${group.subjectId}'
                        : 'Materia non specificata',

                maxLines:
                    1,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    TextStyle(
                  color:
                      AppColors.materialSky
                          .withOpacity(
                    0.90,
                  ),

                  fontSize:
                      compact
                          ? 11
                          : 13,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height:
                    5,
              ),

              Text(
                group.course,

                maxLines:
                    1,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.60,
                  ),

                  fontSize:
                      compact
                          ? 10
                          : 12,
                ),
              ),


              if (group.department
                  .isNotEmpty) ...[
                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  group.department,

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
                        compact
                            ? 9
                            : 10,
                  ),
                ),
              ],

              SizedBox(
                height:
                    compact
                        ? 13
                        : 17,
              ),

              Text(
                group.description.isEmpty
                    ? 'Nessuna descrizione.'
                    : group.description,

                maxLines:
                    compact
                        ? 3
                        : 4,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withOpacity(
                    0.58,
                  ),

                  fontSize:
                      compact
                          ? 11
                          : 13,

                  height:
                      1.4,
                ),
              ),

              SizedBox(
                height:
                    compact
                        ? 14
                        : 18,
              ),

              Wrap(
                spacing:
                    16,

                runSpacing:
                    9,

                children: [
                  _GroupHeaderInfo(
                    icon:
                        Icons
                            .people_outline_rounded,

                    text:
                        '${_participants.length} partecipanti',

                    compact:
                        compact,
                  ),

                  _GroupHeaderInfo(
                    icon:
                        Icons.folder_outlined,

                    text:
                        '${_materials.length} materiali',

                    compact:
                        compact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  // ===========================================================================
  // GUEST INFO
  // ===========================================================================

  Widget _buildGuestInfo() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.skyBlue
                .withOpacity(
          0.06,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.13,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.visibility_outlined,

            color:
                AppColors.materialSky,

            size:
                20,
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child:
                Text(
              'Stai visualizzando il gruppo come Guest. '
              'Puoi consultare le informazioni, vedere i partecipanti '
              'e il materiale disponibile. Per utilizzare la chat '
              'e partecipare alle attività del gruppo devi accedere '
              'a StudentLab.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.55,
                ),

                fontSize:
                    11,

                height:
                    1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // NON MEMBER INFO
  // ===========================================================================

  Widget _buildNonMemberInfo() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.skyBlue
                .withOpacity(
          0.05,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
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
          const Icon(
            Icons.group_add_outlined,

            color:
                AppColors.materialSky,

            size:
                20,
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child:
                Text(
              'Puoi esplorare questo gruppo, ma la chat è '
              'riservata ai partecipanti.',

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
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // CHAT
  // ===========================================================================

  Widget _buildChatCard() {
    return _GroupActionCard(
      icon:
          Icons
              .chat_bubble_outline_rounded,

      title:
          'Chat del gruppo',

      description:
          canUseGroupChat
              ? 'Parla con i partecipanti del gruppo.'
              : isGuest
                  ? 'Accedi per utilizzare la chat del gruppo.'
                  : 'La chat è disponibile ai partecipanti del gruppo.',

      counter:
          'Chat',

      enabled:
          canUseGroupChat,

      onTap:
          _openChat,
    );
  }


  // ===========================================================================
  // OPEN CHAT
  // ===========================================================================

  void _openChat() {
    final SocialUser? user =
        currentUser;


    if (user ==
        null) {
      _showAuthenticationRequired();

      return;
    }


    if (!canUseGroupChat) {
      _showMessage(
        'Devi partecipare al gruppo per utilizzare la chat.',
      );

      return;
    }


    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                GroupChatLayer(
          groupId:
              group.id,

          groupName:
              group.name,

          subjectName:
              group.subject,

          currentUser:
              user,
        ),
      ),
    );
  }


  // ===========================================================================
  // PARTECIPANTI
  // ===========================================================================

  Widget _buildParticipantsCard() {
    return _GroupActionCard(
      icon:
          Icons.people_outline_rounded,

      title:
          'Partecipanti',

      description:
          'Visualizza studenti e insegnanti appartenenti al gruppo.',

      counter:
          '${_participants.length}',

      enabled:
          true,

      onTap:
          _openParticipants,
    );
  }


  // ===========================================================================
  // OPEN PARTICIPANTS
  // ===========================================================================

  void _openParticipants() {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                GroupParticipantsLayer(
          group:
              group,
        ),
      ),
    );
  }


  // ===========================================================================
  // GESTIONE GRUPPO
  // ===========================================================================

  void _openGroupManagement() {
    if (!isAuthenticated ||
        !group.isOwner) {
      return;
    }


    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (_) =>
                GroupManagementPage(
          group:
              group,
        ),
      ),
    );
  }


  // ===========================================================================
  // APRI MATERIALE
  // ===========================================================================

  Future<void> _openMaterial(
    _GroupMaterial material,
  ) async {
    try {
      final bytes =
          await _apiService
              .downloadGroupMaterial(
        material.id,
      );


      if (!mounted) {
        return;
      }


      // Per ora il backend restituisce correttamente
      // il contenuto binario.
      //
      // Il viewer PDF/DOCX verrà collegato
      // al servizio file locale.
      _showMessage(
        '${material.originalName} caricato '
        '(${bytes.length} byte).',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore apertura materiale: '
        '${_cleanError(e)}',
      );
    }
  }


  // ===========================================================================
  // DOWNLOAD MATERIALE
  // ===========================================================================

  Future<void> _downloadMaterial(
    _GroupMaterial material,
  ) async {
    try {
      final bytes =
          await _apiService
              .downloadGroupMaterial(
        material.id,
      );


      if (!mounted) {
        return;
      }


      // Il download HTTP funziona.
      //
      // Il salvataggio definitivo sul filesystem
      // deve passare dal MaterialDownloadService
      // costruito nel local_storage.
      _showMessage(
        'Download ricevuto: '
        '${material.originalName} '
        '(${bytes.length} byte).',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore download materiale: '
        '${_cleanError(e)}',
      );
    }
  }


  // ===========================================================================
  // AGGIUNGI MATERIALE
  // ===========================================================================

  Future<void> _addMaterial() async {
    if (!canUploadMaterial) {
      if (isGuest) {
        _showAuthenticationRequired();
      } else {
        _showMessage(
          'Non hai i permessi per caricare materiale.',
        );
      }

      return;
    }


    final SocialUser? user =
        currentUser;


    if (user ==
        null) {
      _showAuthenticationRequired();

      return;
    }


    try {
      final FilePickerResult? result =
          await FilePicker.platform
              .pickFiles(
        allowMultiple:
            false,

        type:
            FileType.custom,

        allowedExtensions: [
          'pdf',
          'txt',
          'zip',
          'docx',
          'pptx',
        ],
      );


      if (result ==
          null) {
        return;
      }


      final PlatformFile selectedFile =
          result.files.single;


      final String? filePath =
          selectedFile.path;


      if (filePath ==
          null) {
        _showMessage(
          'Impossibile ottenere il percorso del file.',
        );

        return;
      }


      await _apiService
          .addGroupMaterial(
        groupId:
            group.id,

        uploadedBy:
            user.id,

        filePath:
            filePath,
      );


      await _refreshMaterials();


      if (!mounted) {
        return;
      }


      _showMessage(
        'Materiale caricato correttamente.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore caricamento materiale: '
        '${_cleanError(e)}',
      );
    }
  }


  // ===========================================================================
  // ELIMINA MATERIALE
  // ===========================================================================

  Future<void> _deleteMaterial(
    _GroupMaterial material,
  ) async {
    if (!canDeleteMaterial) {
      return;
    }


    final bool? confirmed =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
        dialogContext,
      ) {

        return AlertDialog(
          backgroundColor:
              AppColors.eleganceDeepNavy,

          title:
              const Text(
            'Elimina materiale',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Text(
            'Vuoi eliminare '
            '"${material.originalName}"?',

            style:
                const TextStyle(
              color:
                  Colors.white70,
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'Annulla',
              ),
            ),

            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Elimina',

                style:
                    TextStyle(
                  color:
                      Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );


    if (confirmed !=
        true) {
      return;
    }


    try {
      await _apiService
          .removeGroupMaterial(
        material.id,
      );


      await _refreshMaterials();


      if (!mounted) {
        return;
      }


      _showMessage(
        'Materiale eliminato.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore eliminazione materiale: '
        '${_cleanError(e)}',
      );
    }
  }


  // ===========================================================================
  // OPTIONS
  // ===========================================================================

  void _showOptions() {
    if (!canLeaveGroup) {
      return;
    }


    showModalBottomSheet<void>(
      context:
          context,

      backgroundColor:
          AppColors.eleganceDeepNavy,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            20,
          ),
        ),
      ),

      builder:
          (
        sheetContext,
      ) {

        return SafeArea(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const SizedBox(
                height:
                    8,
              ),

              ListTile(
                enabled:
                    !_leavingGroup,

                leading:
                    _leavingGroup
                        ? const SizedBox(
                            width:
                                22,

                            height:
                                22,

                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .exit_to_app_rounded,

                            color:
                                Colors.redAccent,
                          ),

                title:
                    const Text(
                  'Esci dal gruppo',

                  style:
                      TextStyle(
                    color:
                        Colors.redAccent,
                  ),
                ),

                onTap:
                    _leavingGroup
                        ? null
                        : () {
                            Navigator.pop(
                              sheetContext,
                            );

                            _leaveGroup();
                          },
              ),

              const SizedBox(
                height:
                    6,
              ),
            ],
          ),
        );
      },
    );
  }


  // ===========================================================================
  // ESCI DAL GRUPPO
  // ===========================================================================

  Future<void> _leaveGroup() async {
    final int? userId =
        currentUserId;


    if (userId ==
        null) {
      _showAuthenticationRequired();

      return;
    }


    if (!canLeaveGroup) {
      return;
    }


    final bool? confirmed =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
        dialogContext,
      ) {

        return AlertDialog(
          backgroundColor:
              AppColors.eleganceDeepNavy,

          title:
              const Text(
            'Esci dal gruppo',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Text(
            'Vuoi davvero uscire da "${group.name}"?',

            style:
                const TextStyle(
              color:
                  Colors.white70,
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'Annulla',
              ),
            ),

            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Esci',

                style:
                    TextStyle(
                  color:
                      Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );


    if (confirmed !=
        true) {
      return;
    }


    setState(() {
      _leavingGroup =
          true;
    });


    try {
      await _apiService
          .removeGroupMember(
        groupId:
            group.id,

        userId:
            userId,
      );


      if (!mounted) {
        return;
      }


      _showMessage(
        'Hai lasciato il gruppo.',
      );


      Navigator.of(
        context,
      ).pop(
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }


      _showMessage(
        'Errore durante l\'uscita dal gruppo: '
        '${_cleanError(e)}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _leavingGroup =
              false;
        });
      }
    }
  }


  // ===========================================================================
  // AUTH REQUIRED
  // ===========================================================================

  void _showAuthenticationRequired() {
    _showMessage(
      'Accedi a StudentLab per utilizzare questa funzione.',
    );
  }


  // ===========================================================================
  // MESSAGE
  // ===========================================================================

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


  // ===========================================================================
  // CLEAN ERROR
  // ===========================================================================

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


  // ===========================================================================
  // INT
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


// =============================================================================
// MODEL MATERIALE BACKEND
// =============================================================================

class _GroupMaterial {
  final int id;

  final int groupId;

  final int uploadedBy;

  final String originalName;

  final String storedName;

  final String filePath;

  final String mimeType;

  final int size;

  final DateTime? createdAt;


  const _GroupMaterial({
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


  // ===========================================================================
  // FROM JSON
  // ===========================================================================

  factory _GroupMaterial.fromJson(
    Map<String, dynamic> json,
  ) {

    return _GroupMaterial(
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
  // TYPE
  // ===========================================================================

  String get type {
    if (mimeType ==
        'application/pdf') {
      return 'PDF';
    }


    if (mimeType.contains(
      'wordprocessingml',
    )) {
      return 'DOCX';
    }


    if (mimeType.contains(
      'presentationml',
    )) {
      return 'PPTX';
    }


    if (mimeType ==
        'application/zip') {
      return 'ZIP';
    }


    if (mimeType ==
        'text/plain') {
      return 'TXT';
    }


    return 'FILE';
  }


  // ===========================================================================
  // FORMATTED SIZE
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
  // INT
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


// =============================================================================
// HEADER BADGE
// =============================================================================

class _GroupHeaderBadge
    extends StatelessWidget {

  final IconData icon;

  final String label;

  final bool compact;


  const _GroupHeaderBadge({
    required this.icon,
    required this.label,
    required this.compact,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            compact
                ? 6
                : 8,

        vertical:
            compact
                ? 4
                : 5,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.12,
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
                AppColors.skyBlue,

            size:
                compact
                    ? 11
                    : 13,
          ),

          const SizedBox(
            width:
                4,
          ),

          Text(
            label,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontSize:
                  compact
                      ? 8
                      : 9,

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
// HEADER INFO
// =============================================================================

class _GroupHeaderInfo
    extends StatelessWidget {

  final IconData icon;

  final String text;

  final bool compact;


  const _GroupHeaderInfo({
    required this.icon,
    required this.text,
    required this.compact,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Icon(
          icon,

          size:
              compact
                  ? 14
                  : 16,

          color:
              AppColors.materialSky,
        ),

        const SizedBox(
          width:
              5,
        ),

        Text(
          text,

          style:
              TextStyle(
            color:
                AppColors.materialSky
                    .withOpacity(
              0.90,
            ),

            fontSize:
                compact
                    ? 9
                    : 11,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


// =============================================================================
// MATERIALI DEL GRUPPO
// =============================================================================

class GroupMaterialSection
    extends StatelessWidget {

  final StudyGroup group;

  final List<_GroupMaterial> materials;

  final bool loading;

  final bool canAddMaterial;

  final bool canDeleteMaterial;

  final Future<void> Function()
      onRefresh;

  final VoidCallback
      onAddMaterial;

  final void Function(
    _GroupMaterial material,
  ) onOpenMaterial;

  final void Function(
    _GroupMaterial material,
  ) onDownloadMaterial;

  final void Function(
    _GroupMaterial material,
  ) onDeleteMaterial;


  const GroupMaterialSection({
    super.key,
    required this.group,
    required this.materials,
    required this.loading,
    required this.canAddMaterial,
    required this.canDeleteMaterial,
    required this.onRefresh,
    required this.onAddMaterial,
    required this.onOpenMaterial,
    required this.onDownloadMaterial,
    required this.onDeleteMaterial,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Expanded(
              child:
                  Text(
                'Materiali',

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
            ),

            if (loading)
              const SizedBox(
                width:
                    18,

                height:
                    18,

                child:
                    CircularProgressIndicator(
                  strokeWidth:
                      2,
                ),
              )
            else
              IconButton(
                tooltip:
                    'Aggiorna materiali',

                icon:
                    const Icon(
                  Icons.refresh_rounded,

                  color:
                      AppColors.materialSky,
                ),

                onPressed:
                    () {
                  onRefresh();
                },
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
                '${materials.length}',

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
            ),
          ],
        ),

        const SizedBox(
          height:
              6,
        ),

        Text(
          'Materiale condiviso nel gruppo.',

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
              16,
        ),

        LayoutBuilder(
          builder:
              (
            context,
            constraints,
          ) {

            final double width =
                constraints.maxWidth;


            int columns;


            if (width <
                420) {
              columns =
                  1;
            } else if (width <
                760) {
              columns =
                  2;
            } else {
              columns =
                  3;
            }


            final int itemCount =
                materials.length +
                    (
                      canAddMaterial
                          ? 1
                          : 0
                    );


            if (itemCount ==
                0) {
              return const _EmptyGroupMaterials();
            }


            return GridView.builder(
              shrinkWrap:
                  true,

              physics:
                  const NeverScrollableScrollPhysics(),

              itemCount:
                  itemCount,

              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    columns,

                crossAxisSpacing:
                    14,

                mainAxisSpacing:
                    14,

                mainAxisExtent:
                    columns ==
                            1
                        ? 175
                        : 190,
              ),

              itemBuilder:
                  (
                context,
                index,
              ) {

                if (canAddMaterial &&
                    index ==
                        0) {
                  return _AddGroupMaterialCard(
                    onTap:
                        onAddMaterial,
                  );
                }


                final int materialIndex =
                    canAddMaterial
                        ? index -
                            1
                        : index;


                final _GroupMaterial material =
                    materials[
                        materialIndex];


                return _GroupMaterialCard(
                  material:
                      material,

                  canDelete:
                      canDeleteMaterial,

                  onOpen:
                      () {
                    onOpenMaterial(
                      material,
                    );
                  },

                  onDownload:
                      () {
                    onDownloadMaterial(
                      material,
                    );
                  },

                  onDelete:
                      () {
                    onDeleteMaterial(
                      material,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}


// =============================================================================
// ADD MATERIAL CARD
// =============================================================================

class _AddGroupMaterialCard
    extends StatelessWidget {

  final VoidCallback onTap;


  const _AddGroupMaterialCard({
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
            onTap,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            16,
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
                0.18,
              ),
            ),
          ),

          child:
              const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                Icons
                    .add_circle_outline_rounded,

                color:
                    AppColors.skyBlue,

                size:
                    35,
              ),

              SizedBox(
                height:
                    18,
              ),

              Text(
                'Aggiungi materiale',

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

              SizedBox(
                height:
                    6,
              ),

              Text(
                'Condividi un nuovo file',

                style:
                    TextStyle(
                  color:
                      Colors.white60,

                  fontSize:
                      11,
                ),
              ),

              Spacer(),

              Row(
                children: [
                  Icon(
                    Icons
                        .cloud_upload_outlined,

                    color:
                        AppColors.materialSky,

                    size:
                        16,
                  ),

                  SizedBox(
                    width:
                        5,
                  ),

                  Text(
                    'Carica nel gruppo',

                    style:
                        TextStyle(
                      color:
                          AppColors.materialSky,

                      fontSize:
                          11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// MATERIAL CARD
// =============================================================================

class _GroupMaterialCard
    extends StatelessWidget {

  final _GroupMaterial material;

  final bool canDelete;

  final VoidCallback onOpen;

  final VoidCallback onDownload;

  final VoidCallback onDelete;


  const _GroupMaterialCard({
    required this.material,
    required this.canDelete,
    required this.onOpen,
    required this.onDownload,
    required this.onDelete,
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
            onOpen,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child:
            Container(
          padding:
              const EdgeInsets.all(
            16,
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
                  Container(
                    width:
                        46,

                    height:
                        46,

                    decoration:
                        BoxDecoration(
                      color:
                          AppColors
                              .brandNightBlue,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child:
                        Icon(
                      material.type ==
                              'PDF'
                          ? Icons
                              .picture_as_pdf_rounded
                          : Icons
                              .description_rounded,

                      color:
                          AppColors.skyBlue,

                      size:
                          25,
                    ),
                  ),

                  const Spacer(),

                  PopupMenuButton<String>(
                    tooltip:
                        'Opzioni materiale',

                    color:
                        AppColors
                            .eleganceDeepNavy,

                    icon:
                        const Icon(
                      Icons.more_vert_rounded,

                      color:
                          Colors.white54,
                    ),

                    onSelected:
                        (
                      String value,
                    ) {

                      switch (value) {
                        case 'open':
                          onOpen();

                          break;

                        case 'download':
                          onDownload();

                          break;

                        case 'delete':
                          onDelete();

                          break;
                      }
                    },

                    itemBuilder:
                        (
                      context,
                    ) {

                      return [
                        const PopupMenuItem<String>(
                          value:
                              'open',

                          child:
                              Text(
                            'Apri',

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite,
                            ),
                          ),
                        ),

                        const PopupMenuItem<String>(
                          value:
                              'download',

                          child:
                              Text(
                            'Scarica',

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite,
                            ),
                          ),
                        ),

                        if (canDelete)
                          const PopupMenuItem<String>(
                            value:
                                'delete',

                            child:
                                Text(
                              'Elimina',

                              style:
                                  TextStyle(
                                color:
                                    Colors.redAccent,
                              ),
                            ),
                          ),
                      ];
                    },
                  ),
                ],
              ),

              const SizedBox(
                height:
                    14,
              ),

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
                      15,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height:
                    6,
              ),

              Text(
                material.type,

                style:
                    const TextStyle(
                  color:
                      Colors.white60,

                  fontSize:
                      11,
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,

                    color:
                        AppColors.materialSky,

                    size:
                        15,
                  ),

                  const SizedBox(
                    width:
                        5,
                  ),

                  Expanded(
                    child:
                        Text(
                      '${material.type} • '
                      '${material.formattedSize}',

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            AppColors.materialSky,

                        fontSize:
                            10,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap:
                        onDownload,

                    child:
                        const Padding(
                      padding:
                          EdgeInsets.all(
                        5,
                      ),

                      child:
                          Icon(
                        Icons.download_rounded,

                        color:
                            AppColors.materialSky,

                        size:
                            18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// EMPTY MATERIALS
// =============================================================================

class _EmptyGroupMaterials
    extends StatelessWidget {

  const _EmptyGroupMaterials();


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        28,
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
          const Column(
        children: [
          Icon(
            Icons.folder_open_rounded,

            color:
                Colors.white38,

            size:
                42,
          ),

          SizedBox(
            height:
                10,
          ),

          Text(
            'Nessun materiale condiviso.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.white70,

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
// GROUP ACTION CARD
// =============================================================================

class _GroupActionCard
    extends StatelessWidget {

  final IconData icon;

  final String title;

  final String description;

  final String counter;

  final bool enabled;

  final VoidCallback onTap;


  const _GroupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.counter,
    required this.enabled,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {

        final bool compact =
            constraints.maxWidth <
                360;


        return Material(
          color:
              Colors.transparent,

          child:
              InkWell(
            onTap:
                onTap,

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            child:
                AnimatedOpacity(
              duration:
                  const Duration(
                milliseconds:
                    150,
              ),

              opacity:
                  enabled
                      ? 1
                      : 0.65,

              child:
                  Container(
                padding:
                    EdgeInsets.all(
                  compact
                      ? 13
                      : 16,
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
                          compact
                              ? 43
                              : 48,

                      height:
                          compact
                              ? 43
                              : 48,

                      decoration:
                          BoxDecoration(
                        color:
                            AppColors
                                .brandNightBlue,

                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),

                      child:
                          Icon(
                        icon,

                        color:
                            enabled
                                ? AppColors.skyBlue
                                : Colors.white38,

                        size:
                            compact
                                ? 22
                                : 25,
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
                            title,

                            style:
                                TextStyle(
                              color:
                                  enabled
                                      ? AppColors.pureWhite
                                      : Colors.white54,

                              fontSize:
                                  compact
                                      ? 13
                                      : 15,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height:
                                4,
                          ),

                          Text(
                            description,

                            maxLines:
                                2,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                TextStyle(
                              color:
                                  AppColors.pureWhite
                                      .withOpacity(
                                enabled
                                    ? 0.55
                                    : 0.35,
                              ),

                              fontSize:
                                  compact
                                      ? 10
                                      : 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!compact)
                      Text(
                        counter,

                        style:
                            TextStyle(
                          color:
                              enabled
                                  ? AppColors.materialSky
                                  : Colors.white30,

                          fontSize:
                              12,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                    const SizedBox(
                      width:
                          5,
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,

                      color:
                          Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// =============================================================================
// ERROR
// =============================================================================

class _GroupErrorCard
    extends StatelessWidget {

  final String message;

  final Future<void> Function()
      onRetry;


  const _GroupErrorCard({
    required this.message,
    required this.onRetry,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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

          const Text(
            'Impossibile caricare il gruppo',

            style:
                TextStyle(
              color:
                  AppColors.pureWhite,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            message,

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
                16,
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
    );
  }
}