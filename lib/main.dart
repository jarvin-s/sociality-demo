import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

          // Home screen
          case '/':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );

          // Welcome screen
          case '/welcome':
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );

          // Config screen
          case '/config':
            return MaterialPageRoute(
              builder: (context) => const ConfigScreen(),
            );

          // Join screen
          case '/join':
            return MaterialPageRoute(
              builder: (context) => JoinScreen(
                initialJoinCode: kIsWeb
                    ? Uri.base.queryParameters['code']
                    : null,
              ),
            );

          // Overview screen
          case '/overview':
            return MaterialPageRoute(
              builder: (context) => const OverviewScreen(),
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
