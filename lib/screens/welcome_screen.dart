import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _expandAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    // Start the expansion after the screen loads
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_blue.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 250,
                  height: 230,
                ),

                // Welcome card
                SizeTransition(
                  sizeFactor: _expandAnim,
                  axis: Axis.vertical,
                  axisAlignment: 0.0, 
                  child: FadeTransition(
                    opacity: _expandAnim,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildCardContent(),
                    ),
                  ),
                ),

                // Volgende button
                const SizedBox(height: 40),
                _buildNextButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Welkom bij Sociality',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Colors.black),
        ),

        const SizedBox(height: 10),
        
        const Text(
          'Sociality is ontwikkeld om mensen dichter bij elkaar te brengen. Door middel van vragen en opdrachten leer je elkaar beter kennen en versterk je sociale banden in je buurt, op je werk of binnen je vereniging.',
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),

        const SizedBox(height: 10),

        featureItem(title: 'Speel samen', subtitle: 'Geschikt voor 4 spelers', icon: Icons.people),
        featureItem(title: 'Ontdek verhalen', subtitle: 'Deel ervaringen en luister naar anderen', icon: Icons.menu_book),
        featureItem(title: 'Debatteren', subtitle: 'Vind samen de beste oplossing', icon: Icons.record_voice_over),

        const SizedBox(height: 20),

        const Text(
          '*Fysiek bordspel is nodig om deze applicatie te gebruiken.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/config'),
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: 190,
          height: 42,
          child: Stack(
            children: [
              Positioned(
                bottom: _isPressed ? 2 : 0,
                left: 3,
                right: 0,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 182, 6, 100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                top: _isPressed ? 2 : 0,
                left: 0,
                right: 3,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE82A91),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Volgende',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable item (exactly as requested)
Widget featureItem({required String title, required String subtitle, required IconData icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFE82A91), size: 26),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black87)),
            ],
          ),
        ),
      ],
    ),
  );
}