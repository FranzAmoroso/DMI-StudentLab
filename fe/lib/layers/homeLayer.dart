import 'package:flutter/material.dart';

import 'package:fe/quiz/subjectSelection.dart';

import 'package:fe/theme/nightTheme.dart';

import 'package:fe/material/StudentMaterialPage.dart';

import 'package:fe/social/social_models.dart';
import 'package:fe/social/social_page.dart';

import 'package:fe/social/auth/login_page.dart';

import 'package:fe/social/widgets/social_profile_type.dart';


// =============================================================================
// FEATURE TYPE
// =============================================================================

enum HomeFeatureType {
  exercise,
  examSimulation,
  review,
  definitions,
  materials,
  social,
}


// =============================================================================
// FEATURE CARD
// =============================================================================

class FeatureCard {
  final HomeFeatureType type;

  final String title;

  final String description;

  final IconData icon;

  final Color color;

  final bool isComingSoon;


  const FeatureCard({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,

    this.isComingSoon = false,
  });
}


// =============================================================================
// HOME LAYER
// =============================================================================

class HomeLayer extends StatelessWidget {
  final bool isAuthenticated;


  HomeLayer({
    super.key,
    required this.isAuthenticated,
  });


  // ===========================================================================
  // FEATURE CARDS
  // ===========================================================================

  final List<FeatureCard> _featureCards = [
    FeatureCard(
      type:
          HomeFeatureType.exercise,

      title:
          'Esercitazione',

      description:
          'Allena la tua mente senza lo stress del tempo, '
          'filtrando le domande per singoli argomenti della materia.',

      icon:
          Icons.quiz,

      color:
          AppColors.eleganceObsidian,
    ),

    FeatureCard(
      type:
          HomeFeatureType.examSimulation,

      title:
          'Simulazione Esame',

      description:
          'Mettiti alla prova con i veri compiti d\'esame '
          'd\'appello, aggiornati in base al professore del tuo corso.',

      icon:
          Icons.checklist,

      color:
          AppColors.eleganceMidnight,

      isComingSoon:
          true,
    ),

    FeatureCard(
      type:
          HomeFeatureType.review,

      title:
          'Ripasso',

      description:
          'Rivedi i concetti più difficili e approfondisci '
          'gli argomenti delle domande che hai sbagliato.',

      icon:
          Icons.warning_amber_rounded,

      color:
          AppColors.charcoalGrey,

      isComingSoon:
          true,
    ),

    FeatureCard(
      type:
          HomeFeatureType.definitions,

      title:
          'Definizioni',

      description:
          'Glossario completo dei termini e concetti chiave del corso.',

      icon:
          Icons.menu_book,

      color:
          AppColors.graphite,

      isComingSoon:
          true,
    ),

    FeatureCard(
      type:
          HomeFeatureType.materials,

      title:
          'Materiale',

      description:
          'Accedi a dispense, slide e documenti utili '
          'per supportare il tuo studio.',

      icon:
          Icons.cloud,

      color:
          AppColors.darkElegance,
    ),

    FeatureCard(
      type:
          HomeFeatureType.social,

      title:
          'Altri studenti',

      description:
          'Connettiti con i tuoi colleghi di corso e collaborate.',

      icon:
          Icons.people,

      color:
          AppColors.slateGrey,
    ),
  ];


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final double screenWidth =
        MediaQuery.of(
      context,
    ).size.width;


    int crossAxisCount =
        2;


    if (screenWidth >
            600 &&
        screenWidth <=
            900) {
      crossAxisCount =
          3;
    } else if (screenWidth >
        900) {
      crossAxisCount =
          4;
    }


