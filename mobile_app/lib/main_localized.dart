import 'package:upi_intent/upi_intent.dart';
import 'upi_reports_screen.dart';
import 'upi_checker_screen.dart';
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
    return ValueListenableBuilder<String>(
      valueListenable: appLanguageNotifier,
      builder: (context, language, child) {
        return MaterialApp(
          key: ValueKey(language),
          title: 'Easy Pay - Safe Pay',
          navigatorObservers: [VoiceGuideRouteObserver()],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: pale,
            colorScheme: ColorScheme.fromSeed(seedColor: teal),
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
          home: const HomeScreen(),
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
      },
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFFB9F3E4),
                        size: 42,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppLanguage.text(
                          'Your money.\nYour choice. Your safety.',
                          'ನಿಮ್ಮ ಹಣ.\nನಿಮ್ಮ ಆಯ್ಕೆ. ನಿಮ್ಮ ಸುರಕ್ಷತೆ.',
                          'आपका पैसा।\nआपकी पसंद। आपकी सुरक्षा।',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLanguage.text(
                          'Simple guidance to help you spot scams '
                          'and make more informed digital payments.',
                          'ವಂಚನೆಗಳನ್ನು ಗುರುತಿಸಲು ಮತ್ತು ಹೆಚ್ಚು ಸುರಕ್ಷಿತ '
                          'ಡಿಜಿಟಲ್ ಪಾವತಿಗಳನ್ನು ಮಾಡಲು ಸರಳ ಮಾರ್ಗದರ್ಶನ.',
                          'घोटालों को पहचानने और सुरक्षित '
                          'डिजिटल भुगतान करने में मदद के लिए सरल मार्गदर्शन।',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  AppLanguage.text(
                    'How can we help you?',
                    'ನಾವು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಬಹುದು?',
                    'हम आपकी कैसे मदद कर सकते हैं?',
                  ),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 14),
                FeatureCard(
                  icon: Icons.message_rounded,
                  color: const Color(0xFFE5F5F2),
                  iconColor: teal,
                  title: AppLanguage.text(
                    'Check a suspicious message',
                    'ಅನುಮಾನಾಸ್ಪದ ಸಂದೇಶವನ್ನು ಪರಿಶೀಲಿಸಿ',
                    'संदिग्ध संदेश की जाँच करें',
                  ),
                  description: AppLanguage.text(
                    'Check messages for common scam warning signs.',
                    'ಸಾಮಾನ್ಯ ವಂಚನೆ ಎಚ್ಚರಿಕೆ ಲಕ್ಷಣಗಳಿಗಾಗಿ ಸಂದೇಶಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
                    'सामान्य घोटाले की चेतावनी संकेतों के लिए संदेशों की जाँच करें।',
                  ),
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
                  title: AppLanguage.text(
                    'Check before paying',
                    'ಪಾವತಿಸುವ ಮೊದಲು ಪರಿಶೀಲಿಸಿ',
                    'भुगतान करने से पहले जाँचें',
                  ),
                  description: AppLanguage.text(
                    'Review important precautions before sending money.',
                    'ಹಣ ಕಳುಹಿಸುವ ಮೊದಲು ಪ್ರಮುಖ ಮುನ್ನೆಚ್ಚರಿಕೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
                    'पैसे भेजने से पहले महत्वपूर्ण सावधानियों की समीक्षा करें।',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentSafetyScreen(),
                      settings: const RouteSettings(name: '/payment-safety'),
                    ),
                  ),
                ),
                FeatureCard(
                  icon: Icons.qr_code_scanner_rounded,
                  color: const Color(0xFFDDF5E8),
                  iconColor: const Color(0xFF18794E),
                  title: AppLanguage.text(
                    'UPI Safety Checker',
                    'UPI ಸುರಕ್ಷತಾ ಪರಿಶೀಲನೆ',
                    'UPI सुरक्षा जाँच',
                  ),
                  description: AppLanguage.text(
                    'Check a UPI ID or scan a payment QR.',
                    'UPI ID ಪರಿಶೀಲಿಸಿ ಅಥವಾ ಪಾವತಿ QR ಸ್ಕ್ಯಾನ್ ಮಾಡಿ.',
                    'UPI ID जाँचें या भुगतान QR स्कैन करें।',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UPICheckerScreen(languageCode: AppLanguage.code),
                      settings: const RouteSettings(name: '/upi-checker'),
                    ),
                  ),
                ),
                FeatureCard(
                  icon: Icons.report_gmailerrorred_rounded,
                  color: const Color(0xFFFFE7E5),
                  iconColor: const Color(0xFFB42318),
                  title: AppLanguage.text(
                    'Suspicious UPI Reports',
                    'ಅನುಮಾನಾಸ್ಪದ UPI ವರದಿಗಳು',
                    'संदिग्ध UPI रिपोर्ट',
                  ),
                  description: AppLanguage.text(
                    'Report suspicious UPI IDs and view community reports.',
                    'ಅನುಮಾನಾಸ್ಪದ UPI ID ವರದಿ ಮಾಡಿ ಮತ್ತು ಇತರ ವರದಿಗಳನ್ನು ನೋಡಿ.',
                    'संदिग्ध UPI ID की रिपोर्ट करें और अन्य रिपोर्ट देखें।',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UPIReportsScreen(
                        languageCode: AppLanguage.code,
                      ),
                      settings: const RouteSettings(
                        name: '/upi-reports',
                      ),
                    ),
                  ),
                ),
                FeatureCard(
                  icon: Icons.school_rounded,
                  color: const Color(0xFFEAE8FF),
                  iconColor: const Color(0xFF6357B8),
                  title: AppLanguage.text(
                    'Learn to stay safe',
                    'ಸುರಕ್ಷಿತವಾಗಿರಲು ಕಲಿಯಿರಿ',
                    'सुरक्षित रहना सीखें',
                  ),
                  description: AppLanguage.text(
                    'Learn simple habits to protect yourself from fraud.',
                    'ವಂಚನೆಯಿಂದ ನಿಮ್ಮನ್ನು ರಕ್ಷಿಸಿಕೊಳ್ಳಲು ಸರಳ ಅಭ್ಯಾಸಗಳನ್ನು ಕಲಿಯಿರಿ.',
                    'धोखाधड़ी से खुद को बचाने के लिए सरल आदतें सीखें।',
                  ),
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
                  title: AppLanguage.text(
                    'Voice Guidance',
                    'ಧ್ವನಿ ಮಾರ್ಗದರ್ಶನ',
                    'आवाज़ मार्गदर्शन',
                  ),
                  description: AppLanguage.text(
                    'Voice guidance is available throughout the app. Use the speaker button anytime.',
                    'ಆ್ಯಪ್‌ನಾದ್ಯಂತ ಧ್ವನಿ ಮಾರ್ಗದರ್ಶನ ಲಭ್ಯವಿದೆ. ಯಾವುದೇ ಸಮಯದಲ್ಲಿ ಸ್ಪೀಕರ್ ಬಟನ್ ಬಳಸಿ.',
                    'ऐप भर में आवाज़ मार्गदर्शन उपलब्ध है। किसी भी समय स्पीकर बटन का उपयोग करें।',
                  ),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.favorite_rounded, color: teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLanguage.text(
                            'Remember: Never share your UPI PIN, password or OTP with anyone.',
                            'ನೆನಪಿರಲಿ: ನಿಮ್ಮ UPI PIN, ಪಾಸ್‌ವರ್ಡ್ ಅಥವಾ OTP ಅನ್ನು ಎಂದಿಗೂ ಯಾರೊಂದಿಗೂ ಹಂಚಿಕೊಳ್ಳಬೇಡಿ.',
                            'याद रखें: अपना UPI PIN, पासवर्ड या OTP कभी किसी के साथ साझा न करें।',
                          ),
                          style: const TextStyle(
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
                Center(
                  child: Text(
                    AppLanguage.text(
                      'Stay aware. Pause before you pay.',
                      'ಎಚ್ಚರದಿಂದಿರಿ. ಪಾವತಿಸುವ ಮುನ್ನ ತಡೆದು ಯೋಚಿಸಿ.',
                      'जागरूक रहें। भुगतान करने से पहले रुकें।',
                    ),
                    style: const TextStyle(color: Colors.blueGrey),
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

  static const String apiUrl = 'http://10.72.11.95:5001/api/analyze';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyzeMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      setState(() {
        _error = AppLanguage.text(
          'Please paste or type a message first.',
          'ದಯವಿಟ್ಟು ಮೊದಲು ಸಂದೇಶವನ್ನು ಅಂಟಿಸಿ ಅಥವಾ ಟೈಪ್ ಮಾಡಿ.',
          'कृपया पहले कोई संदेश पेस्ट करें या टाइप करें।',
        );
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
        _error = AppLanguage.text(
          'We could not connect to the safety checker. Please make sure the Flask backend is running on port 5001 and try again.',
          'ಸುರಕ್ಷತಾ ಪರಿಶೀಲಕವನ್ನು ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. Flask backend ಪೋರ್ಟ್ 5001 ನಲ್ಲಿ ಚಾಲನೆಯಲ್ಲಿದೆಯೇ ಎಂದು ಪರಿಶೀಲಿಸಿ, ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
          'हम सुरक्षा जाँच सेवा से कनेक्ट नहीं कर सके। कृपया सुनिश्चित करें कि Flask backend पोर्ट 5001 पर चल रहा है और फिर कोशिश करें।',
        );
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
              Text(
                AppLanguage.text(
                  'Think before you click.',
                  'ಕ್ಲಿಕ್ ಮಾಡುವ ಮೊದಲು ಯೋಚಿಸಿ.',
                  'क्लिक करने से पहले सोचें।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLanguage.text(
                  'Paste a suspicious SMS or message below. We will check it for selected warning signs.',
                  'ಅನುಮಾನಾಸ್ಪದ SMS ಅಥವಾ ಸಂದೇಶವನ್ನು ಕೆಳಗೆ ಅಂಟಿಸಿ. ನಾವು ಅದರಲ್ಲಿ ಎಚ್ಚರಿಕೆಯ ಲಕ್ಷಣಗಳನ್ನು ಪರಿಶೀಲಿಸುತ್ತೇವೆ.',
                  'नीचे संदिग्ध SMS या संदेश पेस्ट करें। हम उसमें चेतावनी के संकेत जाँचेंगे।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5, color: Colors.blueGrey),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLanguage.text(
                          'Your message',
                          'ನಿಮ್ಮ ಸಂದೇಶ',
                          'आपका संदेश',
                        ),
                        style: const TextStyle(
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
                          hintText: AppLanguage.text(
                            'Paste the message you want to check...',
                            'ಪರಿಶೀಲಿಸಬೇಕಾದ ಸಂದೇಶವನ್ನು ಇಲ್ಲಿ ಅಂಟಿಸಿ...',
                            'जिस संदेश की जाँच करनी है, उसे यहाँ पेस्ट करें...',
                          ),
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
                            _loading
                                ? AppLanguage.text(
                                    'Checking message...',
                                    'ಸಂದೇಶವನ್ನು ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
                                    'संदेश की जाँच हो रही है...',
                                  )
                                : AppLanguage.text(
                                    'Check message',
                                    'ಸಂದೇಶವನ್ನು ಪರಿಶೀಲಿಸಿ',
                                    'संदेश की जाँच करें',
                                  ),
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
                              ? AppLanguage.text(
                                  'This message contains serious warning signs.',
                                  'ಈ ಸಂದೇಶವು ಗುರುತಿಸಿದ ಹೆಚ್ಚಿನ ಅಪಾಯ ಸೂಚನೆಗಳನ್ನು ಹೊಂದಿದೆ.',
                                  'यह संदेश गंभीर चेतावनी चिह्नों को शामिल करता है।',
                                )
                              : risk.toLowerCase() == 'medium'
                                  ? AppLanguage.text(
                                      'This message contains possible warning signs.',
                                      'ಈ ಸಂದೇಶವು ಸಾಮಾನ್ಯ ಅಪಾಯ ಸೂಚನೆಗಳನ್ನು ಹೊಂದಿದೆ.',
                                      'यह संदेश संभावित चेतावनी चिह्नों को शामिल करता है।',
                                    )
                                  : AppLanguage.text(
                                      'This result does not guarantee that the message is safe.',
                                      'ಈ ಪರಿಶೀಲನೆಯು ಸಂದೇಶವು ಸುರಕ್ಷಿತವಾಗಿರಲು ಖಚಿತವಲ್ಲ.',
                                      'यह परिणाम यह निश्चित नहीं करता कि संदेश सुरक्षित है।',
                                    ),
                          style: const TextStyle(height: 1.5, color: ink),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppLanguage.text(
                            'What we noticed',
                            'ನಾವು ಗಮನಿಸಿದ ಅಂಶಗಳು',
                            'हमने क्या पाया',
                          ),
                          style: const TextStyle(
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
                          Text(
                            AppLanguage.text(
                              'No selected warning phrases were detected. This does not mean the message is safe.',
                              'ಆಯ್ಕೆ ಮಾಡಿದ ಯಾವುದೇ ಎಚ್ಚರಿಕೆಯ ಪದಗುಚ್ಛಗಳು ಕಂಡುಬಂದಿಲ್ಲ. ಇದರಿಂದ ಸಂದೇಶ ಸುರಕ್ಷಿತವಾಗಿದೆ ಎಂದರ್ಥವಲ್ಲ.',
                              'चुने गए चेतावनी वाले वाक्यांश नहीं मिले। इसका मतलब यह नहीं है कि संदेश सुरक्षित है।',
                            ),
                            style: const TextStyle(height: 1.5),
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
                              Text(
                                AppLanguage.text(
                                  'What should you do?',
                                  'ನೀವು ಯಾವುದನ್ನು ಮಾಡಬೇಕು?',
                                  'आप क्या करें?',
                                ),
                                style: const TextStyle(
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
                        Text(
                          AppLanguage.text(
                            'This tool checks selected warning signs only. It cannot detect every scam or guarantee safety.',
                            'ಈ ಸಾಧನವು ಆಯ್ದ ಎಚ್ಚರಿಕೆಯ ಲಕ್ಷಣಗಳನ್ನು ಮಾತ್ರ ಪರಿಶೀಲಿಸುತ್ತದೆ. ಇದು ಪ್ರತಿಯೊಂದು ವಂಚನೆಯನ್ನು ಪತ್ತೆಹಚ್ಚಲು ಅಥವಾ ಸುರಕ್ಷತೆಯನ್ನು ಖಚಿತಪಡಿಸಲು ಸಾಧ್ಯವಿಲ್ಲ.',
                            'यह टूल केवल चुने गए चेतावनी संकेतों की जाँच करता है। यह हर घोटाले का पता लगाने या सुरक्षा की गारंटी देने में सक्षम नहीं है।',
                          ),
                          style: const TextStyle(
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
              Text(
                AppLanguage.text(
                  'Never share your OTP or UPI PIN, even with someone '
                  'claiming to be from your bank.',
                  'ನೀವು ನಿಮ್ಮ ಬ್ಯಾಂಕ್ ಇರಬಹುದು ಎಂದು ಹೇಳುವ ವ್ಯಕ್ತಿಯನ್ನು ನಿಮ್ಮ OTP ಅಥವಾ UPI PIN ಅನ್ನು ಹಂಚಿಕೊಳ್ಳರದು.',
                  'कभी अपना OTP या UPI PIN साझा न करें, भले ही कोई आपके बैंक से संबंधित हो।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
        AppLanguage.text(
          'Verify the recipient',
          'ಸ್ವೀಕರಿಸುವವರನ್ನು ಪರಿಶೀಲಿಸಿ',
          'प्राप्तकर्ता की जाँच करें',
        ),
        AppLanguage.text(
          'Check the recipient name and payment details carefully.',
          'ಸ್ವೀಕರಿಸುವವರ ಹೆಸರು ಮತ್ತು ಪಾವತಿ ವಿವರಗಳನ್ನು ಎಚ್ಚರಿಕೆಯಿಂದ ಪರಿಶೀಲಿಸಿ.',
          'प्राप्तकर्ता का नाम और भुगतान विवरण ध्यान से जाँचें।',
        ),
      ),
      (
        Icons.call_received_rounded,
        AppLanguage.text(
          'Receiving money?',
          'ಹಣ ಸ್ವೀಕರಿಸುತ್ತಿದ್ದೀರಾ?',
          'पैसे प्राप्त कर रहे हैं?',
        ),
        AppLanguage.text(
          'You do not need to enter your UPI PIN to receive money.',
          'ಹಣ ಸ್ವೀಕರಿಸಲು ನಿಮ್ಮ UPI PIN ನಮೂದಿಸುವ ಅಗತ್ಯವಿಲ್ಲ.',
          'पैसे प्राप्त करने के लिए आपको अपना UPI PIN दर्ज करने की आवश्यकता नहीं है।',
        ),
      ),
      (
        Icons.lock_rounded,
        AppLanguage.text(
          'Protect your PIN',
          'ನಿಮ್ಮ PIN ಅನ್ನು ಸುರಕ್ಷಿತವಾಗಿಡಿ',
          'अपना PIN सुरक्षित रखें',
        ),
        AppLanguage.text(
          'Never share your UPI PIN or OTP with another person.',
          'ನಿಮ್ಮ UPI PIN ಅಥವಾ OTP ಅನ್ನು ಯಾರೊಂದಿಗೂ ಹಂಚಿಕೊಳ್ಳಬೇಡಿ.',
          'अपना UPI PIN या OTP किसी के साथ साझा न करें।',
        ),
      ),
      (
        Icons.pause_circle_outline_rounded,
        AppLanguage.text(
          'Pause under pressure',
          'ಒತ್ತಡದಲ್ಲಿದ್ದಾಗ ತಡೆದು ಯೋಚಿಸಿ',
          'दबाव में रुककर सोचें',
        ),
        AppLanguage.text(
          'Urgency, threats and prize promises can be warning signs.',
          'ತುರ್ತು ಕ್ರಮಕ್ಕೆ ಒತ್ತಾಯಿಸುವುದು, ಬೆದರಿಕೆಗಳು ಮತ್ತು ಬಹುಮಾನದ ಭರವಸೆಗಳು ವಂಚನೆಯ ಎಚ್ಚರಿಕೆಯ ಲಕ್ಷಣಗಳಾಗಿರಬಹುದು.',
          'जल्दबाज़ी का दबाव, धमकियाँ और इनाम के वादे धोखाधड़ी के संकेत हो सकते हैं।',
        ),
      ),
      (
        Icons.link_off_rounded,
        AppLanguage.text(
          'Avoid unknown links',
          'ಅಪರಿಚಿತ ಲಿಂಕ್‌ಗಳನ್ನು ತೆರೆಯಬೇಡಿ',
          'अनजान लिंक से बचें',
        ),
        AppLanguage.text(
          'Open your bank or payment app directly instead.',
          'ಬದಲಿಗೆ ನಿಮ್ಮ ಬ್ಯಾಂಕ್ ಅಥವಾ ಪಾವತಿ ಆ್ಯಪ್ ಅನ್ನು ನೇರವಾಗಿ ತೆರೆಯಿರಿ.',
          'इसके बजाय अपना बैंक या भुगतान ऐप सीधे खोलें।',
        ),
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
          Text(
            AppLanguage.text(
              'Take a moment before every payment.',
              'ಪ್ರತಿ ಪಾವತಿಗೂ ಮೊದಲು ಸ್ವಲ್ಪ ಸಮಯ ತೆಗೆದುಕೊಂಡು ಪರಿಶೀಲಿಸಿ.',
              'हर भुगतान से पहले थोड़ा रुककर जाँचें।',
            ),
            style: const TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLanguage.text(
              'Use this checklist before sending money through a digital '
              'payment app.',
              'ಡಿಜಿಟಲ್ ಪಾವತಿ ಆ್ಯಪ್ ಮೂಲಕ ಹಣ ಕಳುಹಿಸುವ ಮೊದಲು ಈ ಪಟ್ಟಿಯನ್ನು ಬಳಸಿ.',
              'डिजिटल भुगतान ऐप के माध्यम से पैसे भेजने से पहले इस चेकलिस्ट का उपयोग करें।',
            ),
            style: const TextStyle(color: Colors.blueGrey, height: 1.5),
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
            child: Text(
              AppLanguage.text(
                'Please note: this checklist does not verify a UPI ID, recipient identity or live transaction. Always confirm details in your official payment app.',
                'ಗಮನಿಸಿ: ಈ ಪರಿಶೀಲನಾ ಪಟ್ಟಿಯು UPI ID, ಸ್ವೀಕರಿಸುವವರ ಗುರುತು ಅಥವಾ ನೈಜ ಸಮಯದ ವಹಿವಾಟನ್ನು ಪರಿಶೀಲಿಸುವುದಿಲ್ಲ. ವಿವರಗಳನ್ನು ಯಾವಾಗಲೂ ನಿಮ್ಮ ಅಧಿಕೃತ ಪಾವತಿ ಆ್ಯಪ್‌ನಲ್ಲಿ ದೃಢೀಕರಿಸಿ.',
                'ध्यान दें: यह सूची UPI ID, प्राप्तकर्ता की पहचान या वास्तविक समय के लेन-देन की पुष्टि नहीं करती। विवरणों की पुष्टि हमेशा अपने आधिकारिक भुगतान ऐप में करें।',
              ),
              style: const TextStyle(color: navy, height: 1.5),
            ),
          ),

          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DemoUpiPaymentScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: Text(
              AppLanguage.text(
                'Test UPI Intent',
                'UPI ಇಂಟೆಂಟ್ ಪರೀಕ್ಷಿಸಿ',
                'UPI इंटेंट टेस्ट करें',
              ),
            ),
          ),
          const SizedBox(height: 12),

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
      (
        '1',
        AppLanguage.text(
          'A real bank will not ask you to reveal your OTP or UPI PIN.',
          'ನಿಮ್ಮ OTP ಅಥವಾ UPI PIN ಅನ್ನು ತಿಳಿಸುವಂತೆ ನಿಜವಾದ ಬ್ಯಾಂಕ್ ಕೇಳುವುದಿಲ್ಲ.',
          'असली बैंक आपसे अपना OTP या UPI PIN बताने के लिए नहीं कहेगा।',
        ),
      ),
      (
        '2',
        AppLanguage.text(
          'Never enter your UPI PIN just to receive money.',
          'ಹಣ ಸ್ವೀಕರಿಸಲು ಮಾತ್ರ ನಿಮ್ಮ UPI PIN ಅನ್ನು ಎಂದಿಗೂ ನಮೂದಿಸಬೇಡಿ.',
          'सिर्फ पैसे प्राप्त करने के लिए कभी भी अपना UPI PIN दर्ज न करें।',
        ),
      ),
      (
        '3',
        AppLanguage.text(
          'Do not trust a message just because it uses a familiar logo.',
          'ಪರಿಚಿತ ಲೋಗೋ ಇದೆ ಎಂಬ ಕಾರಣಕ್ಕೆ ಮಾತ್ರ ಸಂದೇಶವನ್ನು ನಂಬಬೇಡಿ.',
          'सिर्फ परिचित लोगो देखकर किसी संदेश पर भरोसा न करें।',
        ),
      ),
      (
        '4',
        AppLanguage.text(
          'Verify urgent requests by contacting the person through a number you already trust.',
          'ತುರ್ತು ವಿನಂತಿಗಳನ್ನು ನೀವು ಈಗಾಗಲೇ ನಂಬುವ ಫೋನ್ ಸಂಖ್ಯೆಯ ಮೂಲಕ ಆ ವ್ಯಕ್ತಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ ಪರಿಶೀಲಿಸಿ.',
          'ज़रूरी अनुरोधों की पुष्टि उस व्यक्ति से पहले से भरोसेमंद नंबर पर संपर्क करके करें।',
        ),
      ),
      (
        '5',
        AppLanguage.text(
          'If a payment request feels suspicious, stop and ask someone you trust for help.',
          'ಪಾವತಿ ವಿನಂತಿ ಅನುಮಾನಾಸ್ಪದವೆನಿಸಿದರೆ, ನಿಲ್ಲಿಸಿ ಮತ್ತು ನೀವು ನಂಬುವವರ ಸಹಾಯ ಪಡೆಯಿರಿ.',
          'अगर भुगतान का अनुरोध संदिग्ध लगे, तो रुकें और किसी भरोसेमंद व्यक्ति से मदद लें।',
        ),
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
          Text(
            AppLanguage.text(
              'Small habits. Stronger protection.',
              'ಸಣ್ಣ ಅಭ್ಯಾಸಗಳು. ಹೆಚ್ಚಿನ ರಕ್ಷಣೆ.',
              'छोटी आदतें। बेहतर सुरक्षा।',
            ),
            style: const TextStyle(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFFB9F3E4),
                  size: 35,
                ),
                const SizedBox(height: 10),
                Text(
                  AppLanguage.text(
                    'Suspect financial cyber fraud in India?',
                    'ಭಾರತದಲ್ಲಿ ಹಣಕಾಸಿನ ಸೈಬರ್ ವಂಚನೆ ನಡೆದಿರುವ ಅನುಮಾನವಿದೆಯೇ?',
                    'क्या आपको भारत में वित्तीय साइबर धोखाधड़ी का संदेह है?',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLanguage.text(
                    'Contact the national cybercrime helpline at 1930 as soon as possible. Report the incident through the official cybercrime reporting portal.',
                    'ಸಾಧ್ಯವಾದಷ್ಟು ಬೇಗ ರಾಷ್ಟ್ರೀಯ ಸೈಬರ್ ಅಪರಾಧ ಸಹಾಯವಾಣಿ 1930 ಅನ್ನು ಸಂಪರ್ಕಿಸಿ. ಅಧಿಕೃತ ಸೈಬರ್ ಅಪರಾಧ ವರದಿ ಪೋರ್ಟಲ್ ಮೂಲಕ ಘಟನೆಯನ್ನು ವರದಿ ಮಾಡಿ.',
                    'जितनी जल्दी हो सके राष्ट्रीय साइबर अपराध हेल्पलाइन 1930 पर संपर्क करें। आधिकारिक साइबर अपराध रिपोर्टिंग पोर्टल पर घटना की शिकायत दर्ज करें।',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppLanguage.text(
              'Easy Pay – Safe Pay is an educational safety guide. It does not guarantee that a message or payment is safe.',
              'Easy Pay – Safe Pay ಒಂದು ಶೈಕ್ಷಣಿಕ ಸುರಕ್ಷತಾ ಮಾರ್ಗದರ್ಶಿಯಾಗಿದೆ. ಸಂದೇಶ ಅಥವಾ ಪಾವತಿ ಸುರಕ್ಷಿತವಾಗಿದೆ ಎಂದು ಇದು ಖಚಿತಪಡಿಸುವುದಿಲ್ಲ.',
              'Easy Pay – Safe Pay एक शैक्षिक सुरक्षा मार्गदर्शिका है। यह गारंटी नहीं देता कि कोई संदेश या भुगतान सुरक्षित है।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
              height: 1.5,
            ),
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

  late String _reply; // using late string because AppLanguage can change dynamically

  @override
  void initState() {
    super.initState();
    _reply = AppLanguage.text(
      'Hello! I am your Easy Pay safety assistant. Tap the microphone and ask me how to pay safely.',
      'ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ Easy Pay ಸುರಕ್ಷತಾ ಸಹಾಯಕ. ಮೈಕ್ರೊಫೋನ್ ಟ್ಯಾಪ್ ಮಾಡಿ ಮತ್ತು ಸುರಕ್ಷಿತವಾಗಿ ಪಾವತಿ ಮಾಡುವುದು ಹೇಗೆ ಎಂದು ಕೇಳಿ.',
      'नमस्ते! मैं आपका Easy Pay सुरक्षा सहायक हूँ। माइक्रोफ़ोन पर टैप करें और पूछें कि सुरक्षित रूप से भुगतान कैसे करें।',
    );
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
        SnackBar(
          content: Text(
            AppLanguage.text(
              'Speech is unavailable on this device.',
              'ಈ ಸಾಧನದಲ್ಲಿ ಧ್ವನಿ ಸೌಲಭ್ಯ ಲಭ್ಯವಿಲ್ಲ.',
              'इस डिवाइस पर आवाज़ की सुविधा उपलब्ध नहीं है।',
            ),
          ),
        ),
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
    await _speak(AppLanguage.assistantReply(text));
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
          SnackBar(
            content: Text(
              AppLanguage.text(
                'Speech recognition is unavailable. Please check microphone permissions.',
                'ಧ್ವನಿ ಗುರುತಿಸುವ ಸೌಲಭ್ಯ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ಮೈಕ್ರೊಫೋನ್ ಅನುಮತಿಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
                'आवाज़ पहचानने की सुविधा उपलब्ध नहीं है। कृपया माइक्रोफ़ोन की अनुमति जाँचें।',
              ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              'Voice input error: $e',
              'ಧ್ವನಿ ಇನ್‌ಪುಟ್ ದೋಷ: $e',
              'आवाज़ इनपुट त्रुटि: $e',
            ),
          ),
        ),
      );
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
              Text(
                AppLanguage.text(
                  'Talk to Easy Pay',
                  'Easy Pay ಜೊತೆ ಮಾತನಾಡಿ',
                  'Easy Pay से बात करें',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLanguage.text(
                  'Ask for help with digital payment safety. '
                  'I will listen and read the guidance aloud.',
                  'ಡಿಜಿಟಲ್ ಪೇಮೆಂಟ್ ಸುರಕ್ಷತೆಯ ಬಗ್ಗೆ ಸಹಾಯವನ್ನು ಕೇಳಿ. '
                  'ನಾನು ಕೇಳಲು ಮತ್ತು ಮಾರ್ಗದರ್ಶನವನ್ನು ಓದಲು ಹಾಗೆಯಲ್ಲದರಲ್ಲಿ.',
                  'डिजिटल भुगतान सुरक्षा के संबंध में मदद के लिए पूछें। '
                  'मैं सुनूंगा और मार्गदर्शन पढ़ूंगा।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey, height: 1.5),
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
                      _listening ? Icons.hearing_rounded : Icons.mic_none_rounded,
                      size: 48,
                      color: teal,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLanguage.text(
                        _listening
                            ? 'Listening...'
                            : _speaking
                                ? 'Speaking...'
                                : 'Tap to speak',
                        _listening
                            ? 'ಕೇಳಲಾಗುತ್ತಿದೆ...'
                            : _speaking
                                ? 'ಬರೆಯಲಾಗುತ್ತಿದೆ...'
                                : 'ತಪ್ ಮಾಡಿ ಮಾತನಾಡಿ',
                        _listening
                            ? 'सुन रहा है...'
                            : _speaking
                                ? 'बोल रहा है...'
                                : 'बात करने के लिए टैप करें',
                      ),
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
                          AppLanguage.text(
                            _listening ? 'Stop listening' : 'Speak to assistant',
                            _listening ? 'ಕೇಳುವುದು ಮುಂದುಗಿಸಲಾಗಿದೆ' : 'ಸಹಾಯಕನೊಂದಿಗೆ ಮಾತನಾಡಿ',
                            _listening ? 'सुनना बंद करें' : 'सहायता के लिए बोलें',
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLanguage.text(
                          'What I heard',
                          'ನಾನು ಕೇಳಿದ್ದು',
                          'मैंने क्या सुना',
                        ),
                        style: const TextStyle(
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
                            ? AppLanguage.text(
                                'Your spoken words will appear here.',
                                'ನೀವು ಮಾತನಾಡಿದ ಪದಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
                                'आपके बोले हुए शब्द यहाँ दिखाई देंगे।',
                              )
                            : _heardText,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLanguage.text(
                          'Your safety guidance',
                          'ನಿಮ್ಮ ಸುರಕ್ಷತಾ ಮಾರ್ಗದರ್ಶನ',
                          'आपके लिए सुरक्षा संबंधी सलाह',
                        ),
                        style: const TextStyle(
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
              Text(
                AppLanguage.text(
                  'Try saying:',
                  'ಹೀಗೆ ಹೇಳಿ:',
                  'ऐसा बोलकर देखें:',
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),
              _VoiceExample(
                text: AppLanguage.text(
                  'How do I pay safely?',
                  'ನಾನು ಸುರಕ್ಷಿತವಾಗಿ ಪಾವತಿಸುವುದು ಹೇಗೆ?',
                  'मैं सुरक्षित रूप से भुगतान कैसे करूँ?',
                ),
              ),
              _VoiceExample(
                text: AppLanguage.text(
                  'What if someone asks for my OTP?',
                  'ಯಾರಾದರೂ ನನ್ನ OTP ಕೇಳಿದರೆ ಏನು ಮಾಡಬೇಕು?',
                  'अगर कोई मेरा OTP माँगे तो क्या करूँ?',
                ),
              ),
              _VoiceExample(
                text: AppLanguage.text(
                  'How do I know if a message is a scam?',
                  'ಸಂದೇಶವು ವಂಚನೆಯೇ ಎಂದು ತಿಳಿಯುವುದು ಹೇಗೆ?',
                  'मुझे कैसे पता चलेगा कि कोई संदेश धोखाधड़ी है?',
                ),
              ),
              _VoiceExample(
                text: AppLanguage.text(
                  'What if I am receiving money?',
                  'ನಾನು ಹಣವನ್ನು ಸ್ವೀಕರಿಸುತ್ತಿದ್ದರೆ ಏನು ಮಾಡಬೇಕು?',
                  'अगर मुझे पैसे मिल रहे हों तो क्या करूँ?',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLanguage.text(
                  'This is a basic voice-guidance prototype. '
                  'It does not verify recipients or make payments.',
                  'ಇದು ಮೂಲಭೂತ ಧ್ವನಿ ಮಾರ್ಗದರ್ಶನದ ಮಾದರಿಯಾಗಿದೆ. '
                  'ಇದು ಹಣ ಸ್ವೀಕರಿಸುವವರನ್ನು ಪರಿಶೀಲಿಸುವುದಿಲ್ಲ ಅಥವಾ ಪಾವತಿಗಳನ್ನು ಮಾಡುವುದಿಲ್ಲ.',
                  'यह आवाज़ आधारित मार्गदर्शन का एक प्रारंभिक नमूना है। '
                  'यह प्राप्तकर्ता की पुष्टि नहीं करता और न ही भुगतान करता है।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
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


class DemoUpiPaymentScreen extends StatefulWidget {
  const DemoUpiPaymentScreen({super.key});

  @override
  State<DemoUpiPaymentScreen> createState() =>
      _DemoUpiPaymentScreenState();
}

class _DemoUpiPaymentScreenState
    extends State<DemoUpiPaymentScreen> {
  final _upiController = TextEditingController();
  bool _loading = false;
  String _message = '';

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _testUpiIntent() async {
    final upiId = _upiController.text.trim();

    if (upiId.isEmpty) {
      setState(() => _message = 'Enter your own UPI ID first.');
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final response = await UpiIntent.pay(
        context: context,
        payment: UpiPayment(
          payeeVpa: upiId,
          payeeName: 'Easy Pay Demo',
          amount: 1.00,
          transactionNote: 'Easy Pay intent test',
          transactionRefId:
              'EASYPAY${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      if (!mounted) return;

      setState(() {
        if (response == null) {
          _message = 'Payment flow cancelled. No success was confirmed.';
        } else {
          switch (response.status) {
            case UpiTransactionStatus.success:
              _message =
                  'UPI app reported success. Verify the transaction in your UPI app or bank history.';
            case UpiTransactionStatus.failure:
              _message = 'UPI app reported a failed payment.';
            case UpiTransactionStatus.submitted:
              _message =
                  'Payment was submitted but is not yet confirmed.';
            case UpiTransactionStatus.unknown:
              _message =
                  'Payment status is unknown. Check your UPI app or bank history.';
          }
        }
      });
    } on UpiException catch (e) {
      if (mounted) {
        setState(() => _message = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Could not open UPI: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test UPI Intent')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'UPI Intent Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This test attempts to open an installed UPI app '
            'with a ₹1 payment request. It may result in a real '
            'payment if you authorize it. Cancel in the UPI app '
            'if you only want to test app opening.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _upiController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Your own UPI ID',
              hintText: 'Enter a UPI ID you control',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _testUpiIntent,
            icon: const Icon(Icons.open_in_new),
            label: Text(
              _loading ? 'Opening UPI…' : 'Open UPI App — ₹1',
            ),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(_message),
          ],
        ],
      ),
    );
  }
}
