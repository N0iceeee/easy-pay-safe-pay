import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class UPICheckerScreen extends StatefulWidget {
  final String languageCode;

  const UPICheckerScreen({super.key, this.languageCode = 'en'});

  @override
  State<UPICheckerScreen> createState() => _UPICheckerScreenState();
}

class _UPICheckerScreenState extends State<UPICheckerScreen> {
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _payee;
  String? _qrUpiUri;
  String _result = '';
  bool _scanning = false;

  String t(String en, String kn, String hi) {
    switch (widget.languageCode) {
      case 'kn':
        return kn;
      case 'hi':
        return hi;
      default:
        return en;
    }
  }

  Future<void> _openOfficialSite(String url) async {
  final uri = Uri.parse(url);

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the website. Please try again.'),
      ),
    );
  }
}

  @override
  void dispose() {
    _upiController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _validFormat {
    final id = _upiController.text.trim();
    return RegExp(r'^[A-Za-z0-9._-]{2,256}@[A-Za-z0-9.-]{2,64}$').hasMatch(id);
  }

  void _checkUpi() {
    FocusScope.of(context).unfocus();

    final id = _upiController.text.trim();

    if (id.isEmpty) {
      setState(() {
        _result = t(
          'Enter a UPI ID first.',
          'ಮೊದಲು UPI ID ನಮೂದಿಸಿ.',
          'पहले UPI ID दर्ज करें।',
        );
      });
      return;
    }

    final valid = _validFormat;

    setState(() {
      _result = valid
          ? t(
              'Format looks plausible. This does NOT verify the owner or prove the ID is safe. Check the recipient name in your payment app before paying.',
              'UPI ID ಸ್ವರೂಪ ಸರಿಯಿರುವಂತೆ ಕಾಣುತ್ತದೆ. ಇದರಿಂದ ಮಾಲೀಕರ ಗುರುತು ಅಥವಾ ಸುರಕ್ಷತೆ ದೃಢವಾಗುವುದಿಲ್ಲ. ಪಾವತಿಸುವ ಮೊದಲು ಪಾವತಿ ಆ್ಯಪ್‌ನಲ್ಲಿ ಸ್ವೀಕರಿಸುವವರ ಹೆಸರನ್ನು ಪರಿಶೀಲಿಸಿ.',
              'UPI ID का प्रारूप सही लग रहा है। इससे मालिक की पहचान या सुरक्षा सत्यापित नहीं होती। भुगतान से पहले अपने पेमेंट ऐप में प्राप्तकर्ता का नाम जाँचें।',
            )
          : t(
              'The ID format looks unusual. Recheck it with the recipient before proceeding.',
              'UPI ID ಸ್ವರೂಪ ಸರಿಯಿಲ್ಲದಂತೆ ಕಾಣುತ್ತದೆ. ಮುಂದುವರಿಯುವ ಮೊದಲು ಸ್ವೀಕರಿಸುವವರೊಂದಿಗೆ ಪರಿಶೀಲಿಸಿ.',
              'ID का प्रारूप असामान्य है। आगे बढ़ने से पहले प्राप्तकर्ता से जाँचें।',
            );
    });
  }

  void _readQr(String raw) {
    final uri = Uri.tryParse(raw);

    if (uri == null ||
        uri.scheme.toLowerCase() != 'upi' ||
        uri.host.toLowerCase() != 'pay') {
      setState(() {
        _result = t(
          'This does not look like a standard UPI payment QR. Do not pay based on this scan.',
          'ಇದು ಸಾಮಾನ್ಯ UPI ಪಾವತಿ QR ಆಗಿ ಕಾಣುತ್ತಿಲ್ಲ. ಇದನ್ನು ಆಧರಿಸಿ ಪಾವತಿಸಬೇಡಿ.',
          'यह सामान्य UPI भुगतान QR नहीं लगता। इसे देखकर भुगतान न करें।',
        );
      });
      return;
    }

    final id = uri.queryParameters['pa'] ?? '';
    final name = uri.queryParameters['pn'] ?? '';
    final amount = uri.queryParameters['am'] ?? '';

    setState(() {
      _upiController.text = id;
      _payee = name.isEmpty ? null : name;
      _qrUpiUri = raw;

      if (amount.isNotEmpty) {
        _amountController.text = amount;
      }

      _scanning = false;
      _result = t(
        'QR read successfully. Review the recipient and amount carefully. The QR content has not been independently verified.',
        'QR ಓದಲಾಗಿದೆ. ಸ್ವೀಕರಿಸುವವರು ಮತ್ತು ಮೊತ್ತವನ್ನು ಎಚ್ಚರಿಕೆಯಿಂದ ಪರಿಶೀಲಿಸಿ. QR ಮಾಹಿತಿಯನ್ನು ಸ್ವತಂತ್ರವಾಗಿ ದೃಢಪಡಿಸಲಾಗಿಲ್ಲ.',
        'QR पढ़ लिया गया। प्राप्तकर्ता और राशि ध्यान से जाँचें। QR की जानकारी स्वतंत्र रूप से सत्यापित नहीं हुई है।',
      );
    });
  }

  Future<void> _openScanner() async {
    setState(() {
      _scanning = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QRScannerPage(
          onScan: (value) {
            Navigator.of(context).pop();
            _readQr(value);
          },
          languageCode: widget.languageCode,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('UPI Safety Checker', 'UPI ಸುರಕ್ಷತಾ ಪರಿಶೀಲನೆ', 'UPI सुरक्षा जाँच'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified_user, size: 64),
          const SizedBox(height: 12),
          Text(
            t(
              'Check before you pay',
              'ಪಾವತಿಸುವ ಮೊದಲು ಪರಿಶೀಲಿಸಿ',
              'भुगतान से पहले जाँचें',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _upiController,
            decoration: InputDecoration(
              labelText: t('UPI ID', 'UPI ID', 'UPI ID'),
              hintText: 'example@bank',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: t(
                'Amount (optional)',
                'ಮೊತ್ತ (ಐಚ್ಛಿಕ)',
                'राशि (वैकल्पिक)',
              ),
              prefixText: '₹ ',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _checkUpi,
            icon: const Icon(Icons.shield_outlined),
            label: Text(t('Check UPI ID', 'UPI ID ಪರಿಶೀಲಿಸಿ', 'UPI ID जाँचें')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(
              t(
                'Scan payment QR',
                'ಪಾವತಿ QR ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
                'भुगतान QR स्कैन करें',
              ),
            ),
          ),
          if (_payee != null) ...[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  t(
                    'Name embedded in QR',
                    'QR‌ನಲ್ಲಿರುವ ಹೆಸರು',
                    'QR में दिया गया नाम',
                  ),
                ),
                subtitle: Text(_payee!),
              ),
            ),
          ],
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_result),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            t(
              'Safety reminder: Never share your UPI PIN or OTP. Receiving money does not require entering your UPI PIN.',
              'ಸುರಕ್ಷತಾ ಸೂಚನೆ: ನಿಮ್ಮ UPI PIN ಅಥವಾ OTP ಹಂಚಿಕೊಳ್ಳಬೇಡಿ. ಹಣ ಸ್ವೀಕರಿಸಲು UPI PIN ನಮೂದಿಸುವ ಅಗತ್ಯವಿಲ್ಲ.',
              'सुरक्षा सुझाव: अपना UPI PIN या OTP साझा न करें। पैसे प्राप्त करने के लिए UPI PIN डालने की जरूरत नहीं होती।',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),


Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.languageCode == 'kn'
            ? 'ಅಧಿಕೃತ ಪರಿಶೀಲನಾ ವೆಬ್‌ಸೈಟ್‌ಗಳು'
            : widget.languageCode == 'hi'
                ? 'आधिकारिक जाँच वेबसाइटें'
                : 'Official Credibility Checks',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        widget.languageCode == 'kn'
            ? 'ವರದಿಯಾದ ಅನುಮಾನಾಸ್ಪದ ವಿವರಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.'
            : widget.languageCode == 'hi'
                ? 'रिपोर्ट किए गए संदिग्ध विवरणों की जाँच करें।'
                : 'Check whether details have been reported as suspicious.',
      ),
      const SizedBox(height: 12),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openOfficialSite(
            'https://cybercrime.gov.in/suspect-search',
          ),
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(
            widget.languageCode == 'kn'
                ? 'NCRP ನಲ್ಲಿ ಪರಿಶೀಲಿಸಿ'
                : widget.languageCode == 'hi'
                    ? 'NCRP पर जाँचें'
                    : 'Check on NCRP',
          ),
        ),
      ),

      const SizedBox(height: 8),

      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openOfficialSite(
            'https://www.sebi.gov.in/sebiweb/other/OtherAction.do?doRecognised=yes',
          ),
          icon: const Icon(Icons.account_balance_outlined),
          label: Text(
            widget.languageCode == 'kn'
                ? 'SEBI ನಲ್ಲಿ ನೋಂದಾಯಿತ ಸಂಸ್ಥೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ'
                : widget.languageCode == 'hi'
                    ? 'SEBI में पंजीकृत संस्थाएँ जाँचें'
                    : 'Check registered entities on SEBI',
          ),
        ),
      ),

      const SizedBox(height: 8),

      Text(
        widget.languageCode == 'kn'
            ? 'ಗಮನಿಸಿ: ವರದಿಗಳಲ್ಲಿ ವಿವರ ಕಾಣಿಸದಿರುವುದು ಸುರಕ್ಷಿತ ಎಂಬುದಕ್ಕೆ ಸಾಕ್ಷಿಯಲ್ಲ. SEBI ಷೇರು ಮಾರುಕಟ್ಟೆ ಸಂಬಂಧಿತ ಸಂಸ್ಥೆಗಳಿಗೆ ಮಾತ್ರ.'
            : widget.languageCode == 'hi'
                ? 'ध्यान दें: सूची में विवरण न मिलना सुरक्षा का प्रमाण नहीं है। SEBI केवल प्रतिभूति-बाज़ार से जुड़ी संस्थाओं के लिए है।'
                : 'Note: Not finding an ID in the repository does not prove it is safe. SEBI is for securities-market entities, not ordinary UPI IDs.',
        style: const TextStyle(fontSize: 12),
      ),
    ],
  ),
),


          if (_qrUpiUri != null)
            Text(
              t(
                'A QR payment link was read, but this demo does not initiate payments.',
                'QR ಪಾವತಿ ಲಿಂಕ್ ಓದಲಾಗಿದೆ; ಈ ಡೆಮೊ ಪಾವತಿಯನ್ನು ಪ್ರಾರಂಭಿಸುವುದಿಲ್ಲ.',
                'QR भुगतान लिंक पढ़ा गया है, लेकिन यह डेमो भुगतान शुरू नहीं करता।',
              ),
            ),
        ],
      ),
    );
  }
}

class _QRScannerPage extends StatefulWidget {
  final ValueChanged<String> onScan;
  final String languageCode;

  const _QRScannerPage({required this.onScan, required this.languageCode});

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  bool _handled = false;

  String t(String en, String kn, String hi) {
    switch (widget.languageCode) {
      case 'kn':
        return kn;
      case 'hi':
        return hi;
      default:
        return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('Scan UPI QR', 'UPI QR ಸ್ಕ್ಯಾನ್ ಮಾಡಿ', 'UPI QR स्कैन करें'),
        ),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;

          for (final barcode in capture.barcodes) {
            final value = barcode.rawValue;
            if (value != null && value.isNotEmpty) {
              _handled = true;
              widget.onScan(value);
              break;
            }
          }
        },
      ),
    );
  }
}
