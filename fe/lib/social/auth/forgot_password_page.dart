import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';
import '../../services/account_security_api_service.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();
  final AccountSecurityApiService _service =
      AccountSecurityApiService();

  late final TextEditingController
      _emailController;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(
      text: widget.initialEmail,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading ||
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final PasswordResetStartResult result =
          await _service.startPasswordReset(
        email:
            _emailController.text.trim(),
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordPage(
            requestId:
                result.requestId,
            email:
                _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    String value = error.toString();
    if (value.startsWith('Exception: ')) {
      value = value.substring(11);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor:
            AppColors.brandNightBlue,
        foregroundColor:
            AppColors.pureWhite,
        title:
            const Text('Recupera password'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      color:
                          AppColors.skyBlue,
                      size: 58,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Password dimenticata?',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            AppColors.pureWhite,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inserisci l’email del tuo account. Se esiste, StudentLab invierà un codice di recupero.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            AppColors.pureWhite
                                .withValues(
                          alpha: 0.55,
                        ),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller:
                          _emailController,
                      enabled: !_loading,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      autofillHints:
                          const [
                        AutofillHints.email,
                      ],
                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,
                      ),
                      validator: (value) {
                        final String email =
                            value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Inserisci la tua email';
                        }
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'Inserisci una email valida';
                        }
                        return null;
                      },
                      decoration:
                          const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
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
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _loading
                                ? null
                                : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .mark_email_read_outlined,
                              ),
                        label: Text(
                          _loading
                              ? 'Invio...'
                              : 'Invia codice',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
