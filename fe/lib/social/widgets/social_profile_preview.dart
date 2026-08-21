import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/nightTheme.dart';

import '../../services/api_service.dart';

import '../../services/auth_service.dart';

import '../../services/auth_session.dart';

import '../social_models.dart';

import '../policy/studentlab_policy_page.dart';
import '../widgets/studentlab_user_avatar.dart';

class SocialProfilePreview extends StatefulWidget {

  final SocialProfileDraft draft;

  const SocialProfilePreview({

super.key,

    required this.draft,

  });

  @override

  State<SocialProfilePreview> createState() =>

      _SocialProfilePreviewState();

}

class _SocialProfilePreviewState

    extends State<SocialProfilePreview> {

  final AuthService _authService =

      AuthService();

  final ApiService _apiService =

      ApiService();

  final AuthSession _authSession =

      AuthSession.instance;

  bool _publishing =

      false;

  String? _error;

  @override

  Widget build(

    BuildContext context,

  ) {

    final SocialProfileDraft draft =

        widget.draft;

    final bool isTeacher =

        draft.type ==

            SocialUserType.teacher;

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

          'Anteprima profilo',

          style:

              TextStyle(

            fontSize:

                18,

            fontWeight:

                FontWeight.w600,

          ),

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

                          700

                      ? 650

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

                      Column(

                    crossAxisAlignment:

                        CrossAxisAlignment

                            .stretch,

                    children: [

                      const Text(

                        'Così apparirà il tuo profilo',

                        textAlign:

                            TextAlign.center,

                        style:

                            TextStyle(

                          color:

                              AppColors

                                  .pureWhite,

                          fontSize:

                              20,

                          fontWeight:

                              FontWeight

                                  .bold,

                        ),

                      ),

                      const SizedBox(

                        height:

                            8,

                      ),

                      Text(

                        'Controlla le informazioni prima di creare il tuo account StudentLab.',

                        textAlign:

                            TextAlign.center,

                        style:

                            TextStyle(

                          color:

                              AppColors

                                  .pureWhite

                                  .withOpacity(

                            0.55,

                          ),

                          fontSize:

                              13,

                        ),

                      ),

                      const SizedBox(

                        height:

                            24,

                      ),

                      _ProfileCard(

                        draft:

                            draft,

                        isTeacher:

                            isTeacher,

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

                            28,

                      ),

                      SizedBox(

                        height:

                            54,

                        child:

                            ElevatedButton

                                .icon(

                          onPressed:

                              _publishing

                                  ? null

                                  : _publishProfile,

                          icon:

                              _publishing

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

                                            AppColors

                                                .pureWhite,

                                      ),

                                    )

                                  : const Icon(

                                      Icons

                                          .check_rounded,

                                    ),

                          label:

                              Text(

                            _publishing

                                ? 'Creazione account...'

                                : 'Conferma e registrati',

                            style:

                                const TextStyle(

                              fontSize:

                                  16,

                              fontWeight:

                                  FontWeight

                                      .w600,

                            ),

                          ),

                          style:

                              ElevatedButton

                                  .styleFrom(

                            backgroundColor:

                                isTeacher

                                    ? AppColors

                                        .teacherIndigo

                                    : AppColors

                                        .socialBlue,

                            foregroundColor:

                                AppColors

                                    .pureWhite,

                            shape:

                                RoundedRectangleBorder(

                              borderRadius:

                                  BorderRadius

                                      .circular(

                                16,

                              ),

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(

                        height:

                            12,

                      ),

                      SizedBox(

                        height:

                            50,

                        child:

                            OutlinedButton

                                .icon(

                          onPressed:

                              _publishing

                                  ? null

                                  : () {

                                      Navigator

                                          .pop(

                                        context,

                                      );

                                    },

                          icon:

                              const Icon(

                            Icons

                                .edit_outlined,

                          ),

                          label:

                              const Text(

                            'Modifica profilo',

                          ),

                          style:

                              OutlinedButton

                                  .styleFrom(

                            foregroundColor:

                                AppColors

                                    .pureWhite,

                            side:

                                BorderSide(

                              color:

                                  AppColors

                                      .pureWhite

                                      .withOpacity(

                                0.20,

                              ),

                            ),

                            shape:

                                RoundedRectangleBorder(

                              borderRadius:

                                  BorderRadius

                                      .circular(

                                16,

                              ),

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(

                        height:

                            20,

                      ),

                    ],

                  ),

                ),

              );

            },

          ),

        ),

      ),

    );

  }

  Future<void> _publishProfile() async {
    if (_publishing) {
      return;
    }

    final StudentLabPolicyAcceptance?
        acceptance =
        await Navigator.push<
            StudentLabPolicyAcceptance>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const StudentLabPolicyPage(
          requireAcceptance:
              true,
        ),
      ),
    );

    if (
      acceptance == null ||
      !mounted
    ) {
      return;
    }

    setState(() {
      _publishing =
          true;
      _error =
          null;
    });

    try {
      final AuthRegistrationResult
          registration =
          await _authService.register(
        widget.draft,
        policyVersion:
            acceptance.policyVersion,
        privacyAcknowledged:
            acceptance
                .privacyAcknowledged,
        termsAccepted:
            acceptance.termsAccepted,
      );

      if (!mounted) {
        return;
      }

      SocialUser? user =
          await Navigator.push<
              SocialUser>(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  _EmailVerificationPage(
            registration:
                registration,
            draft:
                widget.draft,
          ),
        ),
      );

      if (
        user == null ||
        !mounted
      ) {
        return;
      }

      if (
        widget.draft.additionalAcademicPaths
            .isNotEmpty
      ) {
        for (
          final SocialAcademicPathDraft path
          in widget.draft.additionalAcademicPaths
        ) {
          await _apiService
              .createAcademicPath(
            university:
                path.university,
            universityCode:
                path.universityCode,
            department:
                path.department,
            departmentCode:
                path.departmentCode,
            course:
                path.course,
            courseCode:
                path.courseCode,
            degreeType:
                path.degreeType,
            status:
                path.status,
            startYear:
                path.startYear,
            graduationYear:
                path.graduationYear,
            isCurrent:
                path.isCurrent,
            isPrimary:
                path.isPrimary,
          );
        }

        user =
            await _apiService
                .getCurrentUser();

        _authSession.updateUser(
          user,
        );
      }

      if (
        widget.draft.type ==
            SocialUserType.teacher &&
        widget.draft.teacherAssignments
            .isNotEmpty
      ) {
        for (
          final TeacherAssignmentDraft
              assignment
          in widget
              .draft
              .teacherAssignments
        ) {
          await _apiService
              .createTeacherAssignment(
            subjectId:
                assignment.subjectId,
            offeringId:
                assignment.offeringId,
            isCurrent:
                assignment.isCurrent,
          );
        }

        user =
            await _apiService
                .getCurrentUser();

        _authSession.updateUser(
          user,
        );
      }

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
            _registrationErrorMessage(
          error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _publishing =
              false;
        });
      }
    }
  }


  String _registrationErrorMessage(

    Object error,

  ) {

    final String message =

        error

            .toString()

            .toLowerCase();

    if (

      message.contains(

            'email',

          ) &&

          (

            message.contains(

              'already',

            ) ||

            message.contains(

              'già',

            ) ||

            message.contains(

              'exists',

            ) ||

            message.contains(

              'esiste',

            )

          )

    ) {

      return 'Esiste già un account associato a questa email. Accedi oppure utilizza un altro indirizzo.';

    }

    if (

      message.contains(

            '14',

          ) ||

          message.contains(

            'age',

          ) ||

          message.contains(

            'età',

          ) ||

          message.contains(

            'nascita',

          )

    ) {

      return 'Non è possibile completare la registrazione perché non risultano soddisfatti i requisiti di età previsti da StudentLab.';

    }

    if (

      message.contains(

            'policy',

          ) ||

          message.contains(

            'privacy',

          ) ||

          message.contains(

            'terms',

          )

    ) {

      return 'Non è stato possibile registrare correttamente l’accettazione della Policy. Riapri il documento e riprova.';

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

            '422',

          ) ||

          message.contains(

            'validation',

          ) ||

          message.contains(

            'invalid',

          )

    ) {

      return 'Alcuni dati inseriti non risultano validi. Torna al profilo, controlla le informazioni e riprova.';

    }

    if (

      message.contains(

            '401',

          ) ||

          message.contains(

            '403',

          ) ||

          message.contains(

            'unauthorized',

          ) ||

          message.contains(

            'forbidden',

          )

    ) {

      return 'Non è stato possibile completare la registrazione. Riprova oppure torna alla schermata iniziale.';

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

    return 'Non è stato possibile creare l’account. Controlla i dati inseriti e riprova.';

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

            0.20,

          ),

        ),

      ),

      child:

          Row(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          const Icon(

            Icons

                .error_outline_rounded,

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

                  'Errore durante la registrazione.',

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite

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

}


class _EmailVerificationPage
    extends StatefulWidget {
  final AuthRegistrationResult
      registration;

  final SocialProfileDraft draft;

  const _EmailVerificationPage({
    required this.registration,
    required this.draft,
  });

  @override
  State<_EmailVerificationPage>
      createState() =>
          _EmailVerificationPageState();
}


class _EmailVerificationPageState
    extends State<_EmailVerificationPage> {
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
        widget.registration
            .registrationId;

    _email =
        widget.registration.email;

    _remainingSeconds =
        widget.registration.expiresIn;

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
          await _authService
              .verifyEmail(
        registrationId:
            _registrationId,
        code:
            code,
        draft:
            widget.draft,
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
            'expired',
          ) ||
      message.contains(
            'scad',
          )
    ) {
      return 'Il codice è scaduto. Richiedi un nuovo codice e riprova.';
    }

    if (
      message.contains(
            'code',
          ) ||
      message.contains(
            'codice',
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

    if (
      message.contains(
            'attempt',
          ) ||
      message.contains(
            'tentativ',
          ) ||
      message.contains(
            '429',
          )
    ) {
      return 'Sono stati effettuati troppi tentativi. Richiedi un nuovo codice o riprova più tardi.';
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

    return 'Non è stato possibile verificare l’email. Controlla il codice e riprova.';
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
            '429',
          ) ||
      message.contains(
            'cooldown',
          ) ||
      message.contains(
            'wait',
          ) ||
      message.contains(
            'attendi',
          )
    ) {
      return 'Hai richiesto un nuovo codice da poco. Attendi prima di riprovare.';
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

    return 'Non è stato possibile inviare un nuovo codice. Riprova.';
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isTeacher =
        widget.draft.type ==
            SocialUserType.teacher;

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
          style:
              TextStyle(
            fontSize:
                18,
            fontWeight:
                FontWeight.w600,
          ),
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
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const SizedBox(
                        height:
                            24,
                      ),
                      Container(
                        width:
                            72,
                        height:
                            72,
                        decoration:
                            BoxDecoration(
                          color:
                              (
                                isTeacher
                                    ? AppColors.teacherIndigo
                                    : AppColors.socialBlue
                              )
                                  .withOpacity(
                            0.14,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            Icon(
                          Icons
                              .mark_email_read_outlined,
                          color:
                              isTeacher
                                  ? AppColors.teacherIndigo
                                  : AppColors.materialSky,
                          size:
                              34,
                        ),
                      ),
                      const SizedBox(
                        height:
                            22,
                      ),
                      const Text(
                        'Controlla la tua email',
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
                        'Abbiamo inviato un codice di 6 cifre a $_email.',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.60,
                          ),
                          fontSize:
                              13,
                          height:
                              1.45,
                        ),
                      ),
                      const SizedBox(
                        height:
                            28,
                      ),
                      TextField(
                        controller:
                            _codeController,
                        enabled:
                            !_verifying,
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
                          hintStyle:
                              TextStyle(
                            color:
                                AppColors.pureWhite
                                    .withOpacity(
                              0.20,
                            ),
                            letterSpacing:
                                10,
                          ),
                          filled:
                              true,
                          fillColor:
                              AppColors.eleganceDeepNavy,
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  AppColors.pureWhite
                                      .withOpacity(
                                0.12,
                              ),
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  AppColors.pureWhite
                                      .withOpacity(
                                0.12,
                              ),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  isTeacher
                                      ? AppColors.teacherIndigo
                                      : AppColors.socialBlue,
                              width:
                                  1.5,
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
                            12,
                      ),
                      Text(
                        _remainingSeconds >
                                0
                            ? 'Il codice scade tra $_remainingTimeLabel'
                            : 'Il codice è scaduto',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              _remainingSeconds >
                                      0
                                  ? AppColors.pureWhite
                                      .withOpacity(
                                      0.45,
                                    )
                                  : Colors.amber,
                          fontSize:
                              11,
                        ),
                      ),
                      if (_error !=
                          null) ...[
                        const SizedBox(
                          height:
                              18,
                        ),
                        _VerificationMessage(
                          text:
                              _error!,
                          isError:
                              true,
                        ),
                      ],
                      if (_message !=
                          null) ...[
                        const SizedBox(
                          height:
                              18,
                        ),
                        _VerificationMessage(
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
                            54,
                        child:
                            ElevatedButton(
                          onPressed:
                              _verifying
                                  ? null
                                  : _verify,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                isTeacher
                                    ? AppColors.teacherIndigo
                                    : AppColors.socialBlue,
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
                                      style:
                                          TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(
                        height:
                            12,
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
              );
            },
          ),
        ),
      ),
    );
  }
}


