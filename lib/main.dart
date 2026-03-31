import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// import pages
import 'screens/welcome_screen.dart';
import 'screens/config_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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

          case '/config':
            return MaterialPageRoute(
              builder: (context) => const ConfigScreen(),
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
