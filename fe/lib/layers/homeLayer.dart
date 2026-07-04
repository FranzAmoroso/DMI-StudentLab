import 'package:fe/quiz/subjectSelection.dart';
import 'package:flutter/material.dart';
import 'package:fe/theme/nightTheme.dart'; 

class FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isComingSoon; 

  FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isComingSoon = false, 
  });
}

class HomeLayer extends StatelessWidget {
  HomeLayer({super.key});
  
  final List<FeatureCard> _featureCards = [
    FeatureCard(
      title: 'Esercitazione',
      description: 'Allena la tua mente senza lo stress del tempo, filtrando le domande per singoli argomenti della materia.',
      icon: Icons.quiz,
      color: AppColors.slateMidnight, 
      isComingSoon: false,
    ),
    FeatureCard(
      title: 'Simulazione Esame', 
      description: 'Mettiti alla prova con i veri compiti d\'esame d\'appello, aggiornati in base al professore del tuo corso.',
      icon: Icons.checklist,
      color: AppColors.royalIndigo, 
      isComingSoon: true,
    ),
    FeatureCard(
      title: 'Ripasso', 
      description: 'Rivedi i concetti più difficili e approfondisci gli argomenti delle domande che hai sbagliato.', // da sistemare
      icon: Icons.warning_amber_rounded,
      color: AppColors.charcoalGrey, 
      isComingSoon: true,
    ),
    FeatureCard(
      title: 'Definizioni',
      description: 'Glossario completo dei termini e concetti chiave del corso.',
      icon: Icons.menu_book,
      color: AppColors.eleganceDeepNavy, 
      isComingSoon: true, 
    ),
    FeatureCard(
      title: 'Materiale',
      description: 'Accedi a dispense, slide e documenti utili per supportare il tuo studio.',
      icon: Icons.cloud,
      color: AppColors.darkElegance, 
      isComingSoon: true, 
    ),
    FeatureCard(
      title: 'Altri studenti',
      description: 'Connettiti con i tuoi colleghi di corso e collaborate.',
      icon: Icons.people,
      color: AppColors.slateGrey, 
      isComingSoon: true, 
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2; 
    if (screenWidth > 600 && screenWidth <= 900) {
      crossAxisCount = 3; 
    } else if (screenWidth > 900) {
      crossAxisCount = 4; 
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: _featureCards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, 
          crossAxisSpacing: 16.0,         
          mainAxisSpacing: 16.0,          
          childAspectRatio: 1.0,          
        ),
        itemBuilder: (context, index) {
          return _buildGridCard(context, _featureCards[index], index);
        },
      ),
    );
  }

  
Widget _buildGridCard(BuildContext context, FeatureCard card, int index) {
  final ValueNotifier<double> shakeOffset = ValueNotifier<double>(0.0);
  final ValueNotifier<double> cardScale = ValueNotifier<double>(1.0);

  Widget cardBody = ValueListenableBuilder<double>(
    valueListenable: cardScale,
    builder: (context, scale, child) {
      return AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150), 
        curve: Curves.easeOutCubic, 
        child: Card(
          elevation: AppColors.elegantCardTheme.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        card.color,
                        card.color.withOpacity(0.8),
                        AppColors.darkElegance, 
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.translucentWhite, 
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              card.icon,
                              size: 26,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pureWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.pureWhite.withOpacity(card.isComingSoon ? 0.4 : 0.7),
                              fontWeight: FontWeight.w300,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      cardScale.value = 1.05; 
                    },
                    onTapUp: (_) {
                      cardScale.value = 1.0;
                    },
                    onTapCancel: () {
                      cardScale.value = 1.0;
                    },
                    onTap: () async {
                      if (card.isComingSoon) {
                        if (shakeOffset.value != 0.0) return;
                        shakeOffset.value = 6.0;
                        await Future.delayed(const Duration(milliseconds: 50));
                        shakeOffset.value = -6.0;
                        await Future.delayed(const Duration(milliseconds: 50));
                        shakeOffset.value = 4.0;
                        await Future.delayed(const Duration(milliseconds: 50));
                        shakeOffset.value = -4.0;
                        await Future.delayed(const Duration(milliseconds: 50));
                        shakeOffset.value = 0.0;
                      } else {
                        if (index == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SubjectSelection(department: "DMI", course: "L-31")),
                          );
                        }
                      }
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

  return Stack(
    children: [
      cardBody,
      
      Positioned(
        top: 0,
        right: 0,
        child: ValueListenableBuilder<double>(
          valueListenable: shakeOffset,
          builder: (context, offset, child) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: offset),
              duration: const Duration(milliseconds: 40), 
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value, 0),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
                child: CustomPaint(
                  size: const Size(65, 65),
                  painter: BannerPainter(
                    message: "SOON",
                    textDirection: TextDirection.ltr,
                    location: BannerLocation.topEnd,
                    layoutDirection: TextDirection.ltr,
                    color: AppColors.skyBlue,
                    textStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandNightBlue,
                      letterSpacing: 1.0,
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

}
