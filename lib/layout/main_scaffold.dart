import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/home/home_screen.dart';
import '../screens/data/data_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final ValueNotifier<bool> _dataRefreshNotifier = ValueNotifier(false);

  late final List<Widget> _screens = [
    const HomeScreen(),
    DataScreen(refreshNotifier: _dataRefreshNotifier),
    const ProfileScreen(),
  ];

  void _onTabTap(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _dataRefreshNotifier.value = !_dataRefreshNotifier.value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