class _VerificationMessage
    extends StatelessWidget {
  final String text;

  final bool isError;

  const _VerificationMessage({
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
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color:
                color,
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
          ),
        ],
      ),
    );
  }
}


class _ProfileCard

    extends StatelessWidget {

  final SocialProfileDraft draft;

  final bool isTeacher;

  const _ProfileCard({

    required this.draft,

    required this.isTeacher,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    final List<SocialAcademicTitleDraft> academicTitles =
        draft.resolvedAcademicTitles;

    final List<SocialAcademicPathDraft> academicPaths =
        draft.resolvedAcademicPaths;

    final bool hasDeclaredGrades =
        !isTeacher &&
        draft.subjects.any(
          (
            SocialSubject subject,
          ) =>
              subject.grade != null,
        );

    final bool hasVerificationData =
        academicTitles.isNotEmpty ||
        academicPaths.isNotEmpty ||
        hasDeclaredGrades ||
        (
          isTeacher &&
          draft.teacherAssignments.isNotEmpty
        );

    return Container(

      width:

          double.infinity,

      padding:

          const EdgeInsets.all(

        18,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .eleganceDeepNavy,

        borderRadius:

            BorderRadius.circular(

          18,

        ),

        border:

            Border.all(

          color:

              isTeacher

                  ? AppColors

                      .teacherIndigo

                      .withOpacity(

                    0.35,

                  )

                  : AppColors

                      .socialBlue

                      .withOpacity(

                    0.35,

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

              StudentLabUserAvatar(

                type:

                    draft.type,

                radius:

                    25,

              ),

              const SizedBox(

                width:

                    12,

              ),

              Expanded(

                child:

                    Column(

                  crossAxisAlignment:

                      CrossAxisAlignment

                          .start,

                  children: [

                    Text(

                      draft.name.isNotEmpty

                          ? draft.name

                          : 'Nome non inserito',

                      maxLines:

                          1,

                      overflow:

                          TextOverflow

                              .ellipsis,

                      style:

                          const TextStyle(

                        color:

                            AppColors

                                .pureWhite,

                        fontSize:

                            17,

                        fontWeight:

                            FontWeight

                                .bold,

                      ),

                    ),

                    const SizedBox(

                      height:

                          2,

                    ),

                    Text(

                      isTeacher

                          ? 'Insegnante'

                          : 'Studente',

                      style:

                          TextStyle(

                        color:

                            AppColors

                                .pureWhite

                                .withOpacity(

                          0.55,

                        ),

                        fontSize:

                            12,

                      ),

                    ),

                    const SizedBox(

                      height:

                          3,

                    ),

                    Text(

                      draft.email,

                      maxLines:

                          1,

                      overflow:

                          TextOverflow

                              .ellipsis,

                      style:

                          TextStyle(

                        color:

                            AppColors

                                .pureWhite

                                .withOpacity(

                          0.40,

                        ),

                        fontSize:

                            10,

                      ),

                    ),

                  ],

                ),

              ),

              if (draft.available)

                const _AvailableBadge(),

            ],

          ),

          const SizedBox(

            height:

                18,

          ),

          Wrap(

            spacing:

                8,

            runSpacing:

                8,

            children: [

              if (

                draft

                    .availableForHelp

              )

                const _ProfileChip(

                  icon:

                      Icons

                          .volunteer_activism_outlined,

                  label:

                      'Disponibile ad aiutare',

                ),

              if (

                draft

                    .availableForPrivateLessons

              )

                const _ProfileChip(

                  icon:

                      Icons

                          .school_outlined,

                  label:

                      'Lezioni private',

                ),

            ],

          ),

          const SizedBox(

            height:

                18,

          ),

          if (hasVerificationData) ...[
            const _PreviewVerificationNotice(),

            const SizedBox(
              height:
                  18,
            ),
          ],

          if (academicTitles.isNotEmpty) ...[
            const Text(
              'Titoli conseguiti',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  9,
            ),

            ...academicTitles.map(
              (
                SocialAcademicTitleDraft title,
              ) =>
                  Padding(
                padding:
                    const EdgeInsets.only(
                  bottom:
                      10,
                ),

                child:
                    _AcademicTitleModelPreview(
                  title:
                      title,
                ),
              ),
            ),

            const SizedBox(
              height:
                  18,
            ),
          ],

          if (academicPaths.isNotEmpty) ...[
            const Text(
              'Percorsi accademici',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite,

                fontSize:
                    13,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height:
                  9,
            ),

            ...academicPaths.map(
              (
                SocialAcademicPathDraft path,
              ) =>
                  Padding(
                padding:
                    const EdgeInsets.only(
                  bottom:
                      10,
                ),

                child:
                    _AcademicPathModelPreview(
                  path:
                      path,
                ),
              ),
            ),
          ],

          if (!isTeacher) ...[

            const SizedBox(

              height:

                  18,

            ),

            const Text(

              'Materie',

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite,

                fontSize:

                    13,

                fontWeight:

                    FontWeight.bold,

              ),

            ),

            const SizedBox(

              height:

                  9,

            ),

            if (draft.subjects.isNotEmpty)

              ...draft.subjects.map(

                (

                  SocialSubject subject,

                ) =>

                    _SubjectPreview(

                  subject:

                      subject,

                ),

              )

            else

              Text(

                'Nessuna materia inserita.',

                style:

                    TextStyle(

                  color:

                      AppColors

                          .pureWhite

                          .withOpacity(

                    0.45,

                  ),

                  fontSize:

                      13,

                ),

              ),

          ],

          if (isTeacher) ...[

            const SizedBox(

              height:

                  18,

            ),

            const Text(

              'Insegnamenti',

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite,

                fontSize:

                    13,

                fontWeight:

                    FontWeight.bold,

              ),

            ),

            const SizedBox(

              height:

                  9,

            ),

            if (

              draft.teacherAssignments

                  .isNotEmpty

            )

              ...draft.teacherAssignments

                  .map(

                (

                  TeacherAssignmentDraft

                      assignment,

                ) =>

                    _TeacherAssignmentPreview(

                  assignment:

                      assignment,

                  subjects:

                      draft.subjects,

                ),

              )

            else

              Text(

                'Nessun insegnamento inserito.',

                style:

                    TextStyle(

                  color:

                      AppColors

                          .pureWhite

                          .withOpacity(

                    0.45,

                  ),

                  fontSize:

                      13,

                ),

              ),

          ],

          if (

            draft.description

                .isNotEmpty

          ) ...[

            const SizedBox(

              height:

                  18,

            ),

            const Text(

              'Descrizione',

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite,

                fontSize:

                    13,

                fontWeight:

                    FontWeight.bold,

              ),

            ),

            const SizedBox(

              height:

                  7,

            ),

            Text(

              draft.description,

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite

                        .withOpacity(

                  0.70,

                ),

                fontSize:

                    14,

                height:

                    1.4,

              ),

            ),

          ],

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

                  AppColors

                      .brandNightBlue,

              borderRadius:

                  BorderRadius

                      .circular(

                12,

              ),

            ),

            child:

                const Row(

              children: [

                Icon(

                  Icons

                      .star_rounded,

                  color:

                      Colors.amber,

                  size:

                      20,

                ),

                SizedBox(

                  width:

                      6,

                ),

                Text(

                  'Nessuna recensione',

                  style:

                      TextStyle(

                    color:

                        AppColors

                            .pureWhite,

                    fontSize:

                        12,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}


class _AcademicTitleModelPreview
    extends StatelessWidget {
  final SocialAcademicTitleDraft title;

  const _AcademicTitleModelPreview({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AcademicTitleCard(
      degreeType:
          title.titleType,

      course:
          title.course,

      university:
          title.university,

      department:
          title.department,

      graduationYear:
          title.graduationYear,

      isPrimary:
          title.isPrimary,
    );
  }
}

class _AcademicPathModelPreview
    extends StatelessWidget {
  final SocialAcademicPathDraft path;

  const _AcademicPathModelPreview({
    required this.path,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              AppColors.skyBlue.withOpacity(
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
            children: [
              const Icon(
                Icons.account_balance_outlined,

                color:
                    AppColors.skyBlue,

                size:
                    17,
              ),

              const SizedBox(
                width:
                    7,
              ),

              Expanded(
                child:
                    Text(
                  path.university.isEmpty
                      ? 'Ateneo non specificato'
                      : path.university,

                  style:
                      const TextStyle(
                    color:
                        AppColors.pureWhite,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              const _PreviewPendingBadge(
                label:
                    'DA VERIFICARE',
              ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          _AcademicInfoRow(
            label:
                'Dipartimento',

            value:
                path.department.isEmpty
                    ? 'Non specificato'
                    : path.department,
          ),

          const SizedBox(
            height:
                7,
          ),

          _AcademicInfoRow(
            label:
                'Corso',

            value:
                path.course.isEmpty
                    ? 'Non specificato'
                    : path.course,
          ),

          const SizedBox(
            height:
                10,
          ),

          Wrap(
            spacing:
                7,

            runSpacing:
                7,

            children: [
              _AcademicStatusBadge(
                status:
                    path.status,
              ),

              if (path.startYear != null)
                _AcademicSimpleBadge(
                  label:
                      'Dal ${path.startYear}',
                ),

              if (path.isCurrent)
                const _AcademicSimpleBadge(
                  label:
                      'Corrente',
                ),

              if (path.isPrimary)
                const _AcademicSimpleBadge(
                  label:
                      'Principale',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryAcademicTitlePreview
    extends StatelessWidget {
  final SocialProfileDraft draft;

  const _PrimaryAcademicTitlePreview({
    required this.draft,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AcademicTitleCard(
      degreeType:
          draft.degreeType,

      course:
          draft.course,

      university:
          draft.university,

      department:
          draft.department,

      graduationYear:
          draft.graduationYear,

      isPrimary:
          true,
    );
  }
}

class _AcademicTitlePreview
    extends StatelessWidget {
  final SocialAcademicPathDraft path;

  const _AcademicTitlePreview({
    required this.path,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return _AcademicTitleCard(
      degreeType:
          path.degreeType,

      course:
          path.course,

      university:
          path.university,

      department:
          path.department,

      graduationYear:
          path.graduationYear,

      isPrimary:
          path.isPrimary,
    );
  }
}

class _AcademicTitleCard
    extends StatelessWidget {
  final String degreeType;
  final String course;
  final String university;
  final String department;
  final int? graduationYear;
  final bool isPrimary;

  const _AcademicTitleCard({
    required this.degreeType,
    required this.course,
    required this.university,
    required this.department,
    required this.graduationYear,
    required this.isPrimary,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String title =
        degreeType.trim().isEmpty
            ? ''
            : academicPathTypeLabel(
                degreeType,
              );

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.brandNightBlue,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              Colors.amber.withOpacity(
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
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width:
                    34,

                height:
                    34,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.amber.withOpacity(
                    0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    const Icon(
                  Icons.workspace_premium_outlined,

                  color:
                      Colors.amber,

                  size:
                      19,
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
                      title,

                      style:
                          const TextStyle(
                        color:
                            AppColors.pureWhite,

                        fontSize:
                            13,

                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    if (course.trim().isNotEmpty) ...[
                      const SizedBox(
                        height:
                            3,
                      ),

                      Text(
                        course,

                        style:
                            TextStyle(
                          color:
                              AppColors.pureWhite
                                  .withOpacity(
                            0.62,
                          ),

                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(
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
                      Colors.amber.withOpacity(
                    0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),

                child:
                    const Text(
                  'DA VERIFICARE',

                  style:
                      TextStyle(
                    color:
                        Colors.amber,

                    fontSize:
                        8,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (
            university.trim().isNotEmpty ||
            department.trim().isNotEmpty
          ) ...[
            const SizedBox(
              height:
                  10,
            ),

            Text(
              [
                if (university.trim().isNotEmpty)
                  university.trim(),
                if (department.trim().isNotEmpty)
                  department.trim(),
              ].join(
                ' • ',
              ),

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.42,
                ),

                fontSize:
                    10,
              ),
            ),
          ],

          const SizedBox(
            height:
                9,
          ),

          Wrap(
            spacing:
                7,

            runSpacing:
                7,

            children: [
              if (graduationYear != null)
                _AcademicSimpleBadge(
                  label:
                      'Conseguito $graduationYear',
                ),

              if (isPrimary)
                const _AcademicSimpleBadge(
                  label:
                      'Principale',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademicPathPreview

    extends StatelessWidget {

  final SocialProfileDraft draft;

  const _AcademicPathPreview({

    required this.draft,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    return Container(

      width:

          double.infinity,

      padding:

          const EdgeInsets.all(

        13,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .brandNightBlue,

        borderRadius:

            BorderRadius.circular(

          12,

        ),

        border:

            Border.all(

          color:

              AppColors

                  .skyBlue

                  .withOpacity(

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

            children: [

              const Icon(

                Icons

                    .account_balance_outlined,

                color:

                    AppColors

                        .skyBlue,

                size:

                    17,

              ),

              const SizedBox(

                width:

                    7,

              ),

              Expanded(

                child:

                    Text(

                  draft.university

                          .isEmpty

                      ? 'Ateneo non specificato'

                      : draft.university,

                  style:

                      const TextStyle(

                    color:

                        AppColors

                            .pureWhite,

                    fontSize:

                        12,

                    fontWeight:

                        FontWeight

                            .w600,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(

            height:

                10,

          ),

          _AcademicInfoRow(

            label:

                'Dipartimento',

            value:

                draft.department

                        .isEmpty

                    ? 'Non specificato'

                    : draft.department,

          ),

          const SizedBox(

            height:

                7,

          ),

          _AcademicInfoRow(

            label:

                'Corso',

            value:

                draft.course

                        .isEmpty

                    ? 'Non specificato'

                    : draft.course,

          ),

          const SizedBox(

            height:

                10,

          ),

          Wrap(

            spacing:

                7,

            runSpacing:

                7,

            children: [

              _AcademicStatusBadge(

                status:

                    draft.academicStatus,

              ),

              if (

                draft.startYear !=

                    null

              )

                _AcademicSimpleBadge(

                  label:

                      'Dal ${draft.startYear}',

                ),

              if (

                draft.academicStatus ==

                        AcademicPathStatus

                            .graduated &&

                    draft.graduationYear !=

                        null

              )

                _AcademicSimpleBadge(

                  label:

                      'Conseguito ${draft.graduationYear}',

                ),

            ],

          ),

        ],

      ),

    );

  }

}

class _TeacherAssignmentPreview

    extends StatelessWidget {

  final TeacherAssignmentDraft

      assignment;

  final List<SocialSubject>

      subjects;

  const _TeacherAssignmentPreview({

    required this.assignment,

    required this.subjects,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    SocialSubject? subject;

    for (

      final SocialSubject current

      in subjects

    ) {

      if (

        current.id ==

        assignment.subjectId

      ) {

        subject =

            current;

        break;

      }

    }

    SubjectOffering? offering;

    if (

      subject != null &&

      assignment.offeringId !=

          null

    ) {

      for (

        final SubjectOffering current

        in subject.offerings

      ) {

        if (

          current.id ==

          assignment.offeringId

        ) {

          offering =

              current;

          break;

        }

      }

    }

    final String subjectName =

        subject?.name ??

            'Materia ${assignment.subjectId}';

    final List<String> details =

        [];

    if (

      offering != null &&

      offering.module

          .trim()

          .isNotEmpty

    ) {

      details.add(

        offering.module,

      );

    }

    if (

      offering != null &&

      offering.channel

          .trim()

          .isNotEmpty

    ) {

      details.add(

        'Canale ${offering.channel}',

      );

    }

    if (

      offering != null &&

      offering.academicYear

          .trim()

          .isNotEmpty

    ) {

      details.add(

        offering.academicYear,

      );

    }

    return Container(

      width:

          double.infinity,

      margin:

          const EdgeInsets.only(

        bottom:

            8,

      ),

      padding:

          const EdgeInsets.all(

        11,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .teacherIndigo

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

              AppColors

                  .teacherIndigo

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

            crossAxisAlignment:

                CrossAxisAlignment.start,

            children: [

              const Padding(

                padding:

                    EdgeInsets.only(

                  top:

                      2,

                ),

                child:

                    Icon(

                  Icons

                      .school_outlined,

                  color:

                      AppColors

                          .skyBlue,

                  size:

                      17,

                ),

              ),

              const SizedBox(

                width:

                    7,

              ),

              Expanded(

                child:

                    Column(

                  crossAxisAlignment:

                      CrossAxisAlignment

                          .start,

                  children: [

                    Text(

                      subjectName,

                      style:

                          const TextStyle(

                        color:

                            AppColors

                                .skyBlue,

                        fontSize:

                            13,

                        fontWeight:

                            FontWeight

                                .w600,

                      ),

                    ),

                    if (

                      subject !=

                          null

                    ) ...[

                      const SizedBox(

                        height:

                            4,

                      ),

                      Text(

                        [

                          if (

                            subject

                                .university

                                .trim()

                                .isNotEmpty

                          )

                            subject

                                .university,

                          if (

                            subject

                                .department

                                .trim()

                                .isNotEmpty

                          )

                            subject

                                .department,

                          if (

                            subject

                                .course

                                .trim()

                                .isNotEmpty

                          )

                            subject

                                .course,

                        ].join(

                          ' • ',

                        ),

                        style:

                            TextStyle(

                          color:

                              AppColors

                                  .pureWhite

                                  .withOpacity(

                            0.45,

                          ),

                          fontSize:

                              9,

                        ),

                      ),

                    ],

                  ],

                ),

              ),

              const SizedBox(

                width:

                    8,

              ),

              Container(

                padding:

                    const EdgeInsets

                        .symmetric(

                  horizontal:

                      7,

                  vertical:

                      4,

                ),

                decoration:

                    BoxDecoration(

                  color:

                      Colors.amber

                          .withOpacity(

                    0.10,

                  ),

                  borderRadius:

                      BorderRadius

                          .circular(

                    8,

                  ),

                ),

                child:

                    const Row(

                  mainAxisSize:

                      MainAxisSize.min,

                  children: [

                    Icon(

                      Icons

                          .schedule_rounded,

                      color:

                          Colors.amber,

                      size:

                          10,

                    ),

                    SizedBox(

                      width:

                          3,

                    ),

                    Text(

                      'DA VERIFICARE',

                      style:

                          TextStyle(

                        color:

                            Colors.amber,

                        fontSize:

                            8,

                        fontWeight:

                            FontWeight

                                .bold,

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

          if (details.isNotEmpty) ...[

            const SizedBox(

              height:

                  9,

            ),

            Wrap(

              spacing:

                  6,

              runSpacing:

                  6,

              children:

                  details

                      .map(

                        (

                          String detail,

                        ) =>

                            _SubjectBadge(

                          label:

                              detail,

                          icon:

                              Icons

                                  .class_outlined,

                        ),

                      )

                      .toList(),

            ),

          ],

          if (

            offering != null &&

            offering.teachers

                .isNotEmpty

          ) ...[

            const SizedBox(

              height:

                  9,

            ),

            Text(

              'Docenti catalogo: ${offering.teachers.map((AcademicTeacher teacher) => teacher.name).join(', ')}',

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite

                        .withOpacity(

                  0.50,

                ),

                fontSize:

                    10,

                height:

                    1.3,

              ),

            ),

          ],

        ],

      ),

    );

  }

}

class _AdditionalAcademicPathPreview

    extends StatelessWidget {

  final SocialAcademicPathDraft path;

  const _AdditionalAcademicPathPreview({

    required this.path,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    return Container(

      width:

          double.infinity,

      padding:

          const EdgeInsets.all(

        13,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors.brandNightBlue,

        borderRadius:

            BorderRadius.circular(

          12,

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

          Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              const Icon(

                Icons.account_balance_outlined,

                color:

                    AppColors.skyBlue,

                size:

                    17,

              ),

              const SizedBox(

                width:

                    7,

              ),

              Expanded(

                child:

                    Text(

                  path.university,

                  style:

                      const TextStyle(

                    color:

                        AppColors.pureWhite,

                    fontSize:

                        12,

                    fontWeight:

                        FontWeight.w600,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(

            height:

                10,

          ),

          _AcademicInfoRow(

            label:

                'Dipartimento',

            value:

                path.department,

          ),

          const SizedBox(

            height:

                7,

          ),

          _AcademicInfoRow(

            label:

                'Corso',

            value:

                path.course,

          ),

          const SizedBox(

            height:

                10,

          ),

          Wrap(

            spacing:

                7,

            runSpacing:

                7,

            children: [

              _AcademicStatusBadge(

                status:

                    path.status,

              ),

              if (path.startYear != null)

                _AcademicSimpleBadge(

                  label:

                      'Dal ${path.startYear}',

                ),

              if (path.graduationYear != null)

                _AcademicSimpleBadge(

                  label:

                      'Conseguito ${path.graduationYear}',

                ),

              if (path.isCurrent)

                const _AcademicSimpleBadge(

                  label:

                      'Corrente',

                ),

              if (path.isPrimary)

                const _AcademicSimpleBadge(

                  label:

                      'Principale',

                ),

            ],

          ),

        ],

      ),

    );

  }

}

class _AcademicInfoRow

    extends StatelessWidget {

  final String label;

  final String value;

  const _AcademicInfoRow({

    required this.label,

    required this.value,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    return Row(

      crossAxisAlignment:

          CrossAxisAlignment.start,

      children: [

        SizedBox(

          width:

              90,

          child:

              Text(

            label,

            style:

                TextStyle(

              color:

                  AppColors

                      .pureWhite

                      .withOpacity(

                0.38,

              ),

              fontSize:

                  10,

            ),

          ),

        ),

        const SizedBox(

          width:

              7,

        ),

        Expanded(

          child:

              Text(

            value,

            style:

                TextStyle(

              color:

                  AppColors

                      .pureWhite

                      .withOpacity(

                0.72,

              ),

              fontSize:

                  11,

            ),

          ),

        ),

      ],

    );

  }

}

class _AcademicStatusBadge

    extends StatelessWidget {

  final AcademicPathStatus status;

  const _AcademicStatusBadge({

    required this.status,

  });

  String get label {

    switch (status) {

      case AcademicPathStatus

            .enrolled:

        return 'Iscritto';

      case AcademicPathStatus

            .graduated:

        return 'Laureato';

      case AcademicPathStatus

            .suspended:

        return 'Percorso sospeso';

      case AcademicPathStatus

            .withdrawn:

        return 'Percorso interrotto';

      case AcademicPathStatus

            .transferred:

        return 'Trasferito';

    }

  }

  IconData get icon {

    switch (status) {

      case AcademicPathStatus

            .enrolled:

        return Icons

            .school_outlined;

      case AcademicPathStatus

            .graduated:

        return Icons

            .workspace_premium_outlined;

      case AcademicPathStatus

            .suspended:

        return Icons

            .pause_circle_outline_rounded;

      case AcademicPathStatus

            .withdrawn:

        return Icons

            .remove_circle_outline;

      case AcademicPathStatus

            .transferred:

        return Icons

            .swap_horiz_rounded;

    }

  }

  @override

  Widget build(

    BuildContext context,

  ) {

    return Container(

      padding:

          const EdgeInsets.symmetric(

        horizontal:

            8,

        vertical:

            5,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .skyBlue

                .withOpacity(

          0.10,

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

            color:

                AppColors

                    .materialSky,

            size:

                12,

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

                  AppColors

                      .materialSky,

              fontSize:

                  9,

              fontWeight:

                  FontWeight

                      .w600,

            ),

          ),

        ],

      ),

    );

  }

}

class _AcademicSimpleBadge

    extends StatelessWidget {

  final String label;

  const _AcademicSimpleBadge({

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

            8,

        vertical:

            5,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .pureWhite

                .withOpacity(

          0.05,

        ),

        borderRadius:

            BorderRadius.circular(

          8,

        ),

      ),

      child:

          Text(

        label,

        style:

            TextStyle(

          color:

              AppColors

                  .pureWhite

                  .withOpacity(

            0.60,

          ),

          fontSize:

              9,

          fontWeight:

              FontWeight.w500,

        ),

      ),

    );

  }

}

class _SubjectPreview

    extends StatelessWidget {

  final SocialSubject subject;

  const _SubjectPreview({

    required this.subject,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    return Container(

      width:

          double.infinity,

      margin:

          const EdgeInsets.only(

        bottom:

            8,

      ),

      padding:

          const EdgeInsets.all(

        11,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .socialBlue

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

              AppColors

                  .socialBlue

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

              const Icon(

                Icons

                    .menu_book_outlined,

                color:

                    AppColors

                        .skyBlue,

                size:

                    17,

              ),

              const SizedBox(

                width:

                    7,

              ),

              Expanded(

                child:

                    Text(

                  subject.name,

                  style:

                      const TextStyle(

                    color:

                        AppColors

                            .skyBlue,

                    fontSize:

                        13,

                    fontWeight:

                        FontWeight

                            .w600,

                  ),

                ),

              ),

              if (

                subject.grade !=

                    null

              )

                _PreviewGradePendingBadge(

                  grade:

                      subject.grade!,

                ),

            ],

          ),

          if (

            subject.canHelp ||

            subject

                .canGivePrivateLessons

          ) ...[

            const SizedBox(

              height:

                  8,

            ),

            Wrap(

              spacing:

                  6,

              runSpacing:

                  6,

              children: [

                if (

                  subject.canHelp

                )

                  const _SubjectBadge(

                    label:

                        'Aiuto',

                    icon:

                        Icons

                            .volunteer_activism_outlined,

                  ),

                if (

                  subject

                      .canGivePrivateLessons

                )

                  const _SubjectBadge(

                    label:

                        'Lezioni private',

                    icon:

                        Icons

                            .school_outlined,

                  ),

              ],

            ),

          ],

          if (

            subject.note

                .isNotEmpty

          ) ...[

            const SizedBox(

              height:

                  8,

            ),

            Text(

              subject.note,

              style:

                  TextStyle(

                color:

                    AppColors

                        .pureWhite

                        .withOpacity(

                  0.55,

                ),

                fontSize:

                    12,

                height:

                    1.3,

              ),

            ),

          ],

        ],

      ),

    );

  }

}


class _PreviewVerificationNotice
    extends StatelessWidget {
  const _PreviewVerificationNotice();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.amber.withOpacity(
          0.07,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              Colors.amber.withOpacity(
            0.18,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.verified_user_outlined,

            color:
                Colors.amber,

            size:
                18,
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Text(
              'I dati accademici dichiarati che richiedono conferma saranno sottoposti a verifica. '
              'Le materie senza voto non richiedono verifica; un voto dichiarato sarà considerato verificato '
              'solo dopo l’approvazione.',

              style:
                  TextStyle(
                color:
                    AppColors.pureWhite
                        .withOpacity(
                  0.62,
                ),

                fontSize:
                    10,

                height:
                    1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _PreviewPendingBadge
    extends StatelessWidget {
  final String label;

  const _PreviewPendingBadge({
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
            Colors.amber.withOpacity(
          0.10,
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
          const Icon(
            Icons.schedule_rounded,

            color:
                Colors.amber,

            size:
                10,
          ),

          const SizedBox(
            width:
                3,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  Colors.amber,

              fontSize:
                  8,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


class _PreviewGradePendingBadge
    extends StatelessWidget {
  final int grade;

  const _PreviewGradePendingBadge({
    required this.grade,
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
            Colors.amber.withOpacity(
          0.10,
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
          const Icon(
            Icons.schedule_rounded,

            color:
                Colors.amber,

            size:
                10,
          ),

          const SizedBox(
            width:
                3,
          ),

          Text(
            '$grade/30 · DA VERIFICARE',

            style:
                const TextStyle(
              color:
                  Colors.amber,

              fontSize:
                  8,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


class _SubjectBadge

    extends StatelessWidget {

  final String label;

  final IconData icon;

  const _SubjectBadge({

    required this.label,

    required this.icon,

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

            AppColors

                .skyBlue

                .withOpacity(

          0.10,

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

            color:

                AppColors

                    .materialSky,

            size:

                11,

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

                  AppColors

                      .materialSky,

              fontSize:

                  8,

              fontWeight:

                  FontWeight

                      .bold,

            ),

          ),

        ],

      ),

    );

  }

}

class _AvailableBadge

    extends StatelessWidget {

  const _AvailableBadge();

  @override

  Widget build(

    BuildContext context,

  ) {

    return const Row(

      mainAxisSize:

          MainAxisSize.min,

      children: [

        Icon(

          Icons.circle,

          color:

              Colors.green,

          size:

              9,

        ),

        SizedBox(

          width:

              5,

        ),

        Text(

          'Disponibile',

          style:

              TextStyle(

            color:

                Colors.green,

            fontSize:

                11,

          ),

        ),

      ],

    );

  }

}

class _ProfileChip

    extends StatelessWidget {

  final IconData icon;

  final String label;

  const _ProfileChip({

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

            9,

        vertical:

            6,

      ),

      decoration:

          BoxDecoration(

        color:

            AppColors

                .skyBlue

                .withOpacity(

          0.08,

        ),

        borderRadius:

            BorderRadius.circular(

          9,

        ),

        border:

            Border.all(

          color:

              AppColors

                  .skyBlue

                  .withOpacity(

            0.15,

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

                AppColors

                    .materialSky,

            size:

                15,

          ),

          const SizedBox(

            width:

                5,

          ),

          Text(

            label,

            style:

                const TextStyle(

              color:

                  AppColors

                      .materialSky,

              fontSize:

                  10,

              fontWeight:

                  FontWeight

                      .w500,

            ),

          ),

        ],

      ),

    );

  }

}