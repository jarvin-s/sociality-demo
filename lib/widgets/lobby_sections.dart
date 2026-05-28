import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

const Color lobbyPink = Color(0xFFEA1F86);
const Color lobbyNavy = Color(0xFF1F2070);

class _LobbyWedgeClipper extends CustomClipper<Path> {
  const _LobbyWedgeClipper(this.rightCut);
  final double rightCut;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * rightCut)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_LobbyWedgeClipper o) => o.rightCut != rightCut;
}

/// Shared lobby scaffold: navy background, pink wedge, fade, back button.
class LobbyShell extends StatelessWidget {
  const LobbyShell({
    super.key,
    required this.fade,
    required this.child,
  });

  final Animation<double> fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: lobbyNavy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: FadeTransition(opacity: fade, child: child),
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

/// Pink spinner + "Live bijgewerkt" row used on both lobby screens.
class LobbyLiveIndicator extends StatelessWidget {
  const LobbyLiveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: lobbyPink.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Live bijgewerkt',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered game code without a card background.
class LobbyGameCodeDisplay extends StatelessWidget {
  const LobbyGameCodeDisplay({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Spelcode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w100,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          code.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 8,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

/// Centered QR code without a card or white box background.
class LobbyQrDisplay extends StatelessWidget {
  const LobbyQrDisplay({
    super.key,
    required this.payload,
    this.size = 200,
  });

  final String payload;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Scan om mee te doen',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w100,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        QrImageView(
          data: payload,
          version: QrVersions.auto,
          size: size,
          backgroundColor: Colors.transparent,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.white,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Single grouped panel: header with count + list of joined players.
class LobbyParticipantsGroup extends StatelessWidget {
  const LobbyParticipantsGroup({super.key, required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final count = names.length;
    final countLabel = '$count ${count == 1 ? 'persoon' : 'personen'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lobbyPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.people_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deelnemers',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          if (names.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Text(
                'Nog geen andere deelnemers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            ColoredBox(
              color: Colors.white.withValues(alpha: 0.04),
              child: Column(
                children: [
                  for (var i = 0; i < names.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 68,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    _ParticipantListTile(name: names[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticipantListTile extends StatelessWidget {
  const _ParticipantListTile({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lobbyPink.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
