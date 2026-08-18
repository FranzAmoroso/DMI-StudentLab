import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

import '../../services/auth_service.dart';

import '../social_models.dart';









class LoginPage extends StatefulWidget {

  const LoginPage({

super.key,

  });





  @override

  State<LoginPage> createState() =>

      _LoginPageState();

}









class _LoginPageState

    extends State<LoginPage> {

  final GlobalKey<FormState> _formKey =

      GlobalKey<FormState>();





  final AuthService _authService =

      AuthService();









  final TextEditingController

      _emailController =

      TextEditingController();

  final TextEditingController

      _passwordController =

      TextEditingController();









  bool _loading =

      false;

  bool _passwordVisible =

      false;

  String? _error;









  @override

  void dispose() {

    _emailController.dispose();

    _passwordController.dispose();

super.dispose();

  }









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
      final AuthLoginResult result =
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

      final SocialUser? authenticatedUser =
          result.user;

      if (authenticatedUser != null) {
        Navigator.pop(
          context,
          authenticatedUser,
        );

        return;
      }

      if (
        result.emailVerificationRequired
      ) {
        final String? registrationId =
            result.registrationId;

        final String? email =
            result.email;

        if (
          registrationId == null ||
          registrationId.isEmpty ||
          email == null ||
          email.isEmpty
        ) {
          throw Exception(
            'Impossibile riprendere la verifica email.',
          );
        }

        final SocialUser? verifiedUser =
            await Navigator.of(
          context,
        ).push<SocialUser>(
          MaterialPageRoute(
            builder:
                (_) =>
                    _LoginEmailVerificationPage(
              registrationId:
                  registrationId,
              email:
                  email,
              expiresIn:
                  result.expiresIn,
            ),
          ),
        );

        if (
          !mounted ||
          verifiedUser == null
        ) {
          return;
        }

        Navigator.pop(
          context,
          verifiedUser,
        );

        return;
      }

      throw Exception(
        'Non è stato possibile completare l’accesso.',
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





  String _cleanErrorMessage(

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

            'invalid credentials',

          ) ||

          message.contains(

            'incorrect password',

          ) ||

          message.contains(

            'credenzial',

          )

    ) {

      return 'Email o password non corretti. Controlla i dati inseriti e riprova.';

    }
if (

      message.contains(

            '403',

          ) ||

          message.contains(

            'forbidden',

          ) ||

          message.contains(

            'disabled',

          ) ||

          message.contains(

            'inactive',

          ) ||

          message.contains(

            'disabilitat',

          )

    ) {

      return 'Questo account non è attualmente disponibile. Contatta l’assistenza StudentLab se ritieni che si tratti di un errore.';

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

            'timeout',

          ) ||

          message.contains(

            'host lookup',

          )

    ) {

      return 'Non è stato possibile contattare StudentLab. Controlla la connessione e riprova.';

    }





    if (

      message.contains(

            '429',

          ) ||

          message.contains(

            'too many',

          )

    ) {

      return 'Sono stati effettuati troppi tentativi di accesso. Attendi qualche momento e riprova.';

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

          ) ||

          message.contains(

            'server',

          )

    ) {

      return 'StudentLab non è temporaneamente disponibile. Riprova tra qualche momento.';

    }





    return 'Non è stato possibile effettuare l’accesso. Controlla i dati inseriti e riprova.';

  }









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









  String? _validatePassword(

    String? value,

  ) {

    if (value == null ||

        value.isEmpty) {

      return 'Inserisci la password';

    }





    return null;

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

          'Accedi',

        ),

      ),









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

                  "Errore durante l'accesso.",

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


class _LoginEmailVerificationPage
    extends StatefulWidget {
  final String registrationId;

  final String email;

  final int expiresIn;


  const _LoginEmailVerificationPage({
    required this.registrationId,
    required this.email,
    required this.expiresIn,
  });


  @override
  State<_LoginEmailVerificationPage>
      createState() =>
          _LoginEmailVerificationPageState();
}


