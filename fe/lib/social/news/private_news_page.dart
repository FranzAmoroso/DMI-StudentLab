import 'package:flutter/material.dart';

import '../../services/auth_session.dart';
import '../../services/news_report_api_service.dart';
import '../../services/private_news_crypto.dart';
import '../../services/private_news_messenger.dart';
import '../../theme/nightTheme.dart';
import 'models/news_report.dart';

class PrivateNewsPage extends StatefulWidget {
  const PrivateNewsPage({
    super.key,
    this.messenger,
    this.reportApi,
  });

  final PrivateNewsMessenger? messenger;

  final NewsReportApiService? reportApi;

  @override
  State<PrivateNewsPage> createState() => _PrivateNewsPageState();
}

class _PrivateNewsPageState extends State<PrivateNewsPage> {
  late final PrivateNewsMessenger _messenger =
      widget.messenger ?? PrivateNewsMessenger();

  late final NewsReportApiService _reportApi =
      widget.reportApi ?? NewsReportApiService();

  List<PrivateConversationMessage> _messages = <PrivateConversationMessage>[];

  bool _loading = true;

  bool _loadingMore = false;

  String? _error;

  int _offset = 0;

  static const int _limit = 30;

  int? get _currentUserId => AuthSession.instance.currentUserId;

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
      _loading = true;
      _error = null;
      _offset = 0;
    });

    try {
      final List<PrivateConversationMessage> messages =
          await _messenger.inbox(
        limit: _limit,
        offset: 0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = messages;
        _offset = messages.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _friendlyMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _messages.length < _offset) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final List<PrivateConversationMessage> more = await _messenger.inbox(
        limit: _limit,
        offset: _offset,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = <PrivateConversationMessage>[..._messages, ...more];
        _offset += more.length;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingMore = false;
      });

      _showMessage(_friendlyMessage(error));
    }
  }

  Future<void> _reply(PrivateConversationMessage message) async {
    final int? viewerId = _currentUserId;

    if (viewerId == null) {
      return;
    }

    final String? text = await _askText(
      title: 'Rispondi a ${message.counterpartName(viewerId)}',
      hint: 'Scrivi il messaggio cifrato',
    );

    if (text == null || text.trim().isEmpty) {
      return;
    }

    try {
      await _messenger.send(
        recipientId: message.counterpartId(viewerId),
        text: text,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Messaggio cifrato e inviato.');

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_friendlyMessage(error));
    }
  }

  Future<void> _delete(PrivateConversationMessage message) async {
    final int? viewerId = _currentUserId;

    if (viewerId == null) {
      return;
    }

    final bool confirmed = await _confirm(
      title: 'Eliminare il messaggio?',
      message:
          'Il messaggio verrà rimosso dal server. Le copie già scaricate su '
          'altri dispositivi non sono recuperabili da qui.',
      confirmLabel: 'Elimina',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _messenger.delete(
        otherUserId: message.counterpartId(viewerId),
        message: message,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = _messages
            .where(
              (PrivateConversationMessage item) => item.id != message.id,
            )
            .toList();
      });

      _showMessage('Messaggio eliminato.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_friendlyMessage(error));
    }
  }

  Future<void> _report(PrivateConversationMessage message) async {
    final int? viewerId = _currentUserId;

    if (viewerId == null) {
      return;
    }

    if (!message.isReadable) {
      _showMessage(
        'Puoi segnalare questo messaggio solo dal dispositivo su cui è '
        'leggibile: serve la sua chiave per rendere la segnalazione '
        'verificabile.',
      );

      return;
    }

    final _ReportRequest? request = await showDialog<_ReportRequest>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const _ReportConsentDialog();
      },
    );

    if (request == null) {
      return;
    }

    try {
      final String contentKey = await _messenger.discloseContentKey(message);

      await _reportApi.reportPrivateMessage(
        otherUserId: message.counterpartId(viewerId),
        newsId: message.id,
        reason: request.reason,
        disclosedContentKey: contentKey,
        description: request.description,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Segnalazione inviata. I moderatori possono leggere solo questo '
        'messaggio.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_friendlyMessage(error));
    }
  }

  Future<String?> _askText({
    required String title,
    required String hint,
  }) async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: Text(
            title,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(color: AppColors.pureWhite),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.42),
              ),
              filled: true,
              fillColor: AppColors.brandNightBlue,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controller.text,
              ),
              child: const Text(
                'Invia',
                style: TextStyle(color: AppColors.skyBlue),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: Text(
            title,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.pureWhite.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                confirmLabel,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.brandNightBlue,
      ),
    );
  }

  String _friendlyMessage(Object error) {
    if (error is PrivateNewsCryptoException) {
      return error.message;
    }

    if (error is StateError) {
      return error.message;
    }

    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Richiesta non valida.';
    }

    return 'Operazione non riuscita. Riprova più tardi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        title: const Text('Comunicazioni private'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _StateView(
        icon: Icons.error_outline_rounded,
        title: 'Impossibile caricare le comunicazioni',
        message: _error!,
        actionLabel: 'Riprova',
        onAction: _load,
      );
    }

    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            _StateView(
              icon: Icons.lock_outline_rounded,
              title: 'Nessuna comunicazione privata',
              message:
                  'I messaggi privati sono cifrati end-to-end: solo i tuoi '
                  'dispositivi e quelli del destinatario possono leggerli.',
            ),
          ],
        ),
      );
    }

    final int viewerId = _currentUserId ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 220) {
            _loadMore();
          }

          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _messages.length + 1,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            if (index == _messages.length) {
              return _loadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const SizedBox(height: 6);
            }

            final PrivateConversationMessage message = _messages[index];

            return _PrivateMessageCard(
              message: message,
              viewerId: viewerId,
              onReply: viewerId == 0 ? null : () => _reply(message),
              onDelete: message.canDelete ? () => _delete(message) : null,
              onReport: message.isMine(viewerId) || viewerId == 0
                  ? null
                  : () => _report(message),
            );
          },
        ),
      ),
    );
  }
}

