import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/auth_service.dart';

import '../social_models.dart';


// =============================================================================
// LOGIN PAGE
// =============================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });


  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}


// =============================================================================
// STATE
// =============================================================================

class _LoginPageState
    extends State<LoginPage> {

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();


  final AuthService _authService =
      AuthService();


  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();


  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _loading =
      false;

  bool _passwordVisible =
      false;

  String? _error;


  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }


  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> _login() async {
    if (_loading) {
      return;
    }


    if (!_formKey.currentState!
        .validate()) {
      return;
    }


    setState(() {
      _loading =
          true;

      _error =
          null;
    });


    try {
      final SocialUser user =
          await _authService.login(
        email:
            _emailController.text
                .trim(),

        password:
            _passwordController.text,
      );


      if (!mounted) {
        return;
      }


      // Restituiamo l'utente autenticato
      // alla pagina che ha aperto LoginPage.
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
            _cleanErrorMessage(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading =
              false;
        });
      }
    }
  }


  // ===========================================================================
  // CLEAN ERROR
  // ===========================================================================

  String _cleanErrorMessage(
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
  // EMAIL VALIDATION
  // ===========================================================================

  String? _validateEmail(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Inserisci la tua email';
    }


    final String email =
        value.trim();


    final RegExp emailRegex =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );


    if (!emailRegex.hasMatch(
      email,
    )) {
      return 'Inserisci una email valida';
    }


    return null;
  }


  // ===========================================================================
  // PASSWORD VALIDATION
  // ===========================================================================

  String? _validatePassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Inserisci la password';
    }


    return null;
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
          'Accedi',
        ),
      ),


      // =========================================================================
      // BODY
      // =========================================================================

      body:
          SafeArea(
        child:
            Center(
          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final double width =
                  constraints.maxWidth >
                          600
                      ? 500
                      : constraints
                          .maxWidth;


              return SizedBox(
                width:
                    width,

                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child:
                      Form(
                    key:
                        _formKey,

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,

                      children: [
                        const SizedBox(
                          height:
                              25,
                        ),


                        // =====================================================
                        // ICON
                        // =====================================================

                        Center(
                          child: Container(
                            width: 78,
                            height: 78,

                            decoration: BoxDecoration(
                              color: AppColors.brandNightBlue,

                              borderRadius:
                                  BorderRadius.circular(24),

                              border: Border.all(
                                color: AppColors.skyBlue
                                    .withOpacity(0.20),
                              ),
                            ),

                            child: const Icon(
                              Icons.lock_open_rounded,
                              color: AppColors.skyBlue,
                              size: 38,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:
                              24,
                        ),


                        // =====================================================
                        // TITLE
                        // =====================================================

                        const Text(
                          'Bentornato',

                          textAlign:
                              TextAlign.center,

                          style:
                              TextStyle(
                            color:
                                AppColors.pureWhite,

                            fontSize:
                                26,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),


                        Text(
                          'Accedi al tuo account StudentLab '
                          'per utilizzare le funzionalità riservate.',

                          textAlign:
                              TextAlign.center,

                          style:
                              TextStyle(
                            color:
                                AppColors.pureWhite
                                    .withOpacity(
                              0.55,
                            ),

                            fontSize:
                                13,

                            height:
                                1.4,
                          ),
                        ),

                        const SizedBox(
                          height:
                              32,
                        ),


                        // =====================================================
                        // EMAIL
                        // =====================================================

                        TextFormField(
                          controller:
                              _emailController,

                          enabled:
                              !_loading,

                          keyboardType:
                              TextInputType.emailAddress,

                          textInputAction:
                              TextInputAction.next,

                          autofillHints:
                              const [
                            AutofillHints.email,
                          ],

                          style:
                              const TextStyle(
                            color:
                                AppColors.pureWhite,
                          ),

                          validator:
                              _validateEmail,

                          decoration:
                              _decoration(
                            label:
                                'Email',

                            hint:
                                'nome@example.com',

                            icon:
                                Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(
                          height:
                              16,
                        ),


                        // =====================================================
                        // PASSWORD
                        // =====================================================

                        TextFormField(
                          controller:
                              _passwordController,

                          enabled:
                              !_loading,

                          obscureText:
                              !_passwordVisible,

                          enableSuggestions:
                              false,

                          autocorrect:
                              false,

                          textInputAction:
                              TextInputAction.done,

                          autofillHints:
                              const [
                            AutofillHints.password,
                          ],

                          style:
                              const TextStyle(
                            color:
                                AppColors.pureWhite,
                          ),

                          validator:
                              _validatePassword,

                          onFieldSubmitted:
                              (_) {
                            _login();
                          },

                          decoration:
                              _passwordDecoration(),
                        ),


                        // =====================================================
                        // ERROR
                        // =====================================================

                        if (_error !=
                            null) ...[
                          const SizedBox(
                            height:
                                18,
                          ),

                          _buildError(),
                        ],


                        const SizedBox(
                          height:
                              26,
                        ),


                        // =====================================================
                        // LOGIN BUTTON
                        // =====================================================

                        SizedBox(
                          height:
                              54,

                          child:
                              ElevatedButton.icon(
                            onPressed:
                                _loading
                                    ? null
                                    : _login,

                            icon:
                                _loading
                                    ? const SizedBox(
                                        width:
                                            18,

                                        height:
                                            18,

                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,

                                          color:
                                              AppColors.pureWhite,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.login_rounded,
                                      ),

                            label:
                                Text(
                              _loading
                                  ? 'Accesso in corso...'
                                  : 'Accedi',

                              style:
                                  const TextStyle(
                                fontSize:
                                    16,

                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.socialBlue,

                              foregroundColor:
                                  AppColors.pureWhite,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:
                              18,
                        ),


                        // =====================================================
                        // INFO
                        // =====================================================

                        Container(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                AppColors.eleganceMidnight,

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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              const Icon(
                                Icons.info_outline_rounded,

                                color:
                                    AppColors.materialSky,

                                size:
                                    19,
                              ),

                              const SizedBox(
                                width:
                                    9,
                              ),

                              Expanded(
                                child:
                                    Text(
                                  'Se non hai ancora un account, '
                                  'torna indietro e scegli Sign Up '
                                  'per creare un profilo studente '
                                  'o insegnante.',

                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.pureWhite
                                            .withOpacity(
                                      0.50,
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
                        ),

                        const SizedBox(
                          height:
                              20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  // ===========================================================================
  // ERROR CARD
  // ===========================================================================

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.redAccent
                .withOpacity(
          0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              Colors.redAccent
                  .withOpacity(
            0.22,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,

            color:
                Colors.redAccent,

            size:
                20,
          ),

          const SizedBox(
            width:
                9,
          ),

          Expanded(
            child:
                Text(
              _error ??
                  'Errore durante l\'accesso.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.75,
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
  // DECORATION
  // ===========================================================================

  InputDecoration _decoration({
    required String label,

    required String hint,

    required IconData icon,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      labelStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.60,
        ),
      ),

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.30,
        ),
      ),

      prefixIcon:
          Icon(
        icon,

        color:
            AppColors.skyBlue,
      ),

      filled:
          true,

      fillColor:
          AppColors.eleganceMidnight,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.08,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.socialBlue,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),
    );
  }


  // ===========================================================================
  // PASSWORD DECORATION
  // ===========================================================================

  InputDecoration _passwordDecoration() {
    return InputDecoration(
      labelText:
          'Password',

      hintText:
          'Inserisci la password',

      labelStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.60,
        ),
      ),

      hintStyle:
          TextStyle(
        color:
            AppColors.pureWhite
                .withOpacity(
          0.30,
        ),
      ),

      prefixIcon:
          const Icon(
        Icons.lock_outline_rounded,

        color:
            AppColors.skyBlue,
      ),

      suffixIcon:
          IconButton(
        tooltip:
            _passwordVisible
                ? 'Nascondi password'
                : 'Mostra password',

        onPressed:
            _loading
                ? null
                : () {
                    setState(() {
                      _passwordVisible =
                          !_passwordVisible;
                    });
                  },

        icon:
            Icon(
          _passwordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,

          color:
              AppColors.pureWhite
                  .withOpacity(
            0.55,
          ),
        ),
      ),

      filled:
          true,

      fillColor:
          AppColors.eleganceMidnight,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              AppColors.skyBlue
                  .withOpacity(
            0.08,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.socialBlue,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),
    );
  }
}