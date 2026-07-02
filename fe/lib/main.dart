import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/nightTheme.dart';
import 'layers/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor : Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkElegance,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'StudentLab',
      debugShowCheckedModeBanner: false,

      theme: ThemeData.dark().copyWith(

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandNightBlue,
          brightness: Brightness.dark,
        ),

        scaffoldBackgroundColor: AppColors.darkElegance,
        appBarTheme: AppColors.nightAppBarTheme,
        cardTheme: AppColors.elegantCardTheme,
        bottomNavigationBarTheme: AppColors.nightBottomNavTheme
      ),
      home: const HomePage(),
    );
  }
}
