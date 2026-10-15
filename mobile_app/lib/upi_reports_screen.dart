
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UPIReportsScreen extends StatefulWidget {
  const UPIReportsScreen({
    super.key,
    this.languageCode = 'en',
  });

  final String languageCode;

  @override
  State<UPIReportsScreen> createState() => _UPIReportsScreenState();
}

class _UPIReportsScreenState extends State<UPIReportsScreen> {
  // For Flutter Web running on your Mac.
  // Change this later if you deploy the backend.
  static const String _baseUrl = 'http://127.0.0.1:5001';

  final _upiController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _filterController = TextEditingController();

  String _reason = 'Suspicious payment request';
  bool _submitting = false;
  bool _loading = false;
  String _message = '';
  List<Map<String, dynamic>> _reports = [];

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

  final Map<String, List<String>> _reasons = {
    'Asked for UPI PIN or OTP': [
      'Asked for UPI PIN or OTP',
      'UPI PIN ಅಥವಾ OTP ಕೇಳಿದರು',
      'UPI PIN या OTP माँगा',
    ],
    'Suspicious payment request': [
      'Suspicious payment request',
      'ಅನುಮಾನಾಸ್ಪದ ಪಾವತಿ ವಿನಂತಿ',
      'संदिग्ध भुगतान अनुरोध',
    ],
    'Possible impersonation': [
      'Possible impersonation',
      'ಬೇರೆಯವರಂತೆ ನಟಿಸುವ ಸಾಧ್ಯತೆ',
      'किसी और की पहचान अपनाने का संदेह',
    ],
    'Money deducted unexpectedly': [
      'Money deducted unexpectedly',
      'ಅನಿರೀಕ್ಷಿತವಾಗಿ ಹಣ ಕಡಿತವಾಗಿದೆ',
      'अचानक पैसे कट गए',
    ],
    'Other': [
      'Other',
      'ಇತರೆ',
      'अन्य',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _descriptionController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final filter = _filterController.text.trim();
      final uri = Uri.parse('$_baseUrl/api/upi/reports').replace(
        queryParameters: filter.isEmpty ? null : {'upi_id': filter},
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Could not load reports');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['reports'] as List? ?? []);

      if (!mounted) return;
      setState(() {
        _reports = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = t(
          'Could not load reports. Check that the backend is running.',
          'ವರದಿಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಬ್ಯಾಕೆಂಡ್ ಚಾಲನೆಯಲ್ಲಿದೆಯೇ ಪರಿಶೀಲಿಸಿ.',
          'रिपोर्ट लोड नहीं हो सकीं। जाँचें कि बैकएंड चल रहा है।',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitReport() async {
    final upiId = _upiController.text.trim();
    final description = _descriptionController.text.trim();

    if (upiId.isEmpty) {
      setState(() {
        _message = t(
          'Please enter a UPI ID.',
          'ದಯವಿಟ್ಟು UPI ID ನಮೂದಿಸಿ.',
          'कृपया UPI ID दर्ज करें।',
        );
      });
      return;
    }

    if (description.length > 500) {
      setState(() {
        _message = t(
          'Description must be 500 characters or less.',
          'ವಿವರಣೆ 500 ಅಕ್ಷರಗಳಿಗಿಂತ ಹೆಚ್ಚು ಇರಬಾರದು.',
          'विवरण 500 अक्षरों से अधिक नहीं होना चाहिए।',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/upi/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'upi_id': upiId,
          'reason': _reason,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        _upiController.clear();
        _descriptionController.clear();
        _filterController.clear();

        if (!mounted) return;
        setState(() {
          _message = t(
            'Report submitted. It is unverified and does not prove fraud.',
            'ವರದಿ ಸಲ್ಲಿಸಲಾಗಿದೆ. ಇದು ಪರಿಶೀಲಿಸದ ವರದಿ; ವಂಚನೆಯನ್ನು ಸಾಬೀತುಪಡಿಸುವುದಿಲ್ಲ.',
            'रिपोर्ट जमा हुई। यह अप्रमाणित है और धोखाधड़ी का प्रमाण नहीं है।',
          );
        });

        await _loadReports();
      } else {
        if (!mounted) return;
        setState(() {
          _message = data['error']?.toString() ??
              t(
                'Could not submit report.',
                'ವರದಿ ಸಲ್ಲಿಸಲಾಗಲಿಲ್ಲ.',
                'रिपोर्ट जमा नहीं हो सकी।',
              );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = t(
          'Could not connect to the backend.',
          'ಬ್ಯಾಕೆಂಡ್‌ಗೆ ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
          'बैकएंड से कनेक्ट नहीं हो सका।',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _reasonLabel(String value) {
    final values = _reasons[value];
    if (values == null) return value;

    switch (widget.languageCode) {
      case 'kn':
        return values[1];
      case 'hi':
        return values[2];
      default:
        return values[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t(
            'Suspicious UPI Reports',
            'ಅನುಮಾನಾಸ್ಪದ UPI ವರದಿಗಳು',
            'संदिग्ध UPI रिपोर्ट',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.report_gmailerrorred_outlined,
            size: 56,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Report a suspicious UPI ID',
              'ಅನುಮಾನಾಸ್ಪದ UPI ID ವರದಿ ಮಾಡಿ',
              'संदिग्ध UPI ID की रिपोर्ट करें',
            ),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _upiController,
            decoration: InputDecoration(
              labelText: t('UPI ID', 'UPI ID', 'UPI ID'),
              hintText: 'example@bank',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t(
                'Reason for reporting',
                'ವರದಿ ಮಾಡುವ ಕಾರಣ',
                'रिपोर्ट करने का कारण',
              ),
              border: const OutlineInputBorder(),
            ),
            items: _reasons.keys.map((reason) {
              return DropdownMenuItem<String>(
                value: reason,
                child: Text(
                  _reasonLabel(reason),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _reason = value);
              }
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: t(
                'What happened? (optional)',
                'ಏನಾಯಿತು? (ಐಚ್ಛಿಕ)',
                'क्या हुआ? (वैकल्पिक)',
              ),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed: _submitting ? null : _submitReport,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(
              _submitting
                  ? t('Submitting...', 'ಸಲ್ಲಿಸಲಾಗುತ್ತಿದೆ...', 'जमा हो रहा है...')
                  : t('Submit report', 'ವರದಿ ಸಲ್ಲಿಸಿ', 'रिपोर्ट जमा करें'),
            ),
          ),

          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),

          Text(
            t(
              'Community reports',
              'ಸಮುದಾಯದ ವರದಿಗಳು',
              'समुदाय की रिपोर्ट',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'These are user-submitted reports, not verified findings.',
              'ಇವು ಬಳಕೆದಾರರು ಸಲ್ಲಿಸಿದ ವರದಿಗಳು; ಪರಿಶೀಲಿತ ನಿರ್ಧಾರಗಳಲ್ಲ.',
              'ये उपयोगकर्ताओं की रिपोर्ट हैं, सत्यापित निष्कर्ष नहीं।',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _filterController,
            decoration: InputDecoration(
              labelText: t(
                'Filter by UPI ID (optional)',
                'UPI ID ಮೂಲಕ ಹುಡುಕಿ (ಐಚ್ಛಿಕ)',
                'UPI ID से खोजें (वैकल्पिक)',
              ),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (_) => _loadReports(),
          ),
          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _loading ? null : _loadReports,
            icon: const Icon(Icons.refresh),
            label: Text(
              t('Refresh reports', 'ವರದಿಗಳನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಿ', 'रिपोर्ट रीफ़्रेश करें'),
            ),
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                t(
                  'No reports found.',
                  'ಯಾವುದೇ ವರದಿಗಳು ಕಂಡುಬಂದಿಲ್ಲ.',
                  'कोई रिपोर्ट नहीं मिली।',
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._reports.map((report) {
              final upiId = report['upi_id']?.toString() ?? '';
              final reason = report['reason']?.toString() ?? '';
              final description =
                  report['description']?.toString() ?? '';
              final createdAt =
                  report['created_at']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              upiId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_reasonLabel(reason)),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(description),
                      ],
                      if (createdAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.info_outline, size: 18),
                        label: Text(
                          t(
                            'Unverified report',
                            'ಪರಿಶೀಲಿಸದ ವರದಿ',
                            'अप्रमाणित रिपोर्ट',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          Text(
            t(
              'Never share your UPI PIN or OTP. If you experience financial cyber fraud in India, contact 1930 promptly.',
              'ನಿಮ್ಮ UPI PIN ಅಥವಾ OTP ಹಂಚಿಕೊಳ್ಳಬೇಡಿ. ಭಾರತದಲ್ಲಿ ಹಣಕಾಸಿನ ಸೈಬರ್ ವಂಚನೆ ಸಂಭವಿಸಿದರೆ ತಕ್ಷಣ 1930 ಸಂಪರ್ಕಿಸಿ.',
              'अपना UPI PIN या OTP साझा न करें। भारत में वित्तीय साइबर धोखाधड़ी होने पर तुरंत 1930 पर संपर्क करें।',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
