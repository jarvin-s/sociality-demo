import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  // If true, position is final
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    // Each widget has a different duration/delay so they stagger naturally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

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
              Image.asset('assets/images/logo.png', width: 250, height: 230),

              // Title
              AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: const Column(
                  children: [
                    Text(
                      'Hoe wil je spelen?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Host je eigen spel of meedoen met anderen!',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // First button
              AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, 0.3),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: GameOptionButton(
                    title: 'Spel hosten',
                    subtitle:
                        'Organiseer een nieuw spel en nodig anderen uit om mee te doen.',
                    leading: SvgPicture.asset(
                      'assets/crown.svg',
                      width: 26,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/overview'),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Second button, longer duration
              AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, 0.3),
                duration: const Duration(
                  milliseconds: 700,
                ),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(
                    milliseconds: 600,
                  ),
                  child: GameOptionButton(
                    title: 'Meedoen',
                    subtitle:
                        'Sluit je aan bij een bestaand spel via een PIN-code of QR-code.',
                    leading: const Icon(Icons.group, color: Color(0xFFE82A91)),
                    onTap: () => Navigator.pushNamed(context, '/join'),
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

class GameOptionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

  const GameOptionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  @override
  State<GameOptionButton> createState() => _GameOptionButtonState();
}

class _GameOptionButtonState extends State<GameOptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: double.infinity,
          height: 100,
          child: Stack(
            children: [
              // Shadow layer
              Positioned(
                bottom: 0,
                left: 2,
                right: 0,
                child: Container(
                  height: 94,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 182, 6, 100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Top layer
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                top: _isPressed ? 5 : 0,
                left: 0,
                right: _isPressed ? 0 : 5,
                child: Container(
                  height: 94,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE82A91),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Icon box
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: widget.leading),
                      ),
                      const SizedBox(width: 15),
                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
    );
  }
}
