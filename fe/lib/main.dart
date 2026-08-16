import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'theme/nightTheme.dart';

import 'layers/home.dart';

import 'local_storage/local_storage.dart';


// =============================================================================
// MAIN
// =============================================================================

Future<void> main() async {
  // Necessario prima di utilizzare plugin Flutter.
  WidgetsFlutterBinding.ensureInitialized();


  // ===========================================================================
  // SQLITE DESKTOP
  // ===========================================================================
  //
  // Su Linux e Windows sqflite utilizza
  // sqflite_common_ffi.
  //
  // Questa configurazione DEVE essere eseguita
  // prima dell'apertura del database.
  // ===========================================================================

  if (Platform.isLinux ||
      Platform.isWindows) {

    sqfliteFfiInit();


    databaseFactory =
        databaseFactoryFfi;
  }


  // ===========================================================================
  // LOCAL STORAGE
  // ===========================================================================

  final LocalStorageService localStorage =
      LocalStorageService();


  // Apre / crea studentlab.db.
  //
  // Non passiamo ancora userId:
  // la sessione utente verrà ripristinata
  // successivamente tramite AuthService/AuthSession.
  await localStorage.initialize();


  // ===========================================================================
  // SYSTEM UI
  // ===========================================================================

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:
          Colors.transparent,

      statusBarIconBrightness:
          Brightness.light,

      systemNavigationBarColor:
          AppColors.darkElegance,

      systemNavigationBarIconBrightness:
          Brightness.light,
    ),
  );


  // ===========================================================================
  // START APP
  // ===========================================================================

  runApp(
    const MyApp(),
  );
}


// =============================================================================
// APP
// =============================================================================

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title:
          'StudentLab',

      debugShowCheckedModeBanner:
          false,


      // =========================================================================
      // THEME
      // =========================================================================

      theme:
          ThemeData.dark().copyWith(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              AppColors.brandNightBlue,

          brightness:
              Brightness.dark,
        ),

        scaffoldBackgroundColor:
            AppColors.darkElegance,

        appBarTheme:
            AppColors.nightAppBarTheme,

        cardTheme:
            AppColors.elegantCardTheme,

        bottomNavigationBarTheme:
            AppColors.nightBottomNavTheme,
      ),


      // =========================================================================
      // HOME
      // =========================================================================

      home:
          const HomePage(),
    );
  }
}