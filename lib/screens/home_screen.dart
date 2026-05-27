import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  final _player = AudioPlayer();

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Called when finger touches button
  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  // Called when finger lifts off button
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  // Called if finger slides off button
  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  void _navigate() {
    _player.play(AssetSource('sounds/click.wav'));
    Navigator.pushNamed(context, '/welcome');
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
          child: Stack(
            children: [

              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Image.asset(
                          'assets/images/logo.png',
                          width: 250,
                          height: 230,
                        ),

                        const SizedBox(height: 40),

                        // Speel nu button
                        GestureDetector(
                          onTap: _navigate,
                          onTapDown: _onTapDown,
                          onTapUp: _onTapUp,
                          onTapCancel: _onTapCancel,

                          child: AnimatedScale(
                            scale: _isPressed ? 0.95 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,

                            child: SizedBox(
                              width: 190,
                              height: 42,
                              child: Stack(
                                children: [

                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 100),
                                    bottom: _isPressed ? 2 : 0,
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

                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 100),
                                    top: _isPressed ? 2 : 0,
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
                                        'Speel nu',
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
                        ),

                      ],
                    ),
                  ),
                ),
              ),

              // Footer pinned to the bottom of the screen
              const Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Text(
                  'InnerGames Sociality ©',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}