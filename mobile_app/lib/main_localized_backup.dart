import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:flutter_tts/flutter_tts.dart';

/// Shared voice guidance used across every screen in Easy Pay.

class VoiceGuideService {
  VoiceGuideService._();

  static final VoiceGuideService instance = VoiceGuideService._();

  final FlutterTts _tts = FlutterTts();

  bool enabled = true;

  String latestText =
      'Welcome to Easy Pay Safe Pay. Choose an option to get help using digital payments safely.';

  Future<void> initialize() async {
    try {
      await _tts.setLanguage(AppLanguage.ttsLocale);

      await _tts.setSpeechRate(0.43);

      await _tts.setPitch(1.0);

      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Voice guidance may not be supported on every browser or device.
    }
  }

  Future<void> speak(String text, {bool force = false}) async {
    latestText = text;

    if (!enabled && !force) return;

    try {
      await _tts.stop();

      await _tts.setLanguage(AppLanguage.ttsLocale);

      await _tts.speak(text);
    } catch (_) {
      // Keep the app usable even if text-to-speech is unavailable.
    }
  }

  Future<void> setLanguage() async {
    try {
      await _tts.setLanguage(AppLanguage.ttsLocale);
    } catch (_) {
      // The selected voice may not be available on this device.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  String guidanceForRoute(String? name) {
    return AppLanguage.guidance(name);
  }
}

class VoiceGuideRouteObserver extends NavigatorObserver {
  void _announce(Route<dynamic>? route) {
    final name = route?.settings.name;

    final guidance = VoiceGuideService.instance.guidanceForRoute(name);

    VoiceGuideService.instance.speak(guidance);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    _announce(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute != null) _announce(previousRoute);
  }
}

class GlobalVoiceGuideButton extends StatefulWidget {
  const GlobalVoiceGuideButton({super.key});

