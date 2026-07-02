import 'package:flutter/material.dart';
import 'package:fe/layers/homeLayer.dart';
import 'package:fe/theme/nightTheme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(){
    switch(_selectedIndex){
      case 0:
        return '10000xxxx3';
      case 1:
        return '(grado e punti lab di 10000xxxx3)';
      case 2:
        return '(punti e grado challange di 10000xxxx3)';
      case 3: 
        return '(punti e preparazione ripasso di 10000xxxx3)';
      default:
        return '10000xxxx3';
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.darkElegance,
      
      appBar: AppBar(
        backgroundColor: AppColors.brandNightBlue, 
        foregroundColor: AppColors.pearlWhite,
        elevation: AppColors.nightAppBarTheme.elevation,
        centerTitle: AppColors.nightAppBarTheme.centerTitle,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _getAppBarTitle(),
            key: ValueKey<int>(_selectedIndex),
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 20,
            )
          )
        )
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {

          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },

          child: IndexedStack(
          key: ValueKey<int>(_selectedIndex), 
          index: _selectedIndex,
          children: [
            HomeLayer(), 
            
            // Layer 1, 2, 3: Placeholder temporanei 
            const Center(child: Text('🧪 Laboratorio', style: TextStyle(color: Colors.white, fontSize: 18))),
            const Center(child: Text('👥 Challange', style: TextStyle(color: Colors.white, fontSize: 18))),
            const Center(child: Text('👤 Profilo', style: TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
      ),

            bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.nightBottomNavTheme.backgroundColor, 
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.science_outlined), activeIcon: Icon(Icons.science), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.connect_without_contact_outlined), activeIcon: Icon(Icons.connect_without_contact), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: ''),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
      );
  }
}