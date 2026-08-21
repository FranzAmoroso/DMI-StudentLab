import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/nightTheme.dart';

class UserBlockAction extends StatefulWidget {
  final int userId;
  final String userName;
  final VoidCallback? onChanged;

  const UserBlockAction({
    super.key,
    required this.userId,
    required this.userName,
    this.onChanged,
  });

  @override
  State<UserBlockAction> createState() => _UserBlockActionState();
}

class _UserBlockActionState extends State<UserBlockAction> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  bool _processing = false;
  bool _blocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> result =
          await _apiService.getUserBlockStatus(widget.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _blocked = result['blocked'] == true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggle() async {
    if (_processing) {
      return;
    }

    if (_blocked) {
      await _unblock();
    } else {
      await _block();
    }
  }

  Future<void> _block() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.eleganceDeepNavy,
          title: const Text(
            'Blocca utente',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          content: Text(
            'Vuoi bloccare ${widget.userName}? Le interazioni private tra voi '
            'verranno limitate dal server. Potrai sbloccare l’utente in qualsiasi momento.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Blocca',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await _apiService.blockUser(widget.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _blocked = true;
      });

      widget.onChanged?.call();
      _showMessage('${widget.userName} è stato bloccato.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _unblock() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await _apiService.unblockUser(widget.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _blocked = false;
      });

      widget.onChanged?.call();
      _showMessage('${widget.userName} è stato sbloccato.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 46,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _processing ? null : _toggle,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                _blocked ? AppColors.materialSky : Colors.redAccent,
            side: BorderSide(
              color: (_blocked ? AppColors.skyBlue : Colors.redAccent)
                  .withOpacity(0.35),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _processing
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _blocked
                      ? Icons.person_add_alt_1_outlined
                      : Icons.block_outlined,
                ),
          label: Text(
            _blocked ? 'Sblocca utente' : 'Blocca utente',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  String _friendlyError(Object error) {
    final String message = error.toString().toLowerCase();

    if (message.contains('401')) {
      return 'La sessione non è più valida. Accedi nuovamente.';
    }

    if (message.contains('404')) {
      return 'Questo utente non è più disponibile.';
    }

    if (message.contains('409') || message.contains('già bloccato')) {
      return 'Questo utente risulta già bloccato. Aggiorna la pagina.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('host lookup')) {
      return 'Non è stato possibile contattare StudentLab.';
    }

    return 'Non è stato possibile aggiornare il blocco utente.';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}