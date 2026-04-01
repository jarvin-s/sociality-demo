import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sociality/screens/story_play_screen.dart';

const Color _kParticipantNavy = Color(0xFF2A337E);
const Color _kParticipantPink = Color(0xFFE9338F);

class ParticipantScreen extends StatelessWidget {
  const ParticipantScreen({super.key});

  static const String _gameCode = '3FD21';
  static const int _participantCount = 3;
  static const List<String> _participants = [
    'Jij (Host)',
    'Test 1',
    'Test 2',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParticipantNavy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const _ParticipantLogoFallback();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Spelcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ZigzagBorderBox(
                      strokeWidth: 3.5,
                      period: 10,
                      amplitude: 3.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _kParticipantPink,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          _gameCode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Deelnemers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_participantCount personen aangemeld',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _kParticipantPink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: _participants
                            .map(
                              (name) => Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _StartenButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const StoryPlayScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantLogoFallback extends StatelessWidget {
  const _ParticipantLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          size: 100,
          color: _kParticipantPink,
        ),
        const SizedBox(height: 4),
        Text(
          'SOCIALITY',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kParticipantPink,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(
                color: Colors.white,
                offset: Offset(1.5, 1.5),
                blurRadius: 0,
              ),
              Shadow(
                color: Colors.white,
                offset: Offset(-1.5, -1.5),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZigzagBorderBox extends StatelessWidget {
  const _ZigzagBorderBox({
    required this.child,
    required this.strokeWidth,
    required this.period,
    required this.amplitude,
  });

  final Widget child;
  final double strokeWidth;
  final double period;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    final pad = strokeWidth + amplitude;
    return CustomPaint(
      painter: _ZigzagRectPainter(
        color: Colors.white,
        strokeWidth: strokeWidth,
        period: period,
        amplitude: amplitude,
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: child,
      ),
    );
  }
}

class _ZigzagRectPainter extends CustomPainter {
  _ZigzagRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.period,
    required this.amplitude,
  });

  final Color color;
  final double strokeWidth;
  final double period;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect = Rect.fromLTWH(half, half, size.width - strokeWidth, size.height - strokeWidth);
    final path = _buildZigzagRectPath(rect);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  Path _buildZigzagRectPath(Rect rect) {
    final path = Path();
    var x = rect.left;
    var y = rect.top;
    path.moveTo(x, y);

    var bumpUp = true;
    while (x < rect.right) {
      final step = math.min(period, rect.right - x);
      x += step;
      path.lineTo(x, rect.top + (bumpUp ? -amplitude : amplitude));
      bumpUp = !bumpUp;
    }
    path.lineTo(rect.right, rect.top);

    bumpUp = true;
    y = rect.top;
    while (y < rect.bottom) {
      final step = math.min(period, rect.bottom - y);
      y += step;
      path.lineTo(rect.right + (bumpUp ? amplitude : -amplitude), y);
      bumpUp = !bumpUp;
    }
    path.lineTo(rect.right, rect.bottom);

    bumpUp = false;
    x = rect.right;
    while (x > rect.left) {
      final step = math.min(period, x - rect.left);
      x -= step;
      path.lineTo(x, rect.bottom + (bumpUp ? -amplitude : amplitude));
      bumpUp = !bumpUp;
    }
    path.lineTo(rect.left, rect.bottom);

    bumpUp = true;
    y = rect.bottom;
    while (y > rect.top) {
      final step = math.min(period, y - rect.top);
      y -= step;
      path.lineTo(rect.left + (bumpUp ? amplitude : -amplitude), y);
      bumpUp = !bumpUp;
    }
    path.lineTo(rect.left, rect.top);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ZigzagRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        period != oldDelegate.period ||
        amplitude != oldDelegate.amplitude;
  }
}

class _StartenButton extends StatelessWidget {
  const _StartenButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: _kParticipantPink,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B1A50).withValues(alpha: 0.55),
                offset: const Offset(0, 5),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const Text(
              'Starten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
