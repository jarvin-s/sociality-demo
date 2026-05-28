import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Color _kPink = Color(0xFFEA1F86);
const Color _kNavyDeep = Color(0xFF1F2070);
const Color _kPinkLight = Color(0xFFFF67B5);

// Diagonal cut: polygon(0 0, 100% 0, 100% 88%, 0 100%)
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.88)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_DiagonalClipper old) => false;
}

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _kNavyDeep,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              // Pink diagonal wedge (top 58% of screen)
              Positioned(
                top: 0, left: 0, right: 0,
                height: h * 0.58,
                child: ClipPath(
                  clipper: _DiagonalClipper(),
                  child: Container(color: _kPink),
                ),
              ),

              // HOST tap zone — top half
              Positioned(
                top: 0, left: 0, right: 0,
                height: h * 0.5,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pushNamed(context, '/overview'),
                ),
              ),

              // JOIN tap zone — bottom half
              Positioned(
                top: h * 0.5, left: 0, right: 0, bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pushNamed(context, '/join'),
                ),
              ),

              // Visual content — non-interactive so taps pass to zones above
              IgnorePointer(
                child: Stack(
                  children: [
                    // Eyebrow label
                    Positioned(
                      top: topPad + 74,
                      left: 0, right: 0,
                      child: const Text(
                        'HOE WIL JE SPELEN?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // HOST content (pink half)
                    Positioned(
                      top: topPad + 114,
                      left: 28, right: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/crown.svg',
                                width: 34, height: 34,
                                colorFilter: const ColorFilter.mode(
                                  _kPink, BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Hosten',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              height: 0.95,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Organiseer een nieuw spel en nodig anderen uit om mee te doen.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Row(
                            children: [
                              Text(
                                'NIEUW SPEL STARTEN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // JOIN content (navy half)
                    Positioned(
                      bottom: 90,
                      left: 28, right: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: _kPink,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: Icon(Icons.group_rounded,
                                  color: Colors.white, size: 34),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Meedoen',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              height: 0.95,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sluit je aan via een PIN-code of scan een QR-code.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.78),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Text(
                                'MEEDOEN MET CODE',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: _kPinkLight,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded,
                                  color: _kPinkLight, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Back button — sits above tap zones
              Positioned(
                top: topPad + 12,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 22),
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