class _PrivateMessageCard extends StatelessWidget {
  const _PrivateMessageCard({
    required this.message,
    required this.viewerId,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  final PrivateConversationMessage message;
  final int viewerId;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isMine(viewerId);
    final String counterpart = message.counterpartName(viewerId);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: mine
            ? AppColors.socialBlue.withValues(alpha: 0.12)
            : AppColors.eleganceMidnight,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: mine
              ? AppColors.socialBlue.withValues(alpha: 0.30)
              : AppColors.skyBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.brandNightBlue,
                child: Text(
                  _initials(mine ? 'Tu' : counterpart),
                  style: const TextStyle(
                    color: AppColors.skyBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mine ? 'Tu → $counterpart' : counterpart,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(message.createdAt),
                      style: TextStyle(
                        color: AppColors.pureWhite.withValues(alpha: 0.48),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const _EncryptedBadge(),
            ],
          ),
          const SizedBox(height: 13),
          if (message.isReadable)
            Text(
              message.text,
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.45,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandNightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_person_outlined,
                    size: 18,
                    color: AppColors.pureWhite.withValues(alpha: 0.52),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Messaggio non leggibile su questo dispositivo: '
                      'è stato cifrato per altri dispositivi.',
                      style: TextStyle(
                        color: AppColors.pureWhite.withValues(alpha: 0.58),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onReport != null)
                TextButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Segnala'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.pureWhite.withValues(
                      alpha: 0.66,
                    ),
                  ),
                ),
              if (onReply != null)
                TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Rispondi'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.skyBlue,
                  ),
                ),
              if (onDelete != null)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Elimina'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _ReportRequest {
  const _ReportRequest({
    required this.reason,
    required this.description,
  });

  final String reason;
  final String description;
}

class _ReportConsentDialog extends StatefulWidget {
  const _ReportConsentDialog();

  @override
  State<_ReportConsentDialog> createState() => _ReportConsentDialogState();
}

class _ReportConsentDialogState extends State<_ReportConsentDialog> {
  final TextEditingController _description = TextEditingController();

  String _reason = 'harassment';

  bool _consent = false;

  @override
  void dispose() {
    _description.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.eleganceDeepNavy,
      title: const Text(
        'Segnala messaggio',
        style: TextStyle(color: AppColors.pureWhite),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandNightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Questo messaggio è cifrato: nessuno, nemmeno StudentLab, '
                'può leggerlo. Segnalandolo, e solo se acconsenti qui '
                'sotto, la chiave di questo singolo messaggio viene inviata '
                'ai moderatori, che potranno leggerlo. Gli altri messaggi '
                'della conversazione restano illeggibili.',
                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.70),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Motivo',
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              dropdownColor: AppColors.brandNightBlue,
              style: const TextStyle(color: AppColors.pureWhite),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.brandNightBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: NewsReportReasons.labels.entries
                  .map(
                    (MapEntry<String, String> entry) =>
                        DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _reason = value;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              maxLength: NewsReportApiService.maxDescriptionLength,
              style: const TextStyle(color: AppColors.pureWhite),
              decoration: InputDecoration(
                hintText: 'Dettagli per i moderatori (facoltativo)',
                hintStyle: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.42),
                ),
                filled: true,
                fillColor: AppColors.brandNightBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            CheckboxListTile(
              value: _consent,
              onChanged: (bool? value) {
                setState(() {
                  _consent = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.socialBlue,
              title: Text(
                'Acconsento a rendere leggibile ai moderatori il contenuto '
                'di questo messaggio.',
                style: TextStyle(
                  color: AppColors.pureWhite.withValues(alpha: 0.78),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: _consent
              ? () => Navigator.pop(
                    context,
                    _ReportRequest(
                      reason: _reason,
                      description: _description.text,
                    ),
                  )
              : null,
          child: const Text(
            'Invia segnalazione',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class _EncryptedBadge extends StatelessWidget {
  const _EncryptedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.materialSky.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: AppColors.materialSky,
          ),
          const SizedBox(width: 5),
          const Text(
            'E2E',
            style: TextStyle(
              color: AppColors.materialSky,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 46,
              color: AppColors.skyBlue.withValues(alpha: 0.72),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.60),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
