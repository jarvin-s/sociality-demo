import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool isScanning = false;
  bool _hasScanned = false;

  void _attemptJoin(String code) {
    if (code.isNotEmpty) {
      debugPrint('Joining game with code: $code');
      // Possible to send this to firebase
      Navigator.pushNamed(context, '/home');
    } else {
      // Show simple error if user attemps to join with empty PIN
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer eerst een geldige code in!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF273583),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Logo
                Image.asset('assets/images/logo.png', width: 184, height: 184),

                const SizedBox(height: 10),

                // Title
                const Text(
                  'Hoe wil je deelnemen?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                // Subtitle
                const Text(
                  'Voer de PIN-code in of scan de QR code om deel te nemen!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),

                const SizedBox(height: 25),

                // PIN box (hidden when scanning)
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: isScanning
                      ? const SizedBox.shrink() // collapses away
                      : Container(
                          width: double.infinity,
                          height: 155,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Voer uw PIN-code in',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              
                              const SizedBox(height: 8),

                              // PIN Input Field
                              Container(
                                width: 190,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6E1E1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: _pinController,
                                  keyboardType: TextInputType.number, // Shows the number pad
                                  textAlign: TextAlign.center,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'PIN-code',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 18,
                                    ),
                                    border: InputBorder.none, // Removes the default underline
                                    counterText:"", // Hides the character counter at the bottom
                                    contentPadding: EdgeInsets.symmetric(vertical: 7),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 1, // Spreads the numbers out nicely
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // QR box (expands when scanning)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: isScanning ? 420 : 155,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    // Prevents internal overflow during animation
                    physics:
                        const NeverScrollableScrollPhysics(), // Internal scroll disabled
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20), // Top padding for the title
                        const Text(
                          'Scan QR-code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (isScanning)
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 247,
                                  height: 300,
                                  child: MobileScanner(
                                    onDetect: (capture) {
                                      if (_hasScanned) return;
                                      final String? code = capture.barcodes.first.rawValue;
                                      if (code != null) {
                                        _hasScanned = true;
                                        _attemptJoin(code);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => setState(() {
                                  isScanning = false;
                                  _hasScanned = false;
                                }),
                                child: const Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    'Annuleren',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          // Tap to scan
                          GestureDetector(
                            onTap: () => setState(() => isScanning = true),
                            child: Container(
                              width: 180,
                              height: 54,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Tik om te scannen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Join button
                GestureDetector(
                  onTap: () {
                    // Get the text from the PIN controller
                    String enteredPin = _pinController.text;
                    _attemptJoin(enteredPin);
                  },
                  child: SizedBox(
                    width: 189,
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
                        // Main button
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
                              'Meedoen',
                              style: TextStyle(
                                fontSize: 16,
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}