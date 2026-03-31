import 'package:flutter/material.dart';
import 'package:sociality/screens/join_screen.dart';
import 'overview_screen.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF273583),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Image
              Image.asset(
                'assets/images/logo.png', // change if needed
                width: 250,
                height: 230,
              ),

              // Title
              const Text(
                'Hoe wil je spelen?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 5),

              // Subtitle
              const Text(
                'Host je eigen spel of meedoen met anderen!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Buttons
              gameOption(
                title: 'Spel hosten',
                subtitle: 'Organiseer een nieuw spel en nodig anderen uit om mee te doen. Je kiest de categorieën en bepaalt het tempo.',
                icon: Icons.calendar_view_day_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OverviewScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              gameOption(
                title: 'Meedoen',
                subtitle: 'Sluit je aan bij een bestaand spel via een PIN-code of door een QR-code te scannen!.',
                icon: Icons.group,
                onTap: () {
                  Navigator.pushNamed(context, '/join');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget gameOption({
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE82A91),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE82A91),
            ),
          ),

          const SizedBox(width: 15),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}