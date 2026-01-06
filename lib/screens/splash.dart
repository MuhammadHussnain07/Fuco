import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
       color:  const Color(0xFF1D1D1D),
        child: Center(child:
         Image.asset('assets/images/Splash Logo.png'),
         ),
      ),
    );
  }
}