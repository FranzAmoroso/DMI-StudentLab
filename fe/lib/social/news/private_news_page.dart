import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../theme/nightTheme.dart';
import 'models/group_news.dart';

class PrivateNewsPage extends StatefulWidget {
  const PrivateNewsPage({
    super.key,
  });

  @override
  State<PrivateNewsPage> createState() =>
      _PrivateNewsPageState();
}

class _PrivateNewsPageState
    extends State<PrivateNewsPage> {
  final ApiService _apiService =
      ApiService();

  List<GroupNews> _items =
      [];

  bool _loading =
      true;

  bool _loadingMore =
      false;

  String? _error;

  int _total =
      0;

  int _offset =
      0;

  static const int _limit =
      30;

  int? get _currentUserId =>
      AuthSession.instance.currentUserId;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading =
          true;

      _error =
          null;

      _offset =
          0;
    });

    try {
      final GroupNewsPrivateInboxResult
          result =
          await _apiService
              .getPrivateGroupNews(
        limit:
            _limit,

        offset:
            0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            result.items;

        _total =
            result.total;

        _offset =
            result.items.length;

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
            _friendlyError(
          e,
        );
      });
    }
  }

  Future<void> _loadMore() async {
    if (
      _loading ||
      _loadingMore ||
      _items.length >=
          _total
    ) {
      return;
    }

    setState(() {
      _loadingMore =
          true;
    });

    try {
      final GroupNewsPrivateInboxResult
          result =
          await _apiService
              .getPrivateGroupNews(
        limit:
            _limit,

        offset:
            _offset,
      );

      if (!mounted) {
        return;
      }

      final Map<int, GroupNews>
          merged = {
        for (final GroupNews item
            in _items)
          item.id:
              item,
      };

      for (final GroupNews item
          in result.items) {
        merged[item.id] =
            item;
      }

      final List<GroupNews>
          values =
          merged.values.toList()
            ..sort(
              (
                GroupNews a,
                GroupNews b,
              ) =>
                  b.createdAt.compareTo(
                a.createdAt,
              ),
            );

      setState(() {
        _items =
            values;

        _total =
            result.total;

        _offset =
            result.offset +
                result.items.length;
      });
    } catch (e) {
      _showMessage(
        _friendlyError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore =
              false;
        });
      }
    }
  }

  Future<void> _reply(
    GroupNews news,
  ) async {
    if (!news.canReply) {
      _showMessage(
        'Non è possibile rispondere a questa comunicazione.',
      );

      return;
    }

    final int? currentUserId =
        _currentUserId;

    if (currentUserId == null) {
      _showMessage(
        'La sessione non è più valida. Accedi nuovamente.',
      );

      return;
    }

    final int? recipientUserId =
        currentUserId ==
                news.authorUserId
            ? news.recipientUserId
            : news.authorUserId;

    if (
      recipientUserId ==
      null
    ) {
      _showMessage(
        'Il destinatario non è più disponibile.',
      );

      return;
    }

    final String? content =
        await _askReply(
      news,
    );

    if (
      content ==
          null ||
      content.trim().isEmpty
    ) {
      return;
    }

    try {
      await _apiService
          .createGroupNews(
        groupId:
            news.groupId,

        content:
            content,

        visibility:
            'private',

        recipientUserId:
            recipientUserId,

        parentNewsId:
            news.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Risposta inviata.',
      );

      await _load();
    } catch (e) {
      _showMessage(
        _friendlyError(
          e,
        ),
      );
    }
  }

  Future<void> _delete(
    GroupNews news,
  ) async {
    if (!news.canDelete) {
      return;
    }

    final bool confirmed =
        await _confirm(
      title:
          'Elimina comunicazione',

      message:
          'Vuoi eliminare questa comunicazione? Non sarà più disponibile nel feed.',
      confirmLabel:
          'Elimina',

      destructive:
          true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _apiService
          .deleteGroupNews(
        news.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items.removeWhere(
          (
            GroupNews item,
          ) =>
              item.id ==
              news.id,
        );

        if (_total > 0) {
          _total--;
        }
      });

      _showMessage(
        'Comunicazione eliminata.',
      );
    } catch (e) {
      _showMessage(
        _friendlyError(
          e,
        ),
      );
    }
  }

  Future<void> _report(
    GroupNews news,
  ) async {
    if (!news.canReport) {
      return;
    }

    final _ReportResult? report =
        await _askReport();

    if (report == null) {
      return;
    }

    try {
      await _apiService
          .createGroupNewsReport(
        newsId:
            news.id,

        reason:
            report.reason,

        description:
            report.description,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Segnalazione inviata. Grazie per aver contribuito alla sicurezza di StudentLab.',
      );
    } catch (e) {
      _showMessage(
        _friendlyError(
          e,
        ),
      );
    }
  }

  Future<String?> _askReply(
    GroupNews news,
  ) async {
    final TextEditingController
        controller =
        TextEditingController();

    String? validation;

    final String? result =
        await showModalBottomSheet<String>(
      context:
          context,

      isScrollControlled:
          true,

      backgroundColor:
          AppColors.eleganceDeepNavy,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            22,
          ),
        ),
      ),

      builder:
          (
        BuildContext sheetContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            return Padding(
              padding:
                  EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18 +
                    MediaQuery.of(
                      context,
                    ).viewInsets.bottom,
              ),

              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .lock_outline_rounded,

                        color:
                            AppColors.skyBlue,
                      ),

                      const SizedBox(
                        width:
                            8,
                      ),

                      const Expanded(
                        child:
                            Text(
                          'Rispondi in privato',

                          style:
                              TextStyle(
                            color:
                                AppColors.pureWhite,

                            fontSize:
                                16,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip:
                            'Chiudi',

                        onPressed:
                            () {
                          Navigator.pop(
                            sheetContext,
                          );
                        },

                        icon:
                            const Icon(
                          Icons.close_rounded,

                          color:
                              Colors.white60,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  Text(
                    'Gruppo: ${news.groupName.isEmpty ? 'StudentLab' : news.groupName}',

                    style:
                        TextStyle(
                      color:
                          AppColors.pureWhite
                              .withValues(
                        alpha:
                            0.48,
                      ),

                      fontSize:
                          11,
                    ),
                  ),

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
                        Text(
                      news.content,

                      maxLines:
                          4,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withValues(
                          alpha:
                              0.64,
                        ),

                        fontSize:
                            11,

                        height:
                            1.4,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height:
                        14,
                  ),

                  TextField(
                    controller:
                        controller,

                    autofocus:
                        true,

                    minLines:
                        3,

                    maxLines:
                        6,

                    maxLength:
                        5000,

                    style:
                        const TextStyle(
                      color:
                          AppColors.pureWhite,
                    ),

                    decoration:
                        InputDecoration(
                      hintText:
                          'Scrivi una risposta...',

                      errorText:
                          validation,
                    ),
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  ElevatedButton.icon(
                    onPressed:
                        () {
                      final String text =
                          controller.text
                              .trim();

                      if (text.isEmpty) {
                        setSheetState(
                          () {
                            validation =
                                'Scrivi un messaggio prima di inviare.';
                          },
                        );

                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                        text,
                      );
                    },

                    icon:
                        const Icon(
                      Icons.send_rounded,
                    ),

                    label:
                        const Text(
                      'Invia risposta',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<_ReportResult?>
      _askReport() async {
    final TextEditingController
        descriptionController =
        TextEditingController();

    String selectedReason =
        'spam';

    final _ReportResult? result =
        await showModalBottomSheet<
            _ReportResult>(
      context:
          context,

      isScrollControlled:
          true,

      backgroundColor:
          AppColors.eleganceDeepNavy,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            22,
          ),
        ),
      ),

      builder:
          (
        BuildContext sheetContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            return Padding(
              padding:
                  EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18 +
                    MediaQuery.of(
                      context,
                    ).viewInsets.bottom,
              ),

              child:
                  SingleChildScrollView(
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    const Text(
                      'Segnala comunicazione',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            16,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height:
                          6,
                    ),

                    Text(
                      'La segnalazione sarà inviata ai moderatori di StudentLab. L’autore non vedrà chi l’ha inviata.',

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withValues(
                          alpha:
                              0.48,
                        ),

                        fontSize:
                            11,

                        height:
                            1.4,
                      ),
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      value:
                          selectedReason,

                      dropdownColor:
                          AppColors.eleganceDeepNavy,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,
                      ),

                      items:
                          const [
                        DropdownMenuItem(
                          value:
                              'spam',

                          child:
                              Text(
                            'Spam',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'harassment',

                          child:
                              Text(
                            'Molestie o comportamento offensivo',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'hate',

                          child:
                              Text(
                            'Contenuto discriminatorio',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'privacy',

                          child:
                              Text(
                            'Violazione della privacy',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'illegal_content',

                          child:
                              Text(
                            'Contenuto illecito',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'other',

                          child:
                              Text(
                            'Altro',
                          ),
                        ),
                      ],

                      onChanged:
                          (
                        String? value,
                      ) {
                        if (value ==
                            null) {
                          return;
                        }

                        setSheetState(
                          () {
                            selectedReason =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    TextField(
                      controller:
                          descriptionController,

                      minLines:
                          3,

                      maxLines:
                          6,

                      maxLength:
                          1000,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,
                      ),

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Dettagli facoltativi',
                      ),
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                () {
                              Navigator.pop(
                                sheetContext,
                              );
                            },

                            child:
                                const Text(
                              'Annulla',
                            ),
                          ),
                        ),

                        const SizedBox(
                          width:
                              10,
                        ),

                        Expanded(
                          child:
                              ElevatedButton(
                            onPressed:
                                () {
                              Navigator.pop(
                                sheetContext,

                                _ReportResult(
                                  reason:
                                      selectedReason,

                                  description:
                                      descriptionController
                                          .text
                                          .trim(),
                                ),
                              );
                            },

                            child:
                                const Text(
                              'Invia',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    descriptionController.dispose();

    return result;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final bool? result =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              AppColors.eleganceDeepNavy,

          title:
              Text(
            title,

            style:
                const TextStyle(
              color:
                  AppColors.pureWhite,
            ),
          ),

          content:
              Text(
            message,

            style:
                TextStyle(
              color:
                  AppColors.pureWhite
                      .withValues(
                alpha:
                    0.62,
              ),

              height:
                  1.4,
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
                  Text(
                confirmLabel,

                style:
                    TextStyle(
                  color:
                      destructive
                          ? Colors.redAccent
                          : AppColors.skyBlue,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ==
        true;
  }

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
          'Comunicazioni private',
        ),

        actions: [
          IconButton(
            tooltip:
                'Aggiorna',

            onPressed:
                _loading
                    ? null
                    : _load,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          SafeArea(
        child:
            _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error !=
        null) {
      return _StateView(
        icon:
            Icons
                .error_outline_rounded,

        title:
            'Impossibile caricare le comunicazioni',

        message:
            _error!,

        actionLabel:
            'Riprova',

        onAction:
            _load,
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            _load,

        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: const [
            SizedBox(
              height:
                  110,
            ),

            _StateView(
              icon:
                  Icons
                      .mark_chat_unread_outlined,

              title:
                  'Nessuna comunicazione privata',

              message:
                  'Qui troverai le comunicazioni private ricevute o inviate all’interno dei tuoi gruppi.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          _load,

      child:
          NotificationListener<
              ScrollNotification>(
        onNotification:
            (
          ScrollNotification notification,
        ) {
          if (
            notification.metrics.pixels >=
            notification.metrics.maxScrollExtent -
                220
          ) {
            _loadMore();
          }

          return false;
        },

        child:
            ListView.separated(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            14,
            14,
            14,
            30,
          ),

          itemCount:
              _items.length +
                  (_loadingMore
                      ? 1
                      : 0),

          separatorBuilder:
              (
            BuildContext context,
            int index,
          ) {
            return const SizedBox(
              height:
                  10,
            );
          },

          itemBuilder:
              (
            BuildContext context,
            int index,
          ) {
            if (
              index >=
              _items.length
            ) {
              return const Padding(
                padding:
                    EdgeInsets.all(
                  18,
                ),

                child:
                    Center(
                  child:
                      CircularProgressIndicator(),
                ),
              );
            }

            final GroupNews
                news =
                _items[index];

            return _PrivateNewsCard(
              news:
                  news,

              currentUserId:
                  _currentUserId,

              onReply:
                  news.canReply
                      ? () {
                          _reply(
                            news,
                          );
                        }
                      : null,

              onDelete:
                  news.canDelete
                      ? () {
                          _delete(
                            news,
                          );
                        }
                      : null,

              onReport:
                  news.canReport
                      ? () {
                          _report(
                            news,
                          );
                        }
                      : null,
            );
          },
        ),
      ),
    );
  }

  String _friendlyError(
    Object error,
  ) {
    final String message =
        error
            .toString()
            .toLowerCase();

    if (
      message.contains(
            '401',
          ) ||
      message.contains(
            'unauthorized',
          ) ||
      message.contains(
            'sessione',
          )
    ) {
      return 'La sessione non è più valida. Accedi nuovamente.';
    }

    if (
      message.contains(
            '403',
          ) ||
      message.contains(
            'forbidden',
          )
    ) {
      return 'Non hai i permessi necessari per questa operazione.';
    }

    if (
      message.contains(
            '404',
          ) ||
      message.contains(
            'not found',
          )
    ) {
      return 'La comunicazione non è più disponibile.';
    }

    if (
      message.contains(
            'network',
          ) ||
      message.contains(
            'socket',
          ) ||
      message.contains(
            'connection',
          ) ||
      message.contains(
            'host lookup',
          )
    ) {
      return 'Non è stato possibile contattare StudentLab. Controlla la connessione e riprova.';
    }

    if (
      message.contains(
            'timeout',
          ) ||
      message.contains(
            'timed out',
          )
    ) {
      return 'La richiesta sta impiegando troppo tempo. Riprova tra qualche momento.';
    }

    if (
      message.contains(
            '500',
          ) ||
      message.contains(
            '502',
          ) ||
      message.contains(
            '503',
          )
    ) {
      return 'StudentLab non è temporaneamente disponibile. Riprova tra qualche momento.';
    }

    return 'Non è stato possibile completare l’operazione. Riprova.';
  }

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
}


class _PrivateNewsCard
    extends StatelessWidget {
  final GroupNews news;
  final int? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const _PrivateNewsCard({
    required this.news,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  bool get _isMine =>
      currentUserId !=
          null &&
      news.authorUserId ==
          currentUserId;

  GroupNewsUser? get _otherUser {
    if (_isMine) {
      return news.recipient;
    }

    return news.author;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final GroupNewsUser?
        other =
        _otherUser;

    final String name =
        other?.fullName ??
            'Utente StudentLab';

    final String role =
        _roleLabel(
      other,
    );

    return Container(
      padding:
          const EdgeInsets.all(
        15,
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
              AppColors.skyBlue
                  .withValues(
            alpha:
                0.12,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              CircleAvatar(
                radius:
                    21,

                backgroundColor:
                    AppColors.brandNightBlue,

                child:
                    Text(
                  _initials(
                    name,
                  ),

                  style:
                      const TextStyle(
                    color:
                        AppColors.skyBlue,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      name,

                      maxLines:
                          1,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            13,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height:
                          3,
                    ),

                    Wrap(
                      spacing:
                          6,

                      runSpacing:
                          5,

                      crossAxisAlignment:
                          WrapCrossAlignment.center,

                      children: [
                        _MiniBadge(
                          icon:
                              Icons
                                  .lock_outline_rounded,

                          label:
                              'Privato',
                        ),

                        if (role.isNotEmpty)
                          _MiniBadge(
                            icon:
                                other?.isVerifiedTeacher ==
                                        true
                                    ? Icons
                                        .verified_rounded
                                    : Icons
                                        .person_outline_rounded,

                            label:
                                role,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<
                  String>(
                tooltip:
                    'Azioni',

                color:
                    AppColors.eleganceDeepNavy,

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
                  if (
                    value ==
                        'delete' &&
                    onDelete !=
                        null
                  ) {
                    onDelete!();
                  }

                  if (
                    value ==
                        'report' &&
                    onReport !=
                        null
                  ) {
                    onReport!();
                  }
                },

                itemBuilder:
                    (
                  BuildContext context,
                ) {
                  return [
                    if (onReport !=
                        null)
                      const PopupMenuItem(
                        value:
                            'report',

                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .flag_outlined,

                              size:
                                  18,
                            ),

                            SizedBox(
                              width:
                                  9,
                            ),

                            Text(
                              'Segnala',
                            ),
                          ],
                        ),
                      ),

                    if (onDelete !=
                        null)
                      const PopupMenuItem(
                        value:
                            'delete',

                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline_rounded,

                              size:
                                  18,

                              color:
                                  Colors.redAccent,
                            ),

                            SizedBox(
                              width:
                                  9,
                            ),

                            Text(
                              'Elimina',

                              style:
                                  TextStyle(
                                color:
                                    Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(
            height:
                12,
          ),

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              11,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.brandNightBlue
                      .withValues(
                alpha:
                    0.65,
              ),

              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  news.content,

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withValues(
                      alpha:
                          0.82,
                    ),

                    fontSize:
                        12,

                    height:
                        1.45,
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Row(
                  children: [
                    Icon(
                      Icons
                          .groups_outlined,

                      size:
                          13,

                      color:
                          AppColors.materialSky
                              .withValues(
                        alpha:
                            0.78,
                      ),
                    ),

                    const SizedBox(
                      width:
                          5,
                    ),

                    Expanded(
                      child:
                          Text(
                        news.contextLabel,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            TextStyle(
                          color:
                              AppColors.materialSky
                                  .withValues(
                            alpha:
                                0.78,
                          ),

                          fontSize:
                              9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
                10,
          ),

          Row(
            children: [
              Text(
                _isMine
                    ? 'Inviato'
                    : 'Ricevuto',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withValues(
                    alpha:
                        0.35,
                  ),

                  fontSize:
                      9,
                ),
              ),

              const SizedBox(
                width:
                    6,
              ),

              Text(
                '• ${_formatDate(news.createdAt)}',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withValues(
                    alpha:
                        0.35,
                  ),

                  fontSize:
                      9,
                ),
              ),

              const Spacer(),

              if (onReply !=
                  null)
                TextButton.icon(
                  onPressed:
                      onReply,

                  icon:
                      const Icon(
                    Icons.reply_rounded,

                    size:
                        17,
                  ),

                  label:
                      const Text(
                    'Rispondi',
                  ),
                ),
            ],
          ),

          if (
            onReply ==
                null &&
            !news.isExpired
          )
            Padding(
              padding:
                  const EdgeInsets.only(
                top:
                    4,
              ),

              child:
                  Text(
                'Non è possibile rispondere a questa comunicazione.',

                style:
                    TextStyle(
                  color:
                      AppColors.pureWhite
                          .withValues(
                    alpha:
                        0.34,
                  ),

                  fontSize:
                      9,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _roleLabel(
    GroupNewsUser? user,
  ) {
    if (user == null) {
      return '';
    }

    if (user.isVerifiedTeacher) {
      return 'Docente verificato';
    }

    if (user.role ==
        'creator') {
      return 'Creator';
    }

    if (user.role ==
        'admin') {
      return 'Admin';
    }

    return '';
  }

  String _initials(
    String name,
  ) {
    final List<String> parts =
        name
            .trim()
            .split(
              RegExp(
                r'\s+',
              ),
            )
            .where(
              (
                String value,
              ) =>
                  value.isNotEmpty,
            )
            .toList();

    if (parts.isEmpty) {
      return 'S';
    }

    if (parts.length ==
        1) {
      return parts.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatDate(
    DateTime date,
  ) {
    final DateTime now =
        DateTime.now();

    final DateTime local =
        date.toLocal();

    final bool today =
        now.year ==
            local.year &&
        now.month ==
            local.month &&
        now.day ==
            local.day;

    if (today) {
      return 'oggi ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}


class _MiniBadge
    extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({
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
            7,

        vertical:
            4,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.skyBlue
                .withValues(
          alpha:
              0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            size:
                12,

            color:
                AppColors.materialSky,
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


class _StateView
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          26,
        ),

        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              icon,

              size:
                  48,

              color:
                  AppColors.skyBlue
                      .withValues(
                alpha:
                    0.75,
              ),
            ),

            const SizedBox(
              height:
                  13,
            ),

            Text(
              title,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    16,

                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height:
                  7,
            ),

            Text(
              message,

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withValues(
                  alpha:
                      0.48,
                ),

                fontSize:
                    11,

                height:
                    1.4,
              ),
            ),

            if (
              actionLabel !=
                  null &&
              onAction !=
                  null
            ) ...[
              const SizedBox(
                height:
                    15,
              ),

              OutlinedButton(
                onPressed:
                    onAction,

                child:
                    Text(
                  actionLabel!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _ReportResult {
  final String reason;
  final String description;

  const _ReportResult({
    required this.reason,
    required this.description,
  });
}