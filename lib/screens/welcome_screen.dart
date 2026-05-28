import 'package:flutter/material.dart';

const Color _kPink = Color(0xFFEA1F86);
const Color _kNavyDeep = Color(0xFF1F2070);

class _WedgeClipper extends CustomClipper<Path> {
  const _WedgeClipper(this.rightCut);
  final double rightCut;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * rightCut)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_WedgeClipper o) => o.rightCut != rightCut;
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kNavyDeep,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              // Pink gradient diagonal wedge (46% height)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: h * 0.46,
                child: ClipPath(
                  clipper: const _WedgeClipper(0.84),
                  child: Container(color: _kPink),
                ),
              ),

              // Top headline content in pink section
              Positioned(
                top: topPad + 48,
                left: 28,
                right: 28,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Ontdek elkaars keuzes.',
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
                        'Vragen & opdrachten die echte gesprekken starten.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom content in navy section
              Positioned(
                top: h * 0.43,
                bottom: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, 28, 28, 24 + bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureRow(
                          icon: Icons.people_rounded,
                          iconBg: Colors.white.withValues(alpha: 0.12),
                          iconBorder: true,
                          title: 'Speel samen',
                          subtitle: 'Geschikt voor groepen van alle groottes',
                        ),
                        const _Divider(),
                        _FeatureRow(
                          icon: Icons.menu_book_rounded,
                          iconBg: Colors.white.withValues(alpha: 0.12),
                          iconBorder: true,
                          title: 'Ontdek verhalen',
                          subtitle: 'Deel ervaringen en luister naar anderen',
                        ),
                        const _Divider(),
                        _FeatureRow(
                          icon: Icons.record_voice_over_rounded,
                          iconBg: Colors.white.withValues(alpha: 0.12),
                          iconBorder: true,
                          title: 'Debatteren',
                          subtitle: 'Vind samen de beste oplossing',
                        ),
                        const Spacer(),
                        Text(
                          '*Fysiek bordspel is nodig om deze app te gebruiken.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.4),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _NextButton(
                          onTap: () => Navigator.pushNamed(context, '/config'),
                        ),
                      ],
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withValues(alpha: 0.1),
      height: 1,
      thickness: 1,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.iconBorder = false,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool iconBorder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              border: iconBorder
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    )
                  : null,
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.3,
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
  const _NextButton({required this.onTap});
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Volgende',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
