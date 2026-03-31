import 'package:flutter/material.dart';

const Color _kOverviewNavy = Color(0xFF233580);

const Color _kSituationPink = Color(0xFFE93D81);

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  static const List<_SituationItem> _situations = [
    _SituationItem(title: 'Speeltuin'),
    _SituationItem(title: 'Skatepark'),
    _SituationItem(title: 'Voetbalveld'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kOverviewNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 250,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const _LogoFallback();
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kies de situatie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kies één situatie die het beste bij jullie past',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _situations.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _SituationCard(
                  title: _situations[i].title,
                  placeholderIcon: _situations[i].placeholderIcon,
                  onTap: () => _showStoryOptions(context, _situations[i].title),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStoryOptions(BuildContext context, String storyTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              storyTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E7E),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.games, color: Colors.white),
              ),
              title: const Text(
                'Spel hosten',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Start een nieuw spel als host'),
              onTap: () {
                Navigator.pop(modalContext);
                _createGame(context, storyTitle);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E7E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.login, color: Colors.white),
              ),
              title: const Text(
                'Deelnemen aan spel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Voer een PIN in om deel te nemen'),
              onTap: () {
                Navigator.pop(modalContext);
                Navigator.pushNamed(context, '/join-pin');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createGame(BuildContext context, String storyTitle) {
    Navigator.pushNamed(
      context,
      '/host-name-entry',
      arguments: {
        'storyTitle': storyTitle,
      },
    );
  }
}

class _SituationItem {
  const _SituationItem({required this.title});

  final String title;
}

extension _SituationItemIcons on _SituationItem {
  IconData get placeholderIcon => switch (title) {
        'Speeltuin' => Icons.park_outlined,
        'Skatepark' => Icons.skateboarding,
        'Voetbalveld' => Icons.sports_soccer_outlined,
        _ => Icons.image_outlined,
      };
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          size: 100,
          color: _kSituationPink,
        ),
        const SizedBox(height: 4),
        Text(
          'SOCIALITY',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kSituationPink,
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

class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.title,
    required this.placeholderIcon,
    required this.onTap,
  });

  final String title;
  final IconData placeholderIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: _kSituationPink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.2),
                      child: Center(
                        child: Icon(
                          placeholderIcon,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
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
