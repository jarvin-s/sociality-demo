import 'package:flutter/material.dart';

// import pages
import 'pages/start_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const SocialityApp());
}

class SocialityApp extends StatelessWidget {
  const SocialityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sociality',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'SF Pro Text',
      ),
      initialRoute: '/',

      // Navigation
      onGenerateRoute: (settings) {
        switch (settings.name) {

          // Welcome screen
          case '/':
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );

          // Home screen
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );

          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text('Route not found'),
                ),
              ),
            );
        }
      },
    );
  }
}
