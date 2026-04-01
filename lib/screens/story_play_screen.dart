import 'package:flutter/material.dart';

const Color _kStoryNavy = Color(0xFF29367C);
const Color _kStoryPanelGray = Color(0xFF333333);
const Color _kStoryPink = Color(0xFFE4318C);
const Color _kStoryCardBeige = Color(0xFFF5E9DF);

class StoryPlayScreen extends StatelessWidget {
  const StoryPlayScreen({super.key});

  static const String _title = 'HET SKATEPARK: DE START';
  static const String _body =
      'Jongeren in een middelgroot drop willen hun skatebaan uitbreiden met een overkapping en bankjes. De baan aan velden. Het is een populaire hangplek. Dat zorgt soms voor overlast door brommers, harde muziek en af en toe signalen van drugsgebruik of -dealen';

  static const String _choicePrompt = 'Wat doe je?';
  static const String _choiceA =
      'Je richt je eerst op gesprekken met de jongeren. Speel kaart 1A.';
  static const String _choiceB =
      'Je gaat voor draagvlak en richt je op het verzet in de buurt. Speel kaart 1B.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kStoryNavy,
      body: SafeArea(
        bottom: false,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                decoration: BoxDecoration(
                  color: _kStoryPanelGray,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      _title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _kStoryPink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _body,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.98),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kStoryCardBeige,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                22 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    _choicePrompt,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StoryChoiceButton(
                    label: _choiceA,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  _StoryChoiceButton(
                    label: _choiceB,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryChoiceButton extends StatelessWidget {
  const _StoryChoiceButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: _kStoryPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
