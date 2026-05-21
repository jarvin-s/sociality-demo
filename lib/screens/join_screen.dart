import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/guest_lobby_screen.dart';
import 'package:sociality/services/player_identity.dart';

class JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = normalizeJoinCodeTyping(newValue.text);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, this.initialJoinCode});

  /// Deep link `?code=` from web or route arguments.
  final String? initialJoinCode;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool isScanning = false;
  bool _hasScanned = false;
  bool _qrScanned = false;
  bool _joinBusy = false;
  bool _isPressed = false;
  bool _scanPressed = false;
  bool _cancelPressed = false;

  // When true, everything animates into its final position
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.initialJoinCode;
    if (prefill != null && prefill.trim().isNotEmpty) {
      _codeController.text = normalizeJoinCodeTyping(prefill);
    }

    // Wait one frame, then trigger all animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _attemptJoin({String? scannedPayload}) async {
    final raw = scannedPayload ?? _codeController.text;
    final code = parseJoinCodeFromQrOrText(raw);
    if (code == null || !isValidJoinCodeFormat(code)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voer een geldige spelcode in (6 tekens: A-Z zonder I/L/O, en 1-9).',
            ),
          ),
        );
      }
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vul je naam in.')),
        );
      }
      return;
    }

    setState(() => _joinBusy = true);
    try {
      await clearPlayerIdentity();
      final result = await joinGameSession(joinCode: code, playerName: name);
      final self = result.selfPlayer;
      if (self != null) {
        await savePlayerIdentity(self);
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => GuestLobbyScreen(
            joinCode: code,
            initialSnapshot: result.snapshot,
            selfPlayerId: result.selfPlayerId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _joinBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF273583),
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
                  tooltip:
                      MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 184,
                  height: 184,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),

                // Title + subtitle
                AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: const Column(
                    children: [
                      Text(
                        'Hoe wil je deelnemen?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Voer je naam en de 6-teken spelcode in, of scan de QR-code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Name + code box
                AnimatedSlide(
                  offset: _visible ? Offset.zero : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _visible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: isScanning
                          ? const SizedBox.shrink()
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 18),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Jouw naam',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      hintText: 'bijvoorbeeld: Sam',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 18,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFE6E1E1),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(4),
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Spelcode (6 tekens)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _codeController,
                                    keyboardType: TextInputType.text,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    inputFormatters: <TextInputFormatter>[
                                      JoinCodeFormatter(),
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    textAlign: TextAlign.left,
                                    decoration: const InputDecoration(
                                      hintText: 'bijvoorbeeld: 3WJ5EP',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 18,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFE6E1E1),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(4),
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),

                if (!_qrScanned) ...[
                  const SizedBox(height: 16),

                  // QR box
                  AnimatedSlide(
                    offset: _visible ? Offset.zero : const Offset(0, 0.3),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        height: isScanning ? 420 : 155,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Scan QR-code',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (isScanning)
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        width: 247,
                                        height: 300,
                                        child: MobileScanner(
                                          onDetect: (capture) {
                                            if (_hasScanned || _joinBusy) {
                                              return;
                                            }
                                            final String? raw = capture
                                                .barcodes.first.rawValue;
                                            if (raw == null) return;
                                            final parsed =
                                                parseJoinCodeFromQrOrText(raw);
                                            if (parsed == null) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Geen geldige spelcode in deze QR-code.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _hasScanned = true;
                                              _qrScanned = true;
                                              isScanning = false;
                                              _codeController.text = parsed;
                                            });
                                            _attemptJoin(scannedPayload: raw);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          isScanning = false;
                                          _hasScanned = false;
                                        }),
                                        onTapDown: (_) => setState(
                                          () => _cancelPressed = true,
                                        ),
                                        onTapUp: (_) => setState(
                                          () => _cancelPressed = false,
                                        ),
                                        onTapCancel: () => setState(
                                          () => _cancelPressed = false,
                                        ),
                                        child: AnimatedScale(
                                          scale: _cancelPressed ? 0.98 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          child: SizedBox(
                                            width: 189,
                                            height: 42,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Positioned(
                                                  bottom: 0,
                                                  left: 3,
                                                  right: 0,
                                                  child: Container(
                                                    height: 38,
                                                    decoration:
                                                        BoxDecoration(
                                                      color: const Color
                                                          .fromARGB(
                                                        255,
                                                        182,
                                                        6,
                                                        100,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(50),
                                                    ),
                                                  ),
                                                ),
                                                AnimatedPositioned(
                                                  duration: const Duration(
                                                    milliseconds: 100,
                                                  ),
                                                  top: _cancelPressed ? 4 : 0,
                                                  left: 0,
                                                  right:
                                                      _cancelPressed ? 0 : 3,
                                                  child: Container(
                                                    height: 38,
                                                    decoration:
                                                        BoxDecoration(
                                                      color: const Color(
                                                        0xFFE82A91,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(50),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      'Annuleren',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                    ),
                                  ],
                                )
                              else
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 20),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => isScanning = true),
                                    onTapDown: (_) =>
                                        setState(() => _scanPressed = true),
                                    onTapUp: (_) =>
                                        setState(() => _scanPressed = false),
                                    onTapCancel: () =>
                                        setState(() => _scanPressed = false),
                                    child: AnimatedScale(
                                      scale: _scanPressed ? 0.98 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 100),
                                      child: SizedBox(
                                        width: 189,
                                        height: 42,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Positioned(
                                              bottom: 0,
                                              left: 3,
                                              right: 0,
                                              child: Container(
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    182,
                                                    6,
                                                    100,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    50,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            AnimatedPositioned(
                                              duration: const Duration(
                                                milliseconds: 100,
                                              ),
                                              top: _scanPressed ? 4 : 0,
                                              left: 0,
                                              right: _scanPressed ? 0 : 3,
                                              child: Container(
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE82A91),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    50,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .qr_code_scanner_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Tik om te scannen',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
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
                  ),
                ],

                const SizedBox(height: 40),

                // Meedoen button
                AnimatedSlide(
                  offset: _visible ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _visible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: Opacity(
                      opacity: _joinBusy ? 0.55 : 1,
                      child: GestureDetector(
                        onTap: _joinBusy ? null : () => _attemptJoin(),
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) => setState(() => _isPressed = false),
                        onTapCancel: () =>
                            setState(() => _isPressed = false),
                        child: AnimatedScale(
                          scale: _isPressed ? 0.98 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: SizedBox(
                            width: 189,
                            height: 42,
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  left: 3,
                                  right: 0,
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 182, 6, 100),
                                      borderRadius:
                                          BorderRadius.circular(50),
                                    ),
                                  ),
                                ),
                                AnimatedPositioned(
                                  duration:
                                      const Duration(milliseconds: 100),
                                  top: _isPressed ? 4 : 0,
                                  left: 0,
                                  right: _isPressed ? 0 : 3,
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE82A91),
                                      borderRadius:
                                          BorderRadius.circular(50),
                                    ),
                                    alignment: Alignment.center,
                                    child: _joinBusy
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Meedoen',
                                            style: TextStyle(
                                              fontSize: 16,
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
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
        ),
      ),
    );
  }
}
