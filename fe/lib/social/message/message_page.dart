
import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
  });

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

        elevation:
            0,

        title: const Text(
          'Messaggi',

          style: TextStyle(
            fontSize:
                20,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(
            20,
          ),

          children: [
            // ===============================================================
            // CHAT PRIVATE
            // ===============================================================

            const Text(
              'Conversazioni',

              style: TextStyle(
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
                  14,
            ),

            _ChatCard(
              icon:
                  Icons.person_rounded,

              title:
                  'Marco',

              subtitle:
                  'Ciao! Hai fatto l\'esercizio di Programmazione?',

              isGroup:
                  false,

              onTap: () {
                _showMessage(
                  context,
                  'Chat privata con Marco: da implementare.',
                );
              },
            ),

            const SizedBox(
              height:
                  10,
            ),

            _ChatCard(
              icon:
                  Icons.person_rounded,

              title:
                  'Francesca',

              subtitle:
                  'Ti ho inviato gli appunti di Algebra.',

              isGroup:
                  false,

              onTap: () {
                _showMessage(
                  context,
                  'Chat privata con Francesca: da implementare.',
                );
              },
            ),

            const SizedBox(
              height:
                  28,
            ),

            // ===============================================================
            // CHAT DI GRUPPO
            // ===============================================================

            const Text(
              'Gruppi',

              style: TextStyle(
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
                  14,
            ),

            _ChatCard(
              icon:
                  Icons.groups_rounded,

              title:
                  'Programmazione 1',

              subtitle:
                  'Marco: possiamo fare l\'esercizio insieme.',

              isGroup:
                  true,

              onTap: () {
                _showMessage(
                  context,
                  'Chat del gruppo Programmazione 1: da implementare.',
                );
              },
            ),

            const SizedBox(
              height:
                  10,
            ),

            _ChatCard(
              icon:
                  Icons.groups_rounded,

              title:
                  'Algebra Lineare',

              subtitle:
                  'Francesca: qualcuno ha gli appunti della lezione?',

              isGroup:
                  true,

              onTap: () {
                _showMessage(
                  context,
                  'Chat del gruppo Algebra Lineare: da implementare.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }
}

// =============================================================================
// CHAT CARD
// =============================================================================

class _ChatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGroup;
  final VoidCallback onTap;

  const _ChatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          Colors.transparent,

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          17,
        ),

        child:
            Container(
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
                      .withOpacity(
                0.12,
              ),
            ),
          ),

          child:
              Row(
            children: [
              Container(
                width:
                    52,

                height:
                    52,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.brandNightBlue,

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child:
                    Icon(
                  icon,

                  color:
                      AppColors.skyBlue,

                  size:
                      27,
                ),
              ),

              const SizedBox(
                width:
                    13,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(
                            title,

                            maxLines:
                                1,

                            overflow:
                                TextOverflow.ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  AppColors.pureWhite,

                              fontSize:
                                  14,

                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        if (isGroup)
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  6,

                              vertical:
                                  3,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors
                                      .brandNightBlue,

                              borderRadius:
                                  BorderRadius.circular(
                                6,
                              ),
                            ),

                            child:
                                const Text(
                              'GRUPPO',

                              style:
                                  TextStyle(
                                color:
                                    AppColors
                                        .materialSky,

                                fontSize:
                                    8,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      subtitle,

                      maxLines:
                          2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors.pureWhite
                                .withOpacity(
                          0.48,
                        ),

                        fontSize:
                            11,

                        height:
                            1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              const Icon(
                Icons.chevron_right_rounded,

                color:
                    Colors.white38,

                size:
                    23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}