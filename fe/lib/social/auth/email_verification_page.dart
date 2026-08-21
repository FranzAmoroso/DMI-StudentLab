import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_security_api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/nightTheme.dart';
import '../social_models.dart';

class EmailVerificationPage extends StatefulWidget {
  final String registrationId;
  final String email;
  final int expiresIn;
  final String currentPassword;
  final SocialProfileDraft? draft;

  const EmailVerificationPage({
    super.key,
    required this.registrationId,
    required this.email,
    required this.expiresIn,
    required this.currentPassword,
    this.draft,
  });

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState
    extends State<EmailVerificationPage> {
  final AuthService _authService =
      AuthService();
  final AccountSecurityApiService
      _securityService =
      AccountSecurityApiService();
  final TextEditingController
      _codeController =
      TextEditingController();

  Timer? _timer;
  late String _registrationId;
  late String _email;
  late String _currentPassword;
  late int _remainingSeconds;

  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _registrationId =
        widget.registrationId;
    _email = widget.email;
    _currentPassword =
        widget.currentPassword;
    _remainingSeconds =
        widget.expiresIn < 0
            ? 0
            : widget.expiresIn;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    if (_remainingSeconds <= 0) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();
          setState(() {
            _remainingSeconds = 0;
          });
          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  String get _remainingTimeLabel {
    final int minutes =
        _remainingSeconds ~/ 60;
    final int seconds =
        _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (_verifying) {
      return;
    }

    final String code =
        _codeController.text.trim();

    if (code.length != 6 ||
        int.tryParse(code) == null) {
      setState(() {
        _error =
            'Inserisci il codice di verifica di 6 cifre ricevuto via email.';
        _message = null;
      });
      return;
    }

    if (_remainingSeconds <= 0) {
      setState(() {
        _error =
            'Il codice è scaduto. Richiedi un nuovo codice per continuare.';
        _message = null;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
      _message = null;
    });

    try {
      final SocialUser user =
          await _authService.verifyEmail(
        registrationId:
            _registrationId,
        code: code,
        draft: widget.draft,
      );

      if (!mounted) {
        return;
      }

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
            _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resending) {
      return;
    }

    setState(() {
      _resending = true;
      _error = null;
      _message = null;
    });

    try {
      final AuthVerificationResendResult
          result =
          await _authService
              .resendVerificationCode(
        registrationId:
            _registrationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _registrationId =
            result.registrationId;
        _email = result.email;
        _remainingSeconds =
            result.expiresIn;
        _codeController.clear();
        _message = result.message;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  Future<void> _changeEmail() async {
    final TextEditingController
        emailController =
        TextEditingController(
      text: _email,
    );
    final TextEditingController
        passwordController =
        TextEditingController(
      text: _currentPassword,
    );

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
        title:
            const Text('Modifica email'),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            TextField(
              controller:
                  emailController,
              keyboardType:
                  TextInputType
                      .emailAddress,
              decoration:
                  const InputDecoration(
                labelText:
                    'Nuova email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Password corrente',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child:
                const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child:
                const Text('Aggiorna'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      emailController.dispose();
      passwordController.dispose();
      return;
    }

    final String newEmail =
        emailController.text.trim();
    final String password =
        passwordController.text;
    emailController.dispose();
    passwordController.dispose();

    try {
      final PendingRegistrationUpdateResult
          result =
          await _securityService
              .changePendingRegistrationEmail(
        registrationId:
            _registrationId,
        currentPassword:
            password,
        newEmail:
            newEmail,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _registrationId =
            result.registrationId;
        _email = result.email;
        _currentPassword =
            password;
        _remainingSeconds =
            result.expiresIn ?? 0;
        _codeController.clear();
        _message =
            result.message;
        _error = null;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            _cleanError(e);
        _message = null;
      });
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController
        currentController =
        TextEditingController(
      text: _currentPassword,
    );
    final TextEditingController
        newController =
        TextEditingController();
    final TextEditingController
        confirmController =
        TextEditingController();

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
        title:
            const Text('Modifica password'),
        content:
            SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller:
                    currentController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Password attuale',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    newController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nuova password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Conferma nuova password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child:
                const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child:
                const Text('Aggiorna'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
      return;
    }

    final String currentPassword =
        currentController.text;
    final String newPassword =
        newController.text;
    final String confirmPassword =
        confirmController.text;

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (newPassword.length < 8) {
      setState(() {
        _error =
            'La nuova password deve contenere almeno 8 caratteri.';
      });
      return;
    }

    if (newPassword !=
        confirmPassword) {
      setState(() {
        _error =
            'Le password non coincidono.';
      });
      return;
    }

    try {
      final PendingRegistrationUpdateResult
          result =
          await _securityService
              .changePendingRegistrationPassword(
        registrationId:
            _registrationId,
        currentPassword:
            currentPassword,
        newPassword:
            newPassword,
        confirmPassword:
            confirmPassword,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPassword =
            newPassword;
        _message =
            result.message;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            _cleanError(e);
        _message = null;
      });
    }
  }

  String _cleanError(
    Object error,
  ) {
    String value =
        error.toString();

    if (value.startsWith(
      'Exception: ',
    )) {
      value =
          value.substring(11);
    }

    return value;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool expired =
        _remainingSeconds <= 0;

    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor:
            AppColors.brandNightBlue,
        foregroundColor:
            AppColors.pureWhite,
        title:
            const Text('Verifica email'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons
                        .mark_email_read_outlined,
                    color:
                        AppColors.skyBlue,
                    size: 58,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Controlla la tua email',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          AppColors.pureWhite,
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Abbiamo inviato un codice a $_email',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          AppColors.pureWhite
                              .withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expired
                        ? 'Il codice non è più valido.'
                        : 'Codice valido ancora per $_remainingTimeLabel',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          expired
                              ? Colors
                                  .orangeAccent
                              : AppColors
                                  .materialSky,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller:
                        _codeController,
                    enabled:
                        !_verifying,
                    keyboardType:
                        TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                      LengthLimitingTextInputFormatter(
                        6,
                      ),
                    ],
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          AppColors.pureWhite,
                      fontSize: 22,
                      letterSpacing: 8,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Codice di verifica',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style:
                          const TextStyle(
                        color:
                            Colors.redAccent,
                      ),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      style:
                          const TextStyle(
                        color:
                            Colors.greenAccent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed:
                          _verifying ||
                                  expired
                              ? null
                              : _verify,
                      child: Text(
                        _verifying
                            ? 'Verifica...'
                            : 'Verifica email',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _resending
                            ? null
                            : _resend,
                    child: Text(
                      _resending
                          ? 'Invio...'
                          : 'Reinvia codice',
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Hai inserito un dato sbagliato?',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          AppColors.pureWhite
                              .withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _changeEmail,
                    icon: const Icon(
                      Icons.email_outlined,
                    ),
                    label:
                        const Text(
                      'Modifica email',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _changePassword,
                    icon: const Icon(
                      Icons.password_outlined,
                    ),
                    label:
                        const Text(
                      'Modifica password',
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
