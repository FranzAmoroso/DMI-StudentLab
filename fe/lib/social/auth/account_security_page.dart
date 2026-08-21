import 'package:flutter/material.dart';

import '../../services/account_security_api_service.dart';
import '../../services/auth_service.dart';
import '../../services/auth_session.dart';
import '../../theme/nightTheme.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({
    super.key,
  });

  @override
  State<AccountSecurityPage> createState() =>
      _AccountSecurityPageState();
}

class _AccountSecurityPageState
    extends State<AccountSecurityPage> {
  final AccountSecurityApiService
      _securityService =
      AccountSecurityApiService();
  final AuthService _authService =
      AuthService();

  bool _loading = false;

  Future<void> _changePassword() async {
    final TextEditingController
        currentController =
        TextEditingController();
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
      _showMessage(
        'La nuova password deve contenere almeno 8 caratteri.',
      );
      return;
    }

    if (newPassword !=
        confirmPassword) {
      _showMessage(
        'Le password non coincidono.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final String message =
          await _securityService
              .changePassword(
        currentPassword:
            currentPassword,
        newPassword:
            newPassword,
        confirmPassword:
            confirmPassword,
      );

      if (!mounted) return;
      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeEmail() async {
    final TextEditingController
        emailController =
        TextEditingController();
    final TextEditingController
        passwordController =
        TextEditingController();

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
                    'Password attuale',
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
                const Text('Invia codice'),
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

    if (newEmail.isEmpty) {
      _showMessage(
        'Inserisci la nuova email.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final EmailChangeStartResult
          result =
          await _securityService
              .startEmailChange(
        currentPassword:
            password,
        newEmail:
            newEmail,
      );

      if (!mounted) return;

      await _verifyNewEmail(
        requestId:
            result.requestId,
        email:
            result.newEmail,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyNewEmail({
    required String requestId,
    required String email,
  }) async {
    final TextEditingController
        codeController =
        TextEditingController();

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          AlertDialog(
        title:
            const Text('Verifica nuova email'),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              'Inserisci il codice inviato a $email.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  codeController,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              decoration:
                  const InputDecoration(
                labelText:
                    'Codice di verifica',
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
                const Text('Verifica'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      codeController.dispose();
      return;
    }

    final String code =
        codeController.text.trim();
    codeController.dispose();

    try {
      final String updatedEmail =
          await _securityService
              .completeEmailChange(
        requestId:
            requestId,
        code: code,
      );

      await _authService
          .refreshCurrentUser();

      if (!mounted) return;

      _showMessage(
        'Email aggiornata: $updatedEmail',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        _cleanError(e),
      );
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

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final String email =
        AuthSession.instance
                .currentUser
                ?.email ??
            '';

    return Scaffold(
      backgroundColor:
          AppColors.darkElegance,
      appBar: AppBar(
        backgroundColor:
            AppColors.brandNightBlue,
        foregroundColor:
            AppColors.pureWhite,
        title:
            const Text(
          'Account e sicurezza',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 620,
            ),
            child: ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              children: [
                ListTile(
                  tileColor:
                      AppColors
                          .eleganceMidnight,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  leading:
                      const Icon(
                    Icons.email_outlined,
                    color:
                        AppColors.skyBlue,
                  ),
                  title:
                      const Text(
                    'Email',
                    style: TextStyle(
                      color:
                          AppColors
                              .pureWhite,
                    ),
                  ),
                  subtitle:
                      Text(
                    email.isEmpty
                        ? 'Email account'
                        : email,
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),
                  trailing:
                      const Icon(
                    Icons.chevron_right,
                    color:
                        Colors.white54,
                  ),
                  onTap:
                      _loading
                          ? null
                          : _changeEmail,
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor:
                      AppColors
                          .eleganceMidnight,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  leading:
                      const Icon(
                    Icons.password_outlined,
                    color:
                        AppColors.skyBlue,
                  ),
                  title:
                      const Text(
                    'Password',
                    style: TextStyle(
                      color:
                          AppColors
                              .pureWhite,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Modifica la password di accesso',
                    style: TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),
                  trailing:
                      const Icon(
                    Icons.chevron_right,
                    color:
                        Colors.white54,
                  ),
                  onTap:
                      _loading
                          ? null
                          : _changePassword,
                ),
                if (_loading) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
