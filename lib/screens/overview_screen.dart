import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sociality/api/api_config.dart';
import 'package:sociality/screens/host_name_screen.dart';

const Color _kOverviewNavy = Color(0xFF233580);

const Color _kSituationPink = Color(0xFFE93D81);

Uri _storiesListUri() {
  return storiesApiBaseUri().replace(path: '/api/stories', query: null);
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late final Future<List<_SituationItem>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = _fetchStoryTitles();
  }

  static int? _storyIdFromJson(Map<String, dynamic> raw) {
    for (final key in <String>['id', 'storyId', 'story_id']) {
      final v = raw[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v.trim());
        if (n != null) return n;
      }
    }
    return null;
  }

  static String? _titleFromStoryJson(Map<String, dynamic> raw) {
    final starting = raw['startingCard'];
    if (starting is Map) {
      final m = Map<String, dynamic>.from(starting);
      final t = m['title'];
      if (t is String && t.trim().isNotEmpty) return t.trim();
    }
    final name = raw['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return null;
  }

  static Future<List<_SituationItem>> _fetchStoryTitles() async {
    final response = await http.get(_storiesListUri());
    if (response.statusCode != 200) {
      throw Exception('Kon verhalen niet laden (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      return const [];
    }
    final items = <_SituationItem>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final storyId = _storyIdFromJson(map);
      if (storyId == null) continue;
      final title = _titleFromStoryJson(map);
      if (title == null) continue;
      items.add(_SituationItem(storyId: storyId, title: title));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kOverviewNavy,
      body: SafeArea(
        child: FutureBuilder<List<_SituationItem>>(
          future: _storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            }
            final situations = snapshot.data ?? const <_SituationItem>[];
            return SingleChildScrollView(
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
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
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
                  if (situations.isEmpty)
                    Text(
                      'Geen situaties beschikbaar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                  else
                    for (var i = 0; i < situations.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _SituationCard(
                        title: situations[i].title,
                        placeholderIcon: situations[i].placeholderIcon,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => HostNameScreen(
                                situationTitle: situations[i].title,
                                currentStory: situations[i].storyId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SituationItem {
  const _SituationItem({required this.storyId, required this.title});

  /// [story_entity.id] — sent as `currentStory` when creating a game session.
  final int storyId;
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