  @override
  State<GlobalVoiceGuideButton> createState() => _GlobalVoiceGuideButtonState();
}

class _GlobalVoiceGuideButtonState extends State<GlobalVoiceGuideButton> {
  @override
  Widget build(BuildContext context) {
    final service = VoiceGuideService.instance;

    return GestureDetector(
      onLongPress: () async {
        setState(() {
          service.enabled = !service.enabled;
        });

        if (!service.enabled) {
          await service.stop();
        } else {
          await service.speak(service.latestText, force: true);
        }
      },

      child: FloatingActionButton.small(
        heroTag: 'global-voice-guide-button',

        backgroundColor: teal,

        foregroundColor: Colors.white,

        onPressed: () async {
          if (service.enabled) {
            await service.speak(service.latestText, force: true);
          } else {
            setState(() {
              service.enabled = true;
            });

            await service.speak(service.latestText, force: true);
          }
        },

        child: Icon(
          service.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await VoiceGuideService.instance.initialize();

  runApp(const EasyPayApp());
}

const Color navy = Color(0xFF153448);

const Color teal = Color(0xFF087E8B);

const Color pale = Color(0xFFF3F8FA);

const Color ink = Color(0xFF243746);

class AppLanguage {
  static String code = 'en';

  static String get ttsLocale {
    switch (code) {
      case 'kn':
        return 'kn-IN';

      case 'hi':
        return 'hi-IN';

      default:
        return 'en-IN';
    }
  }

  static String get speechLocale => ttsLocale;

  static String text(String en, String kn, String hi) {
    switch (code) {
      case 'kn':
        return kn;

      case 'hi':
        return hi;

      default:
        return en;
    }
  }

  static String guidance(String? route) {
    switch (route) {
      case '/scam-checker':
        return text(
          'You are in Scam Message Checker. Enter a suspicious message to check it. This tool cannot identify every scam.',

          'ನೀವು ವಂಚನೆ ಸಂದೇಶ ಪರಿಶೀಲಕದಲ್ಲಿದ್ದೀರಿ. ಅನುಮಾನಾಸ್ಪದ ಸಂದೇಶವನ್ನು ಪರಿಶೀಲಿಸಿ. ಈ ಸಾಧನವು ಎಲ್ಲಾ ವಂಚನೆಗಳನ್ನು ಗುರುತಿಸುವುದಿಲ್ಲ.',

          'आप स्कैम संदेश जाँच में हैं। संदिग्ध संदेश की जाँच करें। यह टूल हर धोखाधड़ी की पहचान नहीं कर सकता।',
        );

      case '/payment-safety':
        return text(
          'Before paying, verify the recipient and amount. Never share your UPI PIN or OTP.',

          'ಹಣ ಕಳುಹಿಸುವ ಮೊದಲು ಸ್ವೀಕರಿಸುವವರ ಹೆಸರು ಮತ್ತು ಮೊತ್ತವನ್ನು ಪರಿಶೀಲಿಸಿ. ನಿಮ್ಮ UPI PIN ಅಥವಾ OTP ಹಂಚಬೇಡಿ.',

          'भुगतान से पहले प्राप्तकर्ता और राशि जाँचें। अपना UPI PIN या OTP कभी साझा न करें।',
        );

      case '/learn':
        return text(
          'Learn how to stay safe while making digital payments. In India, call 1930 if you suspect cyber fraud.',

          'ಡಿಜಿಟಲ್ ಪಾವತಿಗಳಲ್ಲಿ ಸುರಕ್ಷಿತವಾಗಿರುವುದನ್ನು ಕಲಿಯಿರಿ. ಭಾರತದಲ್ಲಿ ಸೈಬರ್ ವಂಚನೆ ಅನುಮಾನವಿದ್ದರೆ 1930 ಗೆ ಕರೆ ಮಾಡಿ.',

          'डिजिटल भुगतान के दौरान सुरक्षित रहना सीखें। भारत में साइबर धोखाधड़ी का संदेह हो तो 1930 पर कॉल करें।',
        );

      case '/voice-assistant':
        return text(
          'You are talking to Easy Pay. Ask about payment safety or suspicious messages.',

          'ನೀವು Easy Pay ಜೊತೆ ಮಾತನಾಡುತ್ತಿದ್ದೀರಿ. ಪಾವತಿ ಸುರಕ್ಷತೆ ಅಥವಾ ಅನುಮಾನಾಸ್ಪದ ಸಂದೇಶಗಳ ಬಗ್ಗೆ ಕೇಳಿ.',

          'आप Easy Pay से बात कर रहे हैं। भुगतान सुरक्षा या संदिग्ध संदेशों के बारे में पूछें।',
        );

      default:
        return text(
          'Welcome to Easy Pay Safe Pay. Choose an option to learn about digital payment safety.',

          'Easy Pay Safe Pay ಗೆ ಸ್ವಾಗತ. ಡಿಜಿಟಲ್ ಪಾವತಿ ಸುರಕ್ಷತೆ ತಿಳಿಯಲು ಒಂದು ಆಯ್ಕೆಯನ್ನು ಆರಿಸಿ.',

          'Easy Pay Safe Pay में आपका स्वागत है। डिजिटल भुगतान सुरक्षा जानने के लिए विकल्प चुनें।',
        );
    }
  }

  static String assistantReply(String input) {
    final message = input.toLowerCase();

    if (message.contains('otp') ||
        message.contains('pin') ||
        message.contains('password') ||
        message.contains('ಒಟಿಪಿ') ||
        message.contains('ಪಿನ್') ||
        message.contains('ओटीपी') ||
        message.contains('पिन') ||
        message.contains('पासवर्ड')) {
      return text(
        'Never share your UPI PIN, OTP, or password. Enter your PIN only in your trusted payment app to authorize a payment.',

        'ನಿಮ್ಮ UPI PIN, OTP ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್ ಹಂಚಬೇಡಿ. ಪಾವತಿಯನ್ನು ಅನುಮೋದಿಸಲು ನಿಮ್ಮ ವಿಶ್ವಾಸಾರ್ಹ ಪಾವತಿ ಆ್ಯಪ್‌ನಲ್ಲೇ PIN ನಮೂದಿಸಿ.',

        'अपना UPI PIN, OTP या पासवर्ड कभी साझा न करें। भुगतान की अनुमति देने के लिए अपना PIN केवल विश्वसनीय भुगतान ऐप में दर्ज करें।',
      );
    }

    if (message.contains('receive') ||
        message.contains('receiving') ||
        message.contains('ಹಣ ಪಡೆಯ') ||
        message.contains('ಹಣ ಸ್ವೀಕರ') ||
        message.contains('पैसे मिल') ||
        message.contains('पैसे प्राप्त')) {
      return text(
        'You do not need a UPI PIN to receive money. Never approve an unexpected collect request.',

        'ಹಣ ಸ್ವೀಕರಿಸಲು UPI PIN ಅಗತ್ಯವಿಲ್ಲ. ಅನಿರೀಕ್ಷಿತ ಹಣದ ವಿನಂತಿಯನ್ನು ಅನುಮೋದಿಸಬೇಡಿ.',

        'पैसे प्राप्त करने के लिए UPI PIN की आवश्यकता नहीं है। अनजान कलेक्ट अनुरोध को मंज़ूर न करें।',
      );
    }

    return text(
      'If a message asks for an OTP, threatens to block your account, or pressures you to click a link, pause and verify it. Never share sensitive information.',

      'ಸಂದೇಶವು OTP ಕೇಳಿದರೆ, ಖಾತೆ ನಿರ್ಬಂಧಿಸುವುದಾಗಿ ಬೆದರಿಸಿದರೆ ಅಥವಾ ಲಿಂಕ್ ತೆರೆಯಲು ಒತ್ತಾಯಿಸಿದರೆ, ನಿಲ್ಲಿಸಿ ಪರಿಶೀಲಿಸಿ. ರಹಸ್ಯ ಮಾಹಿತಿಯನ್ನು ಹಂಚಬೇಡಿ.',

      'यदि कोई संदेश OTP माँगे, खाता बंद करने की धमकी दे या लिंक खोलने का दबाव डाले, तो रुकें और जाँचें। गोपनीय जानकारी साझा न करें।',
    );
  }
}

final ValueNotifier<String> appLanguageNotifier = ValueNotifier<String>(
  AppLanguage.code,
);

class EasyPayApp extends StatelessWidget {
  const EasyPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Pay - Safe Pay',

      navigatorObservers: [VoiceGuideRouteObserver()],

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: pale,

        colorScheme: ColorScheme.fromSeed(seedColor: teal),

        fontFamily: 'Arial',

        appBarTheme: const AppBarTheme(
          backgroundColor: pale,

          foregroundColor: navy,

          elevation: 0,

          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),

      home: ValueListenableBuilder<String>(
        valueListenable: appLanguageNotifier,
        builder: (context, language, child) => const HomeScreen(),
      ),

      builder: (context, child) => Stack(
        children: [
          if (child != null) child,

          const Positioned(
            right: 16,
            bottom: 16,
            child: GlobalVoiceGuideButton(),
          ),
        ],
      ),
    );
  }
}

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        child: Row(
          children: [
            const Icon(Icons.language, color: teal),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                AppLanguage.text(
                  'Choose language',

                  'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',

                  'भाषा चुनें',
                ),
              ),
            ),

            DropdownButton<String>(
              value: AppLanguage.code,

              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),

                DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),

                DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
              ],

              onChanged: (value) async {
                if (value == null) return;

                setState(() {
                  AppLanguage.code = value;
                  appLanguageNotifier.value = value;
                });

                final voice = VoiceGuideService.instance;

                await voice.setLanguage();

                await voice.speak(AppLanguage.guidance(null));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),

            child: ListView(
              padding: const EdgeInsets.all(24),

              children: [
                const LanguageSelector(),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: teal,

                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Icon(
                        Icons.shield_rounded,

                        color: Colors.white,

                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Easy Pay',

                            style: TextStyle(
                              fontSize: 25,

                              fontWeight: FontWeight.bold,

                              color: navy,
                            ),
                          ),

                          Text(
                            'SAFE PAY  •  DIGITAL SAFETY',

                            style: TextStyle(
                              fontSize: 11,

                              letterSpacing: 1.1,

                              color: teal,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.accessibility_new_rounded,

                      size: 29,

                      color: teal,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(26),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [navy, Color(0xFF176B78)],

                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,
                    ),

                    borderRadius: BorderRadius.circular(28),
                  ),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.verified_user_rounded,

                        color: Color(0xFFB9F3E4),

                        size: 42,
                      ),

                      SizedBox(height: 18),

                      Text(
                        'Your money.\nYour choice. Your safety.',

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 29,

                          height: 1.2,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Simple guidance to help you spot scams '
                        'and make more informed digital payments.',

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 15,

                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'How can we help you?',

                  style: TextStyle(
                    fontSize: 22,

                    fontWeight: FontWeight.bold,

                    color: navy,
                  ),
                ),

                const SizedBox(height: 14),

                FeatureCard(
                  icon: Icons.message_rounded,

                  color: const Color(0xFFE5F5F2),

                  iconColor: teal,

                  title: 'Check a suspicious message',

                  description: 'Check messages for common scam warning signs.',

                  onTap: () => Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => const ScamCheckerScreen(),

                      settings: const RouteSettings(name: '/scam-checker'),
                    ),
                  ),
                ),

                FeatureCard(
                  icon: Icons.account_balance_wallet_rounded,

                  color: const Color(0xFFFFF1D8),

                  iconColor: const Color(0xFF9B6900),

                  title: 'Check before paying',

                  description:
                      'Review important precautions before sending money.',

                  onTap: () => Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => const PaymentSafetyScreen(),

                      settings: const RouteSettings(name: '/payment-safety'),
                    ),
                  ),
                ),

                FeatureCard(
                  icon: Icons.school_rounded,

                  color: const Color(0xFFEAE8FF),

                  iconColor: const Color(0xFF6357B8),

                  title: 'Learn to stay safe',

                  description:
                      'Learn simple habits to protect yourself from fraud.',

                  onTap: () => Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => const LearnScreen(),

                      settings: const RouteSettings(name: '/learn'),
                    ),
                  ),
                ),

                FeatureCard(
                  icon: Icons.record_voice_over_rounded,

                  color: const Color(0xFFE0F0FF),

                  iconColor: const Color(0xFF2459A9),

                  title: 'Voice Guidance',

                  description: 'Voice guidance is available throughout the app. Use the speaker button anytime.',

                  onTap: () => Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => const VoiceAssistantScreen(),

                      settings: const RouteSettings(name: '/voice-assistant'),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(17),

                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4EC),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(Icons.favorite_rounded, color: teal),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Remember: Never share your UPI PIN, '
                          'password or OTP with anyone.',

                          style: TextStyle(
                            color: navy,

                            height: 1.5,

                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Stay aware. Pause before you pay.',

                    style: TextStyle(color: Colors.blueGrey),
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

class FeatureCard extends StatelessWidget {
  final IconData icon;

  final Color color;

  final Color iconColor;

  final String title;

  final String description;

  final VoidCallback onTap;

  const FeatureCard({
    super.key,

    required this.icon,

    required this.color,

    required this.iconColor,

    required this.title,

    required this.description,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Row(
            children: [
              Container(
                width: 56,

                height: 56,

                decoration: BoxDecoration(
                  color: color,

                  borderRadius: BorderRadius.circular(17),
                ),

                child: Icon(icon, color: iconColor, size: 29),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        color: navy,

                        fontSize: 16,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,

                      style: const TextStyle(
                        color: Colors.blueGrey,

                        fontSize: 13,

                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,

                color: teal,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScamCheckerScreen extends StatefulWidget {
  const ScamCheckerScreen({super.key});

  @override
  State<ScamCheckerScreen> createState() => _ScamCheckerScreenState();
}

class _ScamCheckerScreenState extends State<ScamCheckerScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;

  String? _error;

  Map<String, dynamic>? _result;

  // Chrome on your Mac can access the Flask server through localhost.

  // For a physical Android phone, this address must be changed.

  static const String apiUrl = 'http://127.0.0.1:5001/api/analyze';

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _analyzeMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      setState(() {
        _error = 'Please paste or type a message first.';

        _result = null;
      });

      return;
    }

    setState(() {
      _loading = true;

      _error = null;

      _result = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({
              'message': message,

              'language': AppLanguage.code,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('The server returned ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response from the server.');
      }

      if (!mounted) return;

      setState(() {
        _result = decoded;
      });

      final resultRisk = decoded['risk']?.toString() ?? 'unverified';

      final resultReasons = decoded['reasons'];

      final resultAction =
          decoded['action']?.toString() ??
          'Pause and verify the message independently.';

      final spokenReasons = resultReasons is List && resultReasons.isNotEmpty
          ? resultReasons.map((item) => item.toString()).join('. ')
          : 'No selected warning phrases were detected. This does not mean the message is safe.';

      await VoiceGuideService.instance.speak(
        'Scam checker result: $resultRisk risk. $spokenReasons. What you should do: $resultAction. This tool checks selected warning signs only and cannot guarantee safety.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'We could not connect to the safety checker. '
            'Please make sure the Flask backend is running on port 5001 '
            'and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _loadSample() {
    setState(() {
      _controller.text =
          'Your bank account will be blocked today. '
          'Share your OTP immediately.';

      _result = null;

      _error = null;
    });
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return const Color(0xFFB42318);

      case 'medium':
        return const Color(0xFF9A6700);

      case 'low':
        return const Color(0xFF087443);

      default:
        return const Color(0xFF46566A);
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Icons.warning_rounded;

      case 'medium':
        return Icons.error_outline_rounded;

      case 'low':
        return Icons.check_circle_outline_rounded;

      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final risk = _result?['risk']?.toString() ?? 'unverified';

    final reasons = _result?['reasons'];

    final action =
        _result?['action']?.toString() ??
        'Pause and verify the message independently.';

    final color = _riskColor(risk);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLanguage.text(
            'Scam Message Checker',
            'ವಂಚನೆ ಸಂದೇಶ ಪರಿಶೀಲಕ',
            'स्कैम संदेश जाँच',
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),

          child: ListView(
            padding: const EdgeInsets.all(22),

            children: [
              const Icon(
                Icons.mark_email_unread_rounded,

                color: teal,
                size: 52,
              ),

              const SizedBox(height: 12),

              const Text(
                'Think before you click.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 26,

                  fontWeight: FontWeight.bold,

                  color: navy,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Paste a suspicious SMS or message below. '
                'We will check it for selected warning signs.',

                textAlign: TextAlign.center,

                style: TextStyle(height: 1.5, color: Colors.blueGrey),
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Your message',

                        style: TextStyle(
                          color: navy,

                          fontSize: 17,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _controller,

                        minLines: 5,

                        maxLines: 8,

                        maxLength: 2000,

                        decoration: InputDecoration(
                          hintText: 'Paste the message you want to check...',

                          filled: true,

                          fillColor: pale,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,

                        child: TextButton.icon(
                          onPressed: _loadSample,

                          icon: const Icon(Icons.science_outlined),

                          label: Text(
                            AppLanguage.text(
                              'Try sample message',
                              'ಉದಾಹರಣೆ ಸಂದೇಶ ಪ್ರಯತ್ನಿಸಿ',
                              'नमूना संदेश आज़माएँ',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,

                        child: FilledButton.icon(
                          onPressed: _loading ? null : _analyzeMessage,

                          icon: _loading
                              ? const SizedBox(
                                  height: 19,

                                  width: 19,

                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,

                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search_rounded),

                          label: Text(
                            _loading ? 'Checking message...' : 'Check message',
                          ),

                          style: FilledButton.styleFrom(
                            backgroundColor: teal,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 17),

                            textStyle: const TextStyle(
                              fontSize: 16,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E5),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Text(
                    _error!,

                    style: const TextStyle(
                      color: Color(0xFF9D2017),

                      height: 1.5,
                    ),
                  ),
                ),
              ],

              if (_result != null) ...[
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Icon(_riskIcon(risk), color: color, size: 32),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                risk.toUpperCase() == 'UNVERIFIED'
                                    ? 'UNVERIFIED'
                                    : '${risk.toUpperCase()} RISK',

                                style: TextStyle(
                                  fontSize: 21,

                                  fontWeight: FontWeight.bold,

                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          risk.toLowerCase() == 'high'
                              ? 'This message contains serious warning signs.'
                              : risk.toLowerCase() == 'medium'
                              ? 'This message contains possible warning signs.'
                              : 'This result does not guarantee that the message is safe.',

                          style: const TextStyle(height: 1.5, color: ink),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'What we noticed',

                          style: TextStyle(
                            color: navy,

                            fontSize: 17,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (reasons is List && reasons.isNotEmpty)
                          ...reasons.map(
                            (reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Icon(Icons.circle, color: color, size: 9),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      reason.toString(),

                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Text(
                            'No selected warning phrases were detected. '
                            'This does not mean the message is safe.',

                            style: TextStyle(height: 1.5),
                          ),

                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(15),

                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F5F2),

                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'What should you do?',

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,

                                  color: navy,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Text(
                                action,

                                style: const TextStyle(
                                  height: 1.5,

                                  color: navy,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'This tool checks selected warning signs only. '
                          'It cannot detect every scam or guarantee safety.',

                          style: TextStyle(
                            color: Colors.blueGrey,

                            fontSize: 12,

                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              const Text(
                'Never share your OTP or UPI PIN, even with someone '
                'claiming to be from your bank.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: navy,

                  height: 1.5,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSafetyScreen extends StatelessWidget {
  const PaymentSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      (
        Icons.person_search_rounded,

        'Verify the recipient',

        'Check the recipient name and payment details carefully.',
      ),

      (
        Icons.call_received_rounded,

        'Receiving money?',

        'You do not need to enter your UPI PIN to receive money.',
      ),

      (
        Icons.lock_rounded,

        'Protect your PIN',

        'Never share your UPI PIN or OTP with another person.',
      ),

      (
        Icons.pause_circle_outline_rounded,

        'Pause under pressure',

        'Urgency, threats and prize promises can be warning signs.',
      ),

      (
        Icons.link_off_rounded,

        'Avoid unknown links',

        'Open your bank or payment app directly instead.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLanguage.text(
            'Check Before Paying',
            'ಪಾವತಿಸುವ ಮೊದಲು ಪರಿಶೀಲಿಸಿ',
            'भुगतान से पहले जाँचें',
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(22),

        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,

            size: 52,
            color: teal,
          ),

          const SizedBox(height: 14),

          const Text(
            'Take a moment before every payment.',

            style: TextStyle(
              color: navy,

              fontSize: 25,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Use this checklist before sending money through a digital '
            'payment app.',

            style: TextStyle(color: Colors.blueGrey, height: 1.5),
          ),

          const SizedBox(height: 22),

          ...tips.map(
            (tip) => Card(
              margin: const EdgeInsets.only(bottom: 12),

              child: Padding(
                padding: const EdgeInsets.all(17),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(tip.$1, size: 29, color: teal),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            tip.$2,

                            style: const TextStyle(
                              color: navy,

                              fontSize: 16,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            tip.$3,

                            style: const TextStyle(
                              height: 1.5,

                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D8),

              borderRadius: BorderRadius.circular(18),
            ),

            child: const Text(
              'Please note: this checklist does not verify a UPI ID, '
              'recipient identity or live transaction. Always confirm '
              'details in your official payment app.',

              style: TextStyle(color: navy, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = [
      ('1', 'A real bank will not ask you to reveal your OTP or UPI PIN.'),

      ('2', 'Never enter your UPI PIN just to receive money.'),

      ('3', 'Do not trust a message just because it uses a familiar logo.'),

      (
        '4',

        'Verify urgent requests by contacting the person through '
            'a number you already trust.',
      ),

      (
        '5',

        'If a payment request feels suspicious, stop and ask '
            'someone you trust for help.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLanguage.text(
            'Learn to Stay Safe',
            'ಸುರಕ್ಷಿತವಾಗಿರಲು ಕಲಿಯಿರಿ',
            'सुरक्षित रहना सीखें',
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(22),

        children: [
          const Icon(Icons.school_rounded, size: 52, color: teal),

          const SizedBox(height: 14),

          const Text(
            'Small habits. Stronger protection.',

            style: TextStyle(
              color: navy,

              fontSize: 25,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ...lessons.map(
            (lesson) => Card(
              margin: const EdgeInsets.only(bottom: 12),

              child: Padding(
                padding: const EdgeInsets.all(17),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      width: 35,

                      height: 35,

                      alignment: Alignment.center,

                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F5F2),

                        shape: BoxShape.circle,
                      ),

                      child: Text(
                        lesson.$1,

                        style: const TextStyle(
                          color: teal,

                          fontWeight: FontWeight.bold,

                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Text(
                        lesson.$2,

                        style: const TextStyle(
                          color: ink,

                          height: 1.5,

                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: navy,

              borderRadius: BorderRadius.circular(22),
            ),

            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.support_agent_rounded,

                  color: Color(0xFFB9F3E4),
                  size: 35,
                ),

                SizedBox(height: 10),

                Text(
                  'Suspect financial cyber fraud in India?',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Contact the national cybercrime helpline at 1930 '
                  'as soon as possible and report the incident through '
                  'the official cybercrime reporting portal.',

                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Easy Pay – Safe Pay is an educational safety guide. '
            'It does not guarantee that a message or payment is safe.',

            textAlign: TextAlign.center,

            style: TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  final FlutterTts _tts = FlutterTts();

  bool _available = false;

  bool _listening = false;

  bool _speaking = false;

  String _heardText = '';

  String _reply =
      'Hello! I am your Easy Pay safety assistant. '
      'Tap the microphone and ask me how to pay safely.';

  @override
  void initState() {
    super.initState();

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      await _tts.setLanguage(AppLanguage.ttsLocale);

      await _tts.setSpeechRate(0.45);

      await _tts.setPitch(1.0);

      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            _listening = status == 'listening';
          });
        },

        onError: (error) {
          if (!mounted) return;

          setState(() {
            _listening = false;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _available = available;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _available = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    setState(() {
      _reply = text;

      _speaking = true;
    });

    try {
      await _tts.stop();

      await _tts.speak(text);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech is unavailable on this device.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _speaking = false;
        });
      }
    }
  }


Future<void> _handleCommand(String text) async {
  if (!mounted) return;

  setState(() {
    _speaking = true;
    _reply = AppLanguage.text(
      'Thinking... Please wait.',
      'ಯೋಚಿಸಲಾಗುತ್ತಿದೆ... ದಯವಿಟ್ಟು ಕಾಯಿರಿ.',
      'सोच रहा हूँ... कृपया प्रतीक्षा करें।',
    );
  });

  try {
    final response = await http
        .post(
          Uri.parse('http://127.0.0.1:5001/api/ai-help'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'prompt': text,
            'language': AppLanguage.code,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('AI request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final answer = data['response'] as String?;

    if (answer == null || answer.trim().isEmpty) {
      throw Exception('Empty AI response');
    }

    if (!mounted) return;

    await _speak(answer);
  } catch (e) {
    if (!mounted) return;

    final errorMessage = AppLanguage.text(
      'Sorry, I could not connect to the AI assistant. Please check that the backend is running and try again.',
      'ಕ್ಷಮಿಸಿ, AI ಸಹಾಯಕನೊಂದಿಗೆ ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಬ್ಯಾಕೆಂಡ್ ಚಾಲನೆಯಲ್ಲಿದೆಯೇ ಎಂದು ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'क्षमा करें, AI सहायक से जुड़ नहीं पाया। कृपया बैकएंड चालू है या नहीं जाँचें और फिर कोशिश करें।',
    );

    setState(() {
      _reply = errorMessage;
      _speaking = false;
    });
  }
}


  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();

      return;
    }

    if (!_available) {
      await _initializeVoice();

      if (!_available) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is unavailable. '
              'Please check microphone permissions.',
            ),
          ),
        );

        return;
      }
    }

    await _tts.stop();

    setState(() {
      _heardText = '';
    });

    try {
      await _speech.listen(
        localeId: AppLanguage.speechLocale,

        listenFor: const Duration(seconds: 20),

        pauseFor: const Duration(seconds: 3),

        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _heardText = result.recognizedWords;
          });

          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _speech.stop();

            _handleCommand(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Voice input error: $e')));
    }
  }

  @override
  void dispose() {
    _speech.stop();

    _tts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLanguage.text('Voice Assistant', 'ಧ್ವನಿ ಸಹಾಯಕ', 'आवाज़ सहायक'),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),

          child: ListView(
            padding: const EdgeInsets.all(24),

            children: [
              const SizedBox(height: 12),

              const Icon(Icons.support_agent_rounded, size: 76, color: teal),

              const SizedBox(height: 16),

              const Text(
                'Talk to Easy Pay',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 28,

                  fontWeight: FontWeight.bold,

                  color: navy,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Ask for help with digital payment safety. '
                'I will listen and read the guidance aloud.',

                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.blueGrey, height: 1.5),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(24),
                ),

                child: Column(
                  children: [
                    Icon(
                      _listening
                          ? Icons.hearing_rounded
                          : Icons.mic_none_rounded,

                      size: 48,

                      color: teal,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _listening
                          ? 'Listening...'
                          : _speaking
                          ? 'Speaking...'
                          : 'Tap to speak',

                      style: const TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,

                      child: FilledButton.icon(
                        onPressed: _toggleListening,

                        icon: Icon(
                          _listening ? Icons.stop_rounded : Icons.mic_rounded,
                        ),

                        label: Text(
                          _listening ? 'Stop listening' : 'Speak to assistant',
                        ),

                        style: FilledButton.styleFrom(
                          backgroundColor: teal,

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'What I heard',

                        style: TextStyle(
                          color: navy,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: pale,

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Text(
                        _heardText.isEmpty
                            ? 'Your spoken words will appear here.'
                            : _heardText,

                        style: const TextStyle(height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'Your safety guidance',

                        style: TextStyle(
                          color: navy,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _reply,

                      style: const TextStyle(
                        color: ink,

                        height: 1.6,

                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 14),

                    OutlinedButton.icon(
                      onPressed: () => _speak(_reply),

                      icon: const Icon(Icons.volume_up_rounded),

                      label: Text(
                        AppLanguage.text(
                          'Read guidance aloud',
                          'ಮಾರ್ಗದರ್ಶನವನ್ನು ಕೇಳಿ',
                          'सलाह आवाज़ में सुनें',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Try saying:',

                style: TextStyle(
                  fontSize: 17,

                  fontWeight: FontWeight.bold,

                  color: navy,
                ),
              ),

              const SizedBox(height: 12),

              const _VoiceExample(text: 'How do I pay safely?'),

              const _VoiceExample(text: 'What if someone asks for my OTP?'),

              const _VoiceExample(
                text: 'How do I know if a message is a scam?',
              ),

              const _VoiceExample(text: 'What if I am receiving money?'),

              const SizedBox(height: 20),

              const Text(
                'This is a basic voice-guidance prototype. '
                'It does not verify recipients or make payments.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.blueGrey,

                  fontSize: 12,

                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceExample extends StatelessWidget {
  final String text;

  const _VoiceExample({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFE5F5F2),

        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: teal),

          const SizedBox(width: 10),

          Expanded(
            child: Text(text, style: const TextStyle(color: navy)),
          ),
        ],
      ),
    );
  }
}
