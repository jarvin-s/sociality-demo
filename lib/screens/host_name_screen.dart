import 'package:flutter/material.dart';
import 'package:sociality/screens/participant_screen.dart';

const Color _kHostNavy = Color(0xFF233580);
const Color _kHostPink = Color(0xFFE82A91);

class HostNameScreen extends StatefulWidget {
  const HostNameScreen({
    super.key,
    required this.situationTitle,
    required this.currentStory,
  });

  final String situationTitle;
  final int currentStory;

  @override
  State<HostNameScreen> createState() => _HostNameScreenState();
}

class _HostNameScreenState extends State<HostNameScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Controls the button press effect
  bool _isPressed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _controller.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ParticipantScreen(
          hostName: name,
          currentStory: widget.currentStory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kHostNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Situatie: ${widget.situationTitle}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Spel Host',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Jij bent de host van dit spel. Kies een naam die deelnemers bij jou zien.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: const Color.fromARGB(255, 191, 191, 191).withValues(alpha: 0.95),
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name, AutofillHints.nickname],
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w100,
                    fontStyle: FontStyle.italic,
                  ),
                  cursorColor: _kHostPink,
                  decoration: InputDecoration(
                    hintText: 'Username:',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kHostPink, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vul je naam in';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _onContinue(),
                ),

                const SizedBox(height: 24),

                // Doorgaan button
                GestureDetector(
                  onTap: _onContinue,
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedScale(
                    scale: _isPressed ? 0.98 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: Stack(
                        children: [

                          // Shadow layer
                          Positioned(
                            bottom: 0,
                            left: 2,
                            right: 0,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 182, 6, 100),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),

                          // Top layer, shifts down on press
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 100),
                            top: _isPressed ? 5 : 0,
                            left: 0,
                            right: _isPressed ? 0 : 5,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: _kHostPink,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Doorgaan',
                                style: TextStyle(
                                  fontSize: 20,
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
    );
  }
}