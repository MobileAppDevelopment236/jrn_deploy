// lib/screens/main/main_screen.dart
import 'package:flutter/material.dart';
//import 'package:jrr_immigration_app/screens/home_screen.dart';
//import 'package:jrr_immigration_app/screens/dashboard_screen.dart';
import 'package:jrr_immigration_app/screens/tabbed_dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simply return your DashboardScreen from home_screen.dart
    return const TabbedDashboardScreen();
  }
}