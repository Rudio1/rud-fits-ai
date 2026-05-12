import 'package:flutter/material.dart';

import 'package:rud_fits_ai/features/home/screens/home_screen.dart';
import 'package:rud_fits_ai/features/meal_logs/screens/daily_meals_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _index;
  int _mealsRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          DailyMealsScreen(refreshToken: _mealsRefreshToken),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          final prev = _index;
          setState(() {
            _index = i;
            if (i == 1 && prev != 1) {
              _mealsRefreshToken++;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Refeições',
          ),
        ],
      ),
    );
  }
}
