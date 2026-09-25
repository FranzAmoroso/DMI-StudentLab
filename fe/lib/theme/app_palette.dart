import 'package:flutter/material.dart';

import 'nightTheme.dart';

/// Palette di StudentLab come [ThemeExtension].
///
/// Ogni tema usa gli STESSI nomi di [AppColors]; cambiano solo i valori.
/// Il tema principale è [AppPalette.night]. Per un nuovo tema basta creare
/// un'altra istanza, ad esempio `AppPalette.night.copyWith(...)`.
///
/// Nei widget nuovi leggi i colori con `context.palette.eleganceMidnight`
/// invece di `AppColors.eleganceMidnight`, così il cambio tema funziona
/// senza toccare il codice. I widget esistenti possono migrare un po' alla volta.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color brandNightBlue;
  final Color secondaryNightBlue;
  final Color deepOcean;
  final Color darkElegance;
  final Color eleganceSoftNight;
  final Color eleganceMidnight;
  final Color eleganceDeepNavy;
  final Color eleganceShadow;
  final Color eleganceObsidian;
  final Color slateMidnight;
  final Color royalIndigo;
  final Color electricBlue;
  final Color vividSapphire;
  final Color lavenderBlue;
  final Color materialBlue;
  final Color materialNavy;
  final Color materialSteel;
  final Color materialSky;
  final Color socialBlue;
  final Color socialIndigo;
  final Color socialCobalt;
  final Color socialSky;
  final Color studentBlue;
  final Color studentSteel;
  final Color teacherIndigo;
  final Color teacherNavy;
  final Color availableBlue;
  final Color availableGreen;
  final Color pendingAmber;
  final Color charcoalGrey;
  final Color slateGrey;
  final Color graphite;
  final Color darkSlate;
  final Color mediumSlate;
  final Color lightSlate;
  final Color skyBlue;
  final Color diamondDust;
  final Color iceBlue;
  final Color steelBlue;
  final Color pureWhite;
  final Color pearlWhite;
  final Color mistWhite;
  final Color opaqueWhite;
  final Color translucentWhite;
  final Color correct;
  final Color wrong;
  final Color adminCyan;
  final Color adminBlue;
  final Color adminIndigo;
  final Color adminGreen;
  final Color adminAmber;
  final Color adminMagenta;
  final Color adminCoral;
  final Color surface;
  final Color surfaceStrong;
  final Color surfaceSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color surfaceBorder;

  const AppPalette({
    required this.brandNightBlue,
    required this.secondaryNightBlue,
    required this.deepOcean,
    required this.darkElegance,
    required this.eleganceSoftNight,
    required this.eleganceMidnight,
    required this.eleganceDeepNavy,
    required this.eleganceShadow,
    required this.eleganceObsidian,
    required this.slateMidnight,
    required this.royalIndigo,
    required this.electricBlue,
    required this.vividSapphire,
    required this.lavenderBlue,
    required this.materialBlue,
    required this.materialNavy,
    required this.materialSteel,
    required this.materialSky,
    required this.socialBlue,
    required this.socialIndigo,
    required this.socialCobalt,
    required this.socialSky,
    required this.studentBlue,
    required this.studentSteel,
    required this.teacherIndigo,
    required this.teacherNavy,
    required this.availableBlue,
    required this.availableGreen,
    required this.pendingAmber,
    required this.charcoalGrey,
    required this.slateGrey,
    required this.graphite,
    required this.darkSlate,
    required this.mediumSlate,
    required this.lightSlate,
    required this.skyBlue,
    required this.diamondDust,
    required this.iceBlue,
    required this.steelBlue,
    required this.pureWhite,
    required this.pearlWhite,
    required this.mistWhite,
    required this.opaqueWhite,
    required this.translucentWhite,
    required this.correct,
    required this.wrong,
    required this.adminCyan,
    required this.adminBlue,
    required this.adminIndigo,
    required this.adminGreen,
    required this.adminAmber,
    required this.adminMagenta,
    required this.adminCoral,
    required this.surface,
    required this.surfaceStrong,
    required this.surfaceSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.surfaceBorder,
  });

  static const AppPalette night = AppPalette(
    brandNightBlue: AppColors.brandNightBlue,
    secondaryNightBlue: AppColors.secondaryNightBlue,
    deepOcean: AppColors.deepOcean,
    darkElegance: AppColors.darkElegance,
    eleganceSoftNight: AppColors.eleganceSoftNight,
    eleganceMidnight: AppColors.eleganceMidnight,
    eleganceDeepNavy: AppColors.eleganceDeepNavy,
    eleganceShadow: AppColors.eleganceShadow,
    eleganceObsidian: AppColors.eleganceObsidian,
    slateMidnight: AppColors.slateMidnight,
    royalIndigo: AppColors.royalIndigo,
    electricBlue: AppColors.electricBlue,
    vividSapphire: AppColors.vividSapphire,
    lavenderBlue: AppColors.lavenderBlue,
    materialBlue: AppColors.materialBlue,
    materialNavy: AppColors.materialNavy,
    materialSteel: AppColors.materialSteel,
    materialSky: AppColors.materialSky,
    socialBlue: AppColors.socialBlue,
    socialIndigo: AppColors.socialIndigo,
    socialCobalt: AppColors.socialCobalt,
    socialSky: AppColors.socialSky,
    studentBlue: AppColors.studentBlue,
    studentSteel: AppColors.studentSteel,
    teacherIndigo: AppColors.teacherIndigo,
    teacherNavy: AppColors.teacherNavy,
    availableBlue: AppColors.availableBlue,
    availableGreen: AppColors.availableGreen,
    pendingAmber: AppColors.pendingAmber,
    charcoalGrey: AppColors.charcoalGrey,
    slateGrey: AppColors.slateGrey,
    graphite: AppColors.graphite,
    darkSlate: AppColors.darkSlate,
    mediumSlate: AppColors.mediumSlate,
    lightSlate: AppColors.lightSlate,
    skyBlue: AppColors.skyBlue,
    diamondDust: AppColors.diamondDust,
    iceBlue: AppColors.iceBlue,
    steelBlue: AppColors.steelBlue,
    pureWhite: AppColors.pureWhite,
    pearlWhite: AppColors.pearlWhite,
    mistWhite: AppColors.mistWhite,
    opaqueWhite: AppColors.opaqueWhite,
    translucentWhite: AppColors.translucentWhite,
    correct: AppColors.correct,
    wrong: AppColors.wrong,
    adminCyan: AppColors.adminCyan,
    adminBlue: AppColors.adminBlue,
    adminIndigo: AppColors.adminIndigo,
    adminGreen: AppColors.adminGreen,
    adminAmber: AppColors.adminAmber,
    adminMagenta: AppColors.adminMagenta,
    adminCoral: AppColors.adminCoral,
    surface: AppColors.surface,
    surfaceStrong: AppColors.surfaceStrong,
    surfaceSoft: AppColors.surfaceSoft,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    divider: AppColors.divider,
    surfaceBorder: AppColors.surfaceBorder,
  );

  @override
  AppPalette copyWith({
    Color? brandNightBlue,
    Color? secondaryNightBlue,
    Color? deepOcean,
    Color? darkElegance,
    Color? eleganceSoftNight,
    Color? eleganceMidnight,
    Color? eleganceDeepNavy,
    Color? eleganceShadow,
    Color? eleganceObsidian,
    Color? slateMidnight,
    Color? royalIndigo,
    Color? electricBlue,
    Color? vividSapphire,
    Color? lavenderBlue,
    Color? materialBlue,
    Color? materialNavy,
    Color? materialSteel,
    Color? materialSky,
    Color? socialBlue,
    Color? socialIndigo,
    Color? socialCobalt,
    Color? socialSky,
    Color? studentBlue,
    Color? studentSteel,
    Color? teacherIndigo,
    Color? teacherNavy,
    Color? availableBlue,
    Color? availableGreen,
    Color? pendingAmber,
    Color? charcoalGrey,
    Color? slateGrey,
    Color? graphite,
    Color? darkSlate,
    Color? mediumSlate,
    Color? lightSlate,
    Color? skyBlue,
    Color? diamondDust,
    Color? iceBlue,
    Color? steelBlue,
    Color? pureWhite,
    Color? pearlWhite,
    Color? mistWhite,
    Color? opaqueWhite,
    Color? translucentWhite,
    Color? correct,
    Color? wrong,
    Color? adminCyan,
    Color? adminBlue,
    Color? adminIndigo,
    Color? adminGreen,
    Color? adminAmber,
    Color? adminMagenta,
    Color? adminCoral,
    Color? surface,
    Color? surfaceStrong,
    Color? surfaceSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? surfaceBorder,
  }) {
    return AppPalette(
      brandNightBlue: brandNightBlue ?? this.brandNightBlue,
      secondaryNightBlue: secondaryNightBlue ?? this.secondaryNightBlue,
      deepOcean: deepOcean ?? this.deepOcean,
      darkElegance: darkElegance ?? this.darkElegance,
      eleganceSoftNight: eleganceSoftNight ?? this.eleganceSoftNight,
      eleganceMidnight: eleganceMidnight ?? this.eleganceMidnight,
      eleganceDeepNavy: eleganceDeepNavy ?? this.eleganceDeepNavy,
      eleganceShadow: eleganceShadow ?? this.eleganceShadow,
      eleganceObsidian: eleganceObsidian ?? this.eleganceObsidian,
      slateMidnight: slateMidnight ?? this.slateMidnight,
      royalIndigo: royalIndigo ?? this.royalIndigo,
      electricBlue: electricBlue ?? this.electricBlue,
      vividSapphire: vividSapphire ?? this.vividSapphire,
      lavenderBlue: lavenderBlue ?? this.lavenderBlue,
      materialBlue: materialBlue ?? this.materialBlue,
      materialNavy: materialNavy ?? this.materialNavy,
      materialSteel: materialSteel ?? this.materialSteel,
      materialSky: materialSky ?? this.materialSky,
      socialBlue: socialBlue ?? this.socialBlue,
      socialIndigo: socialIndigo ?? this.socialIndigo,
      socialCobalt: socialCobalt ?? this.socialCobalt,
      socialSky: socialSky ?? this.socialSky,
      studentBlue: studentBlue ?? this.studentBlue,
      studentSteel: studentSteel ?? this.studentSteel,
      teacherIndigo: teacherIndigo ?? this.teacherIndigo,
      teacherNavy: teacherNavy ?? this.teacherNavy,
      availableBlue: availableBlue ?? this.availableBlue,
      availableGreen: availableGreen ?? this.availableGreen,
      pendingAmber: pendingAmber ?? this.pendingAmber,
      charcoalGrey: charcoalGrey ?? this.charcoalGrey,
      slateGrey: slateGrey ?? this.slateGrey,
      graphite: graphite ?? this.graphite,
      darkSlate: darkSlate ?? this.darkSlate,
      mediumSlate: mediumSlate ?? this.mediumSlate,
      lightSlate: lightSlate ?? this.lightSlate,
      skyBlue: skyBlue ?? this.skyBlue,
      diamondDust: diamondDust ?? this.diamondDust,
      iceBlue: iceBlue ?? this.iceBlue,
      steelBlue: steelBlue ?? this.steelBlue,
      pureWhite: pureWhite ?? this.pureWhite,
      pearlWhite: pearlWhite ?? this.pearlWhite,
      mistWhite: mistWhite ?? this.mistWhite,
      opaqueWhite: opaqueWhite ?? this.opaqueWhite,
      translucentWhite: translucentWhite ?? this.translucentWhite,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      adminCyan: adminCyan ?? this.adminCyan,
      adminBlue: adminBlue ?? this.adminBlue,
      adminIndigo: adminIndigo ?? this.adminIndigo,
      adminGreen: adminGreen ?? this.adminGreen,
      adminAmber: adminAmber ?? this.adminAmber,
      adminMagenta: adminMagenta ?? this.adminMagenta,
      adminCoral: adminCoral ?? this.adminCoral,
      surface: surface ?? this.surface,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brandNightBlue: Color.lerp(brandNightBlue, other.brandNightBlue, t)!,
      secondaryNightBlue: Color.lerp(secondaryNightBlue, other.secondaryNightBlue, t)!,
      deepOcean: Color.lerp(deepOcean, other.deepOcean, t)!,
      darkElegance: Color.lerp(darkElegance, other.darkElegance, t)!,
      eleganceSoftNight: Color.lerp(eleganceSoftNight, other.eleganceSoftNight, t)!,
      eleganceMidnight: Color.lerp(eleganceMidnight, other.eleganceMidnight, t)!,
      eleganceDeepNavy: Color.lerp(eleganceDeepNavy, other.eleganceDeepNavy, t)!,
      eleganceShadow: Color.lerp(eleganceShadow, other.eleganceShadow, t)!,
      eleganceObsidian: Color.lerp(eleganceObsidian, other.eleganceObsidian, t)!,
      slateMidnight: Color.lerp(slateMidnight, other.slateMidnight, t)!,
      royalIndigo: Color.lerp(royalIndigo, other.royalIndigo, t)!,
      electricBlue: Color.lerp(electricBlue, other.electricBlue, t)!,
      vividSapphire: Color.lerp(vividSapphire, other.vividSapphire, t)!,
      lavenderBlue: Color.lerp(lavenderBlue, other.lavenderBlue, t)!,
      materialBlue: Color.lerp(materialBlue, other.materialBlue, t)!,
      materialNavy: Color.lerp(materialNavy, other.materialNavy, t)!,
      materialSteel: Color.lerp(materialSteel, other.materialSteel, t)!,
      materialSky: Color.lerp(materialSky, other.materialSky, t)!,
      socialBlue: Color.lerp(socialBlue, other.socialBlue, t)!,
      socialIndigo: Color.lerp(socialIndigo, other.socialIndigo, t)!,
      socialCobalt: Color.lerp(socialCobalt, other.socialCobalt, t)!,
      socialSky: Color.lerp(socialSky, other.socialSky, t)!,
      studentBlue: Color.lerp(studentBlue, other.studentBlue, t)!,
      studentSteel: Color.lerp(studentSteel, other.studentSteel, t)!,
      teacherIndigo: Color.lerp(teacherIndigo, other.teacherIndigo, t)!,
      teacherNavy: Color.lerp(teacherNavy, other.teacherNavy, t)!,
      availableBlue: Color.lerp(availableBlue, other.availableBlue, t)!,
      availableGreen: Color.lerp(availableGreen, other.availableGreen, t)!,
      pendingAmber: Color.lerp(pendingAmber, other.pendingAmber, t)!,
      charcoalGrey: Color.lerp(charcoalGrey, other.charcoalGrey, t)!,
      slateGrey: Color.lerp(slateGrey, other.slateGrey, t)!,
      graphite: Color.lerp(graphite, other.graphite, t)!,
      darkSlate: Color.lerp(darkSlate, other.darkSlate, t)!,
      mediumSlate: Color.lerp(mediumSlate, other.mediumSlate, t)!,
      lightSlate: Color.lerp(lightSlate, other.lightSlate, t)!,
      skyBlue: Color.lerp(skyBlue, other.skyBlue, t)!,
      diamondDust: Color.lerp(diamondDust, other.diamondDust, t)!,
      iceBlue: Color.lerp(iceBlue, other.iceBlue, t)!,
      steelBlue: Color.lerp(steelBlue, other.steelBlue, t)!,
      pureWhite: Color.lerp(pureWhite, other.pureWhite, t)!,
      pearlWhite: Color.lerp(pearlWhite, other.pearlWhite, t)!,
      mistWhite: Color.lerp(mistWhite, other.mistWhite, t)!,
      opaqueWhite: Color.lerp(opaqueWhite, other.opaqueWhite, t)!,
      translucentWhite: Color.lerp(translucentWhite, other.translucentWhite, t)!,
      correct: Color.lerp(correct, other.correct, t)!,
      wrong: Color.lerp(wrong, other.wrong, t)!,
      adminCyan: Color.lerp(adminCyan, other.adminCyan, t)!,
      adminBlue: Color.lerp(adminBlue, other.adminBlue, t)!,
      adminIndigo: Color.lerp(adminIndigo, other.adminIndigo, t)!,
      adminGreen: Color.lerp(adminGreen, other.adminGreen, t)!,
      adminAmber: Color.lerp(adminAmber, other.adminAmber, t)!,
      adminMagenta: Color.lerp(adminMagenta, other.adminMagenta, t)!,
      adminCoral: Color.lerp(adminCoral, other.adminCoral, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Palette del tema corrente; se il tema non la registra usa [AppPalette.night].
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.night;
}
