import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_blue.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 250,
                  height: 200,
                ),

                // Welcome Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Welkom bij Sociality',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sociality is ontwikkeld om mensen dichter bij elkaar te brengen. Door middel van vragen en opdrachten leer je elkaar beter kennen en versterk je sociale banden in je buurt, op je werk of binnen je vereniging.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),

                      featureItem(
                        title: 'Speel samen',
                        subtitle: 'Geschikt voor 4 spelers',
                        icon: Icons.people,
                      ),

                      featureItem(
                        title: 'Ontdek verhalen',
                        subtitle: 'Deel ervaringen en luister naar anderen',
                        icon: Icons.menu_book,
                      ),

                      featureItem(
                        title: 'Debatteren',
                        subtitle: 'Vind samen de beste oplossing',
                        icon: Icons.record_voice_over,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        '*Fysiek bordspel is nodig om deze applicatie te gebruiken.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // Next button
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/config');
                  },
                  child: SizedBox(
                    width: 190,
                    height: 42,
                    child: Stack(
                      children: [
                        // Shadow layer
                        Positioned(
                          bottom: 0,
                          left: 3,
                          right: 0,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 182, 6, 100),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                        // Main button layer
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 3,
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE82A91),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Volgende',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reuseable item for feature icons
Widget featureItem({
  required String title,
  required String subtitle,
  required IconData icon, }) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon box
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE82A91), size: 26),
        ),

        const SizedBox(width: 6),

        // Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
