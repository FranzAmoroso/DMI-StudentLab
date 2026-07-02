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
      title: 'Quiz',
      description: 'Metti alla prova le tue conoscenze con domande a risposta multipla.',
      icon: Icons.quiz,
      color: AppColors.royalIndigo, 
      isComingSoon: false,
    ),
    FeatureCard(
      title: 'Definizioni',
      description: 'Glossario completo dei termini e concetti chiave del corso.',
      icon: Icons.menu_book,
      color: AppColors.brandNightBlue, 
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

  
  Widget _buildGridCard(BuildContext context,FeatureCard card, int index) {
    Widget cardContent = Card(
      elevation: AppColors.elegantCardTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          
          onTap: card.isComingSoon 
              ? null 
              : () {
                  if (index == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubjectSelection(department: "DMI", course: "L-31")),
                    );
                  }
                },
          child: Padding(
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
                      decoration: BoxDecoration(
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
        ),
      ),
    );

    if (card.isComingSoon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20), 
        child: Banner(
          message: "SOON",
          location: BannerLocation.topEnd, 
          color: AppColors.skyBlue, 
          textStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.brandNightBlue, 
            letterSpacing: 1.0,
          ),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
