import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sociality/api/api_config.dart';
import 'package:sociality/screens/host_name_screen.dart';

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

Uri _storiesListUri() {
  return storiesApiBaseUri().replace(path: '/api/stories', query: null);
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  late final Future<List<_SituationItem>> _storiesFuture;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _storiesFuture = _fetchStoryTitles();
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
    if (decoded is! List<dynamic>) return const [];
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
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kNavyDeep,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              // Pink diagonal wedge (top 44%)
              Positioned(
                top: 0, left: 0, right: 0,
                height: h * 0.44,
                child: ClipPath(
                  clipper: const _WedgeClipper(0.84),
                  child: Container(color: _kPink),
                ),
              ),

              // Scrollable content
              Positioned.fill(
                child: FadeTransition(
                  opacity: _fade,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(28, topPad + 90, 28, 24 + bottomPad),
                    child: FutureBuilder<List<_SituationItem>>(
                      future: _storiesFuture,
                      builder: (context, snapshot) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              'Situaties',
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
                              'Kies één situatie die het beste bij jullie past.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),

                            SizedBox(height: h * 0.24),

                            // Cards in navy section
                            if (snapshot.connectionState == ConnectionState.waiting)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 32),
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              )
                            else if (snapshot.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Text(
                                  snapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  for (var i = 0; i < (snapshot.data ?? []).length; i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _SituationCard(
                                      item: snapshot.data![i],
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => HostNameScreen(
                                            situationTitle: snapshot.data![i].title,
                                            currentStory: snapshot.data![i].storyId,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: topPad + 12,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
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

class _SituationItem {
  const _SituationItem({required this.storyId, required this.title});
  final int storyId;
  final String title;
}

extension _SituationItemIcons on _SituationItem {
  IconData get icon => switch (title) {
        'Speeltuin' => Icons.park_outlined,
        'Skatepark' => Icons.skateboarding,
        'Skatebaan' => Icons.skateboarding,
        'Test' => Icons.text_snippet_outlined,
        'Voetbalveld' => Icons.sports_soccer_outlined,
        _ => Icons.image_outlined,
      };
}

class _SituationCard extends StatefulWidget {
  const _SituationCard({required this.item, required this.onTap});
  final _SituationItem item;
  final VoidCallback onTap;

  @override
  State<_SituationCard> createState() => _SituationCardState();
}

class _SituationCardState extends State<_SituationCard> {
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _kPink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(widget.item.icon,
                        color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.4), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
