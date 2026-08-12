
import 'package:flutter/material.dart';
import 'package:fe/layers/homeLayer.dart';
import 'package:fe/theme/nightTheme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkElegance,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue,
        foregroundColor: AppColors.pearlWhite,
        elevation: AppColors.nightAppBarTheme.elevation,

        // Nessun titolo centrale.
        centerTitle: false,

        // ========================================================
        // LOGO STUDENTLAB
        // ========================================================

        leading: IconButton(
          icon: const Icon(
            Icons.school_rounded,
          ),
          tooltip: 'Home',
          onPressed: () {
            // La Home è già aperta.
            //
            // In futuro, quando avremo una navigazione
            // completa, questo pulsante porterà sempre
            // alla Home principale.
          },
        ),

        // ========================================================
        // AUTENTICAZIONE
        // ========================================================

        actions: [
          // ------------------------------------------------------
          // ACCEDI
          // ------------------------------------------------------

          _AuthButton(
            text: 'Accedi',
            filled: false,
            onPressed: () {
              // TODO:
              // Aprire LoginPage
            },
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // SIGN UP
          // ------------------------------------------------------

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

      // ==========================================================
      // HOME CONTENT
      // ==========================================================

      body: HomeLayer(),
    );
  }
}


// ==================================================================
// AUTH BUTTON
// ==================================================================

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
          // ------------------------------------------------------
          // SFONDO
          // ------------------------------------------------------

          backgroundColor: filled
              ? AppColors.skyBlue
              : Colors.transparent,

          // ------------------------------------------------------
          // BORDO
          // ------------------------------------------------------

          side: BorderSide(
            color: AppColors.skyBlue,
            width: 1.2,
          ),

          // ------------------------------------------------------
          // FORMA
          // ------------------------------------------------------

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          // ------------------------------------------------------
          // SPAZIATURA
          // ------------------------------------------------------

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