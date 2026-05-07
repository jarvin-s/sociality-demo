import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/guest_lobby_screen.dart';

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
  bool _joinBusy = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.initialJoinCode;
    if (prefill != null && prefill.trim().isNotEmpty) {
      _codeController.text = normalizeJoinCodeTyping(prefill);
    }
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
      final snapshot = await joinGameSession(joinCode: code, playerName: name);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => GuestLobbyScreen(
            joinCode: code,
            initialSnapshot: snapshot,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/images/logo.png', width: 184, height: 184),
                const SizedBox(height: 10),
                const Text(
                  'Hoe wil je deelnemen?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Voer je naam en de 6-teken spelcode in, of scan de QR-code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 25),
                AnimatedSize(
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'bijvoorbeeld: Sam',
                                  filled: true,
                                  fillColor: Color(0xFFE6E1E1),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
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
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: <TextInputFormatter>[
                                  JoinCodeFormatter(),
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: 'bijv. 3WJ5EP',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 18,
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFE6E1E1),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
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
                const SizedBox(height: 16),
                AnimatedContainer(
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
                                      if (_hasScanned || _joinBusy) return;
                                      final String? raw =
                                          capture.barcodes.first.rawValue;
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
                                        _codeController.text = parsed;
                                      });
                                      _attemptJoin(scannedPayload: raw);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => setState(() {
                                  isScanning = false;
                                  _hasScanned = false;
                                }),
                                child: const Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    'Annuleren',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: () => setState(() => isScanning = true),
                            child: Container(
                              width: 180,
                              height: 54,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Tik om te scannen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: _joinBusy ? 0.55 : 1,
                  child: GestureDetector(
                    onTap: _joinBusy ? null : () => _attemptJoin(),
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
                                color: const Color.fromARGB(255, 182, 6, 100),
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 3,
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE82A91),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              alignment: Alignment.center,
                              child: _joinBusy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