    return Padding(
      padding:
          const EdgeInsets.all(
        16,
      ),

      child:
          GridView.builder(
        itemCount:
            _featureCards.length,

        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              crossAxisCount,

          crossAxisSpacing:
              16,

          mainAxisSpacing:
              16,

          childAspectRatio:
              1,
        ),

        itemBuilder:
            (
          context,
          index,
        ) {
          return _buildGridCard(
            context,
            _featureCards[index],
          );
        },
      ),
    );
  }


  // ===========================================================================
  // CARD
  // ===========================================================================

  Widget _buildGridCard(
    BuildContext context,
    FeatureCard card,
  ) {
    final ValueNotifier<double>
        shakeOffset =
        ValueNotifier<double>(
      0,
    );


    final ValueNotifier<double>
        cardScale =
        ValueNotifier<double>(
      1,
    );


    final Widget cardBody =
        ValueListenableBuilder<double>(
      valueListenable:
          cardScale,

      builder:
          (
        context,
        scale,
        child,
      ) {
        return AnimatedScale(
          scale:
              scale,

          duration:
              const Duration(
            milliseconds:
                150,
          ),

          curve:
              Curves.easeOutCubic,

          child:
              Card(
            elevation:
                AppColors
                    .elegantCardTheme
                    .elevation,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child:
                ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              child:
                  Stack(
                children: [
                  // ===========================================================
                  // BACKGROUND
                  // ===========================================================

                  Container(
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        begin:
                            Alignment.topLeft,

                        end:
                            Alignment.bottomRight,

                        colors: [
                          card.color,

                          card.color
                              .withOpacity(
                            0.8,
                          ),

                          AppColors
                              .darkElegance,
                        ],
                      ),
                    ),
                  ),


                  // ===========================================================
                  // CONTENT
                  // ===========================================================

                  Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(
                                8,
                              ),

                              decoration:
                                  const BoxDecoration(
                                color:
                                    AppColors
                                        .translucentWhite,

                                shape:
                                    BoxShape.circle,
                              ),

                              child:
                                  Icon(
                                card.icon,

                                size:
                                    26,

                                color:
                                    AppColors
                                        .pureWhite,
                              ),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              card.title,

                              maxLines:
                                  1,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(
                                fontSize:
                                    18,

                                fontWeight:
                                    FontWeight.bold,

                                color:
                                    AppColors
                                        .pureWhite,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  4,
                            ),

                            Text(
                              card.description,

                              maxLines:
                                  2,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  TextStyle(
                                fontSize:
                                    12,

                                color:
                                    AppColors
                                        .pureWhite
                                        .withOpacity(
                                  card.isComingSoon
                                      ? 0.4
                                      : 0.7,
                                ),

                                fontWeight:
                                    FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),


                  // ===========================================================
                  // TAP
                  // ===========================================================

                  Positioned.fill(
                    child:
                        GestureDetector(
                      behavior:
                          HitTestBehavior
                              .opaque,

                      onTapDown:
                          (_) {
                        cardScale.value =
                            1.05;
                      },

                      onTapUp:
                          (_) {
                        cardScale.value =
                            1;
                      },

                      onTapCancel:
                          () {
                        cardScale.value =
                            1;
                      },

                      onTap:
                          () async {
                        if (card
                            .isComingSoon) {
                          await _shakeSoon(
                            shakeOffset,
                          );

                          return;
                        }


                        await _openFeature(
                          context,
                          card,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );


    if (!card.isComingSoon) {
      return cardBody;
    }


    // =========================================================================
    // COMING SOON BANNER
    // =========================================================================

    return Stack(
      children: [
        cardBody,

        Positioned(
          top:
              0,

          right:
              0,

          child:
              ValueListenableBuilder<
                  double>(
            valueListenable:
                shakeOffset,

            builder:
                (
              context,
              offset,
              child,
            ) {
              return TweenAnimationBuilder<
                  double>(
                tween:
                    Tween<double>(
                  begin:
                      0,

                  end:
                      offset,
                ),

                duration:
                    const Duration(
                  milliseconds:
                      40,
                ),

                builder:
                    (
                  context,
                  value,
                  child,
                ) {
                  return Transform.translate(
                    offset:
                        Offset(
                      value,
                      0,
                    ),

                    child:
                        child,
                  );
                },

                child:
                    ClipRRect(
                  borderRadius:
                      const BorderRadius.only(
                    topRight:
                        Radius.circular(
                      20,
                    ),
                  ),

                  child:
                      CustomPaint(
                    size:
                        const Size(
                      65,
                      65,
                    ),

                    painter:
                        BannerPainter(
                      message:
                          'SOON',

                      textDirection:
                          TextDirection.ltr,

                      location:
                          BannerLocation.topEnd,

                      layoutDirection:
                          TextDirection.ltr,

                      color:
                          AppColors.skyBlue,

                      textStyle:
                          const TextStyle(
                        fontSize:
                            9,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            AppColors
                                .brandNightBlue,

                        letterSpacing:
                            1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  // ===========================================================================
  // OPEN FEATURE
  // ===========================================================================

  Future<void> _openFeature(
    BuildContext context,
    FeatureCard card,
  ) async {
    switch (card.type) {
      // =======================================================================
      // ESERCITAZIONE
      // =======================================================================

      case HomeFeatureType.exercise:
        await Navigator.of(
          context,
        ).push(
          MaterialPageRoute(
            builder:
                (_) =>
                    const SubjectSelection(
              department:
                  'DMI',

              course:
                  'L-31',
            ),
          ),
        );

        return;


      // =======================================================================
      // MATERIALI
      // =======================================================================

      case HomeFeatureType.materials:
        await Navigator.of(
          context,
        ).push(
          MaterialPageRoute(
            builder:
                (_) =>
                    const StudentMaterialPage(),
          ),
        );

        return;


      // =======================================================================
      // SOCIAL
      // =======================================================================

      case HomeFeatureType.social:
        if (isAuthenticated) {
          await Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder:
                  (_) =>
                      const SocialPage(),
            ),
          );

          return;
        }


        await _showSocialGuestOptions(
          context,
        );

        return;


      // =======================================================================
      // COMING SOON
      // =======================================================================

      case HomeFeatureType.examSimulation:
      case HomeFeatureType.review:
      case HomeFeatureType.definitions:
        return;
    }
  }


  // ===========================================================================
  // SOCIAL GUEST OPTIONS
  // ===========================================================================

  Future<void> _showSocialGuestOptions(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
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
              Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              12,
            ),

            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                const Text(
                  'StudentLab Social',

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

                const SizedBox(
                  height:
                      7,
                ),

                Text(
                  'Per utilizzare gruppi, messaggi e funzionalità '
                  'Social puoi accedere oppure creare il tuo profilo.',

                  style:
                      TextStyle(
                    color:
                        AppColors.pureWhite
                            .withOpacity(
                      0.55,
                    ),

                    fontSize:
                        12,

                    height:
                        1.4,
                  ),
                ),

                const SizedBox(
                  height:
                      20,
                ),


                // =============================================================
                // LOGIN
                // =============================================================

                SizedBox(
                  height:
                      48,

                  child:
                      OutlinedButton.icon(
                    onPressed:
                        () async {
                      Navigator.pop(
                        sheetContext,
                      );


                      final SocialUser? user =
                          await Navigator.of(
                        context,
                      ).push<
                          SocialUser>(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const LoginPage(),
                        ),
                      );


                      if (user !=
                              null &&
                          context.mounted) {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const SocialPage(),
                          ),
                        );
                      }
                    },

                    icon:
                        const Icon(
                      Icons.login_rounded,
                    ),

                    label:
                        const Text(
                      'Accedi',
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.skyBlue,

                      side:
                          BorderSide(
                        color:
                            AppColors.skyBlue
                                .withOpacity(
                          0.35,
                        ),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),


                // =============================================================
                // SIGN UP
                // =============================================================

                SizedBox(
                  height:
                      48,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        () async {
                      Navigator.pop(
                        sheetContext,
                      );


                      final SocialUser? user =
                          await Navigator.of(
                        context,
                      ).push<
                          SocialUser>(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const SocialProfileType(),
                        ),
                      );


                      if (user !=
                              null &&
                          context.mounted) {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const SocialPage(),
                          ),
                        );
                      }
                    },

                    icon:
                        const Icon(
                      Icons.person_add_alt_1_rounded,
                    ),

                    label:
                        const Text(
                      'Crea profilo',
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
                          13,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ===========================================================================
  // SHAKE COMING SOON
  // ===========================================================================

  Future<void> _shakeSoon(
    ValueNotifier<double> shakeOffset,
  ) async {
    if (shakeOffset.value !=
        0) {
      return;
    }


    shakeOffset.value =
        6;

    await Future.delayed(
      const Duration(
        milliseconds:
            50,
      ),
    );


    shakeOffset.value =
        -6;

    await Future.delayed(
      const Duration(
        milliseconds:
            50,
      ),
    );


    shakeOffset.value =
        4;

    await Future.delayed(
      const Duration(
        milliseconds:
            50,
      ),
    );


    shakeOffset.value =
        -4;

    await Future.delayed(
      const Duration(
        milliseconds:
            50,
      ),
    );


    shakeOffset.value =
        0;
  }
}