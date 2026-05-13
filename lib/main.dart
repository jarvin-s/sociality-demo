import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sociality/screens/home_screen.dart';
import 'package:sociality/screens/join_screen.dart';
import 'firebase_options.dart';

// import pages
import 'screens/welcome_screen.dart';
import 'screens/config_screen.dart';
import 'screens/overview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SocialityApp());
}

class SocialityApp extends StatelessWidget {
  const SocialityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sociality',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink, fontFamily: 'SF Pro Text'),
      initialRoute: '/',

      // Navigation
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          // Home screen
          case '/':
            page = const HomeScreen();

          // Welcome screen
          case '/welcome':
            page = const WelcomeScreen();

          // Config screen
          case '/config':
            page = const ConfigScreen();

          // Join screen
          case '/join':
            page = const JoinScreen();

          // Overview screen
          case '/overview':
            page = const OverviewScreen();

          default:
            page = const Scaffold(body: Center(child: Text('Route not found')));
        }

        // Slide animation for all transitions
        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide =
                Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            return SlideTransition(position: slide, child: child);
          },
        );
      },
    );
  }
}