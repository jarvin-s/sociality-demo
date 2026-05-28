import 'package:flutter/material.dart';
import 'package:sociality/screens/participant_screen.dart';

const Color _kPink = Color(0xFFEA1F86);
const Color _kNavyDeep = Color(0xFF1F2070);

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

class _HostNameScreenState extends State<HostNameScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ctrl.dispose();
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
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kNavyDeep,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: _fade,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      topPad + 90,
                      28,
                      24 + bottomPad,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Jouw naam',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              height: 0.93,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Kies de naam die deelnemers bij jou zien. Jij bent de host van dit spel.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),

                          SizedBox(height: h * 0.16),

                          _SituationPill(title: widget.situationTitle),
                          const SizedBox(height: 18),

                          TextFormField(
                            controller: _controller,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [
                              AutofillHints.name,
                              AutofillHints.nickname,
                            ],
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: _kPink,
                            decoration: InputDecoration(
                              hintText: 'bijvoorbeeld: Sam',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontStyle: FontStyle.italic,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _kPink,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.5,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              errorStyle: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                          const SizedBox(height: 28),
                          _NextButton(label: 'Doorgaan', onTap: _onContinue),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: topPad + 12,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SituationPill extends StatelessWidget {
  const _SituationPill({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.place_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Situatie',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  const _NextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _kPink,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}
