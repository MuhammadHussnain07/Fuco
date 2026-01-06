import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class GoogleNavScreen extends StatefulWidget {
  const GoogleNavScreen({super.key});

  @override
  State<GoogleNavScreen> createState() => _GoogleNavScreenState();
}

class _GoogleNavScreenState extends State<GoogleNavScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:GNav(
        backgroundColor:Colors.black,
        color: Colors.white,
        activeColor: Colors.white,
        tabBackgroundColor: Colors.grey.shade800,
        gap: 5,
        tabs: const
      [
        GButton(icon: Icons.home,text: 'Home',),
        GButton(icon: Icons.settings,text: 'Setting',),
        GButton(icon: Icons.history,text: 'History',),
        GButton(icon: Icons.map,text: 'Location Search',),
      ]
      ),
    );
  }
}