class _LoginEmailVerificationPageState
    extends State<_LoginEmailVerificationPage> {
  final AuthService _authService =
      AuthService();

  final TextEditingController
      _codeController =
      TextEditingController();

  Timer? _timer;

  late String _registrationId;

  late String _email;

  late int _remainingSeconds;

  bool _verifying =
      false;

  bool _resending =
      false;

  String? _error;

  String? _message;


  @override
  void initState() {
    super.initState();

    _registrationId =
        widget.registrationId;

    _email =
        widget.email;

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

    _timer =
        Timer.periodic(
      const Duration(
        seconds:
            1,
      ),
      (
        Timer timer,
      ) {
        if (!mounted) {
          timer.cancel();

          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();

          setState(() {
            _remainingSeconds =
                0;
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
        _remainingSeconds ~/
            60;

    final int seconds =
        _remainingSeconds %
            60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }


  Future<void> _verify() async {
    if (_verifying) {
      return;
    }

    final String code =
        _codeController.text
            .trim();

    if (
      code.length != 6 ||
      int.tryParse(
            code,
          ) ==
          null
    ) {
      setState(() {
        _error =
            'Inserisci il codice di verifica di 6 cifre ricevuto via email.';
        _message =
            null;
      });

      return;
    }

    if (_remainingSeconds <= 0) {
      setState(() {
        _error =
            'Il codice è scaduto. Richiedi un nuovo codice per continuare.';
        _message =
            null;
      });

      return;
    }

    setState(() {
      _verifying =
          true;

      _error =
          null;

      _message =
          null;
    });

    try {
      final SocialUser user =
          await _authService.verifyEmail(
        registrationId:
            _registrationId,
        code:
            code,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        user,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            _verificationErrorMessage(
          error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifying =
              false;
        });
      }
    }
  }


  Future<void> _resend() async {
    if (_resending) {
      return;
    }

    setState(() {
      _resending =
          true;

      _error =
          null;

      _message =
          null;
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

      _codeController.clear();

      setState(() {
        _registrationId =
            result.registrationId;

        _email =
            result.email;

        _remainingSeconds =
            result.expiresIn;

        _message =
            result.message.isNotEmpty
                ? result.message
                : 'Ti abbiamo inviato un nuovo codice di verifica.';
      });

      _startTimer();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            _resendErrorMessage(
          error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending =
              false;
        });
      }
    }
  }


  String _verificationErrorMessage(
    Object error,
  ) {
    final String message =
        error
            .toString()
            .toLowerCase();

    if (
      message.contains(
            'scad',
          ) ||
      message.contains(
            'expired',
          )
    ) {
      return 'Il codice è scaduto. Richiedi un nuovo codice e riprova.';
    }

    if (
      message.contains(
            'tentativ',
          ) ||
      message.contains(
            'attempt',
          )
    ) {
      return 'Sono stati effettuati troppi tentativi. Richiedi un nuovo codice.';
    }

    if (
      message.contains(
            'codice',
          ) ||
      message.contains(
            'code',
          ) ||
      message.contains(
            'invalid',
          ) ||
      message.contains(
            'incorrect',
          )
    ) {
      return 'Il codice inserito non è corretto. Controllalo e riprova.';
    }

    return 'Non è stato possibile verificare l’email. Riprova.';
  }


  String _resendErrorMessage(
    Object error,
  ) {
    final String message =
        error
            .toString()
            .toLowerCase();

    if (
      message.contains(
            'attendi',
          ) ||
      message.contains(
            'cooldown',
          ) ||
      message.contains(
            '429',
          )
    ) {
      return 'Hai richiesto un nuovo codice da poco. Attendi prima di riprovare.';
    }

    return 'Non è stato possibile inviare un nuovo codice. Riprova.';
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
          'Verifica email',
        ),
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  500,
            ),

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              children: [
                const SizedBox(
                  height:
                      24,
                ),

                const Icon(
                  Icons
                      .mark_email_read_outlined,

                  color:
                      AppColors.skyBlue,

                  size:
                      58,
                ),

                const SizedBox(
                  height:
                      20,
                ),

                const Text(
                  'Email da verificare',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        22,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Text(
                  _remainingSeconds > 0
                      ? 'Inserisci il codice di 6 cifre inviato a $_email.'
                      : 'Il codice precedente non è più valido. Richiedi un nuovo codice per $_email.',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.58,
                    ),

                    fontSize:
                        13,

                    height:
                        1.4,
                  ),
                ),

                const SizedBox(
                  height:
                      26,
                ),

                TextField(
                  controller:
                      _codeController,

                  enabled:
                      !_verifying &&
                      _remainingSeconds >
                          0,

                  keyboardType:
                      TextInputType.number,

                  textAlign:
                      TextAlign.center,

                  maxLength:
                      6,

                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,

                    LengthLimitingTextInputFormatter(
                      6,
                    ),
                  ],

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        24,

                    fontWeight:
                        FontWeight.w700,

                    letterSpacing:
                        10,
                  ),

                  decoration:
                      InputDecoration(
                    counterText:
                        '',

                    hintText:
                        '000000',

                    filled:
                        true,

                    fillColor:
                        AppColors.eleganceMidnight,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  onSubmitted:
                      (_) {
                    _verify();
                  },
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Text(
                  _remainingSeconds > 0
                      ? 'Scadenza: $_remainingTimeLabel'
                      : 'Codice scaduto',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        _remainingSeconds > 0
                            ? AppColors.pureWhite
                                .withOpacity(
                                0.42,
                              )
                            : Colors.amber,

                    fontSize:
                        11,
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(
                    height:
                        16,
                  ),

                  _LoginVerificationMessage(
                    text:
                        _error!,

                    isError:
                        true,
                  ),
                ],

                if (_message != null) ...[
                  const SizedBox(
                    height:
                        16,
                  ),

                  _LoginVerificationMessage(
                    text:
                        _message!,

                    isError:
                        false,
                  ),
                ],

                const SizedBox(
                  height:
                      24,
                ),

                SizedBox(
                  height:
                      52,

                  child:
                      ElevatedButton(
                    onPressed:
                        _verifying ||
                                _remainingSeconds <=
                                    0
                            ? null
                            : _verify,

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

                    child:
                        _verifying
                            ? const SizedBox(
                                width:
                                    20,

                                height:
                                    20,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,

                                  color:
                                      AppColors.pureWhite,
                                ),
                              )
                            : const Text(
                                'Verifica email',
                              ),
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                TextButton(
                  onPressed:
                      _resending
                          ? null
                          : _resend,

                  child:
                      _resending
                          ? const SizedBox(
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
                          : const Text(
                              'Invia un nuovo codice',
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _LoginVerificationMessage
    extends StatelessWidget {
  final String text;

  final bool isError;


  const _LoginVerificationMessage({
    required this.text,
    required this.isError,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    final Color color =
        isError
            ? Colors.redAccent
            : Colors.greenAccent;

    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
          0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              color.withOpacity(
            0.20,
          ),
        ),
      ),

      child:
          Text(
        text,

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
    );
  }
}
