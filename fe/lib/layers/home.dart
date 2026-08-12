
import 'package:flutter/material.dart';
import 'package:fe/layers/homeLayer.dart';
import 'package:fe/theme/nightTheme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pearlWhite,
        elevation: AppColors.nightAppBarTheme.elevation,

        // Nessun titolo centrale.
        centerTitle: false,

        leading: IconButton(
          icon: Image.asset(
            'assets/icons/favicon.png',
            width: 50,
            height: 50,
          ),
          tooltip: 'Home',
          onPressed: () {
            // Torna alla Home
          },
        ),
        actions: [
          _AuthButton(
            text: 'Accedi',
            filled: false,
            onPressed: () {
              // TODO:
              // Aprire LoginPage
            },
          ),

          const SizedBox(width: 8),

          _AuthButton(
            text: 'Sign Up',
            filled: true,
            onPressed: () {
              // TODO:
              // Aprire SignUpPage
            },
          ),

          const SizedBox(width: 16),
        ],
      ),

      body: HomeLayer(),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String text;
  final bool filled;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.text,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,

      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(

          backgroundColor: filled
              ? AppColors.skyBlue
              : Colors.transparent,

          side: BorderSide(
            color: AppColors.skyBlue,
            width: 1.2,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),

          elevation: 0,
        ),

        child: Text(
          text,
          style: TextStyle(
            color: filled
                ? AppColors.brandNightBlue
                : AppColors.skyBlue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}