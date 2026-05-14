import 'package:flutter/material.dart';

import 'package:rud_fits_ai/core/icons/app_icons.dart';
import 'package:rud_fits_ai/features/home/screens/home_screen.dart';
import 'package:rud_fits_ai/features/meal_logs/screens/daily_meals_screen.dart';
import 'package:rud_fits_ai/features/profile/screens/profile_screen.dart';

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
    _index = widget.initialIndex.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          DailyMealsScreen(refreshToken: _mealsRefreshToken),
          const ProfileScreen(),
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
            icon: Icon(AppIcons.navHome),
            selectedIcon: Icon(AppIcons.navHomeActive),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.navMeals),
            selectedIcon: Icon(AppIcons.navMealsActive),
            label: 'Refeições',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.navProfile),
            selectedIcon: Icon(AppIcons.navProfileActive),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
