import 'package:flutter/material.dart';

import '../models/study_group.dart';

import 'package:fe/theme/nightTheme.dart';


class StudyGroupCard extends StatelessWidget {
  final StudyGroup group;

  final VoidCallback onTap;


  const StudyGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final double width =
            constraints.maxWidth;


        final bool compact =
            width < 180;


        final bool medium =
            width >= 180 &&
            width < 260;


        final double padding =
            compact
                ? 12
                : medium
                    ? 15
                    : 18;


        final double iconSize =
            compact
                ? 42
                : medium
                    ? 46
                    : 50;


        final double icon =
            compact
                ? 22
                : medium
                    ? 25
                    : 28;


        return Material(
          color:
              Colors.transparent,

          child:
              InkWell(
            onTap:
                onTap,

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            child:
                Container(
              width:
                  double.infinity,

              padding:
                  EdgeInsets.all(
                padding,
              ),

              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .eleganceMidnight,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                border:
                    Border.all(
                  color:
                      AppColors.skyBlue
                          .withOpacity(
                    0.18,
                  ),
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.15,
                    ),

                    blurRadius:
                        8,

                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  // ==========================================================
                  // HEADER
                  // ==========================================================

                  Row(
                    children: [
                      Container(
                        width:
                            iconSize,

                        height:
                            iconSize,

                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .brandNightBlue,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),

                        child:
                            Icon(
                          Icons
                              .groups_rounded,

                          color:
                              AppColors
                                  .skyBlue,

                          size:
                              icon,
                        ),
                      ),

                      const Spacer(),


                      if (group.isOwner)
                        Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            right:
                                7,
                          ),

                          padding:
                              EdgeInsets
                                  .symmetric(
                            horizontal:
                                compact
                                    ? 6
                                    : 8,

                            vertical:
                                compact
                                    ? 4
                                    : 5,
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
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),

                          child:
                              Text(
                            'OWNER',

                            style:
                                TextStyle(
                              color:
                                  AppColors
                                      .materialSky,

                              fontSize:
                                  compact
                                      ? 7
                                      : 9,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),


                      if (group.isPrivate)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            right:
                                8,
                          ),

                          child:
                              Icon(
                            Icons
                                .lock_outline_rounded,

                            color:
                                AppColors
                                    .pureWhite
                                    .withOpacity(
                              0.45,
                            ),

                            size:
                                compact
                                    ? 15
                                    : 18,
                          ),
                        ),


                      Icon(
                        Icons
                            .arrow_forward_ios_rounded,

                        color:
                            AppColors
                                .pureWhite
                                .withOpacity(
                          0.45,
                        ),

                        size:
                            compact
                                ? 13
                                : 16,
                      ),
                    ],
                  ),


                  SizedBox(
                    height:
                        compact
                            ? 12
                            : 16,
                  ),


                  // ==========================================================
                  // NOME
                  // ==========================================================

                  Text(
                    group.name,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          AppColors
                              .pureWhite,

                      fontSize:
                          compact
                              ? 14
                              : medium
                                  ? 16
                                  : 17,

                      fontWeight:
                          FontWeight.bold,

                      height:
                          1.2,
                    ),
                  ),


                  SizedBox(
                    height:
                        compact
                            ? 5
                            : 7,
                  ),


                  // ==========================================================
                  // MATERIA
                  // ==========================================================

                  Text(
                    _subjectText(),

                    maxLines:
                        1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          group.subject
                                  .isNotEmpty
                              ? AppColors
                                  .materialSky
                              : AppColors
                                  .pureWhite
                                  .withOpacity(
                                  0.60,
                                ),

                      fontSize:
                          compact
                              ? 10
                              : 12,

                      fontWeight:
                          group.subject
                                  .isNotEmpty
                              ? FontWeight
                                  .w500
                              : FontWeight
                                  .normal,
                    ),
                  ),


                  SizedBox(
                    height:
                        compact
                            ? 4
                            : 6,
                  ),


                  // ==========================================================
                  // CORSO
                  // ==========================================================

                  Text(
                    group.course,

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
                        0.50,
                      ),

                      fontSize:
                          compact
                              ? 9
                              : 11,
                    ),
                  ),


                  SizedBox(
                    height:
                        compact
                            ? 8
                            : 10,
                  ),


                  // ==========================================================
                  // DESCRIZIONE
                  // ==========================================================

                  Expanded(
                    child:
                        Text(
                      group.description
                              .isEmpty
                          ? 'Nessuna descrizione.'
                          : group
                              .description,

                      maxLines:
                          compact
                              ? 2
                              : 3,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          TextStyle(
                        color:
                            AppColors
                                .pureWhite
                                .withOpacity(
                          0.50,
                        ),

                        fontSize:
                            compact
                                ? 10
                                : 12,

                        height:
                            1.3,
                      ),
                    ),
                  ),


                  SizedBox(
                    height:
                        compact
                            ? 12
                            : 16,
                  ),


                  // ==========================================================
                  // INFORMAZIONI
                  // ==========================================================

                  Row(
                    children: [
                      Icon(
                        Icons
                            .people_outline_rounded,

                        size:
                            compact
                                ? 14
                                : 16,

                        color:
                            AppColors
                                .materialSky,
                      ),

                      const SizedBox(
                        width:
                            5,
                      ),

                      Expanded(
                        child:
                            Text(
                          '${group.memberCount} partecipanti',

                          maxLines:
                              1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            color:
                                AppColors
                                    .materialSky
                                    .withOpacity(
                              0.9,
                            ),

                            fontSize:
                                compact
                                    ? 10
                                    : 12,

                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width:
                            8,
                      ),

                      Icon(
                        Icons
                            .folder_outlined,

                        size:
                            compact
                                ? 14
                                : 16,

                        color:
                            AppColors
                                .materialSky,
                      ),

                      const SizedBox(
                        width:
                            5,
                      ),

                      Text(
                        '${group.materialCount}',

                        style:
                            TextStyle(
                          color:
                              AppColors
                                  .materialSky
                                  .withOpacity(
                            0.9,
                          ),

                          fontSize:
                              compact
                                  ? 10
                                  : 12,

                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // ===========================================================================
  // NOME MATERIA
  // ===========================================================================

  String _subjectText() {
    if (group.subject.isNotEmpty) {
      return group.subject;
    }


    if (group.subjectId != null) {
      return 'Materia #${group.subjectId}';
    }


    return 'Materia non specificata';
  }
}