import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_collection_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? appVersion;
  String? libraryVersion;
  int? bookCount;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Widget _buildContributor(String name, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _loadVersions() async {
    // Load app version
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    // Load library version from file
    await _loadLibraryVersion();

    setState(() {});
  }

  Future<void> _loadLibraryVersion() async {
    final dataService = DataCollectionService();
    libraryVersion = await dataService.readLibraryVersion();
    if (libraryVersion == 'unknown') {
      libraryVersion = 'לא ידוע';
    }

    // Load book count
    bookCount = await dataService.getTotalBookCount();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Upper part with icon and title
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon/icon.png',
                  width: 128,
                  height: 128,
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'אוצריא ',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'מאגר תורני חינמי',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'תוכנה זו נוצרה והוקדשה על ידי: ',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    _buildContributor('sivan22', 'https://github.com/Sivan22'),
                    const Text(', '),
                    _buildContributor('Y.PL.', 'https://github.com/Y-PLONI'),
                    const Text(', '),
                    _buildContributor('YOSEFTT', 'https://github.com/YOSEFTT'),
                    const Text(', '),
                    _buildContributor(
                        'zevisvei', 'https://github.com/zevisvei'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                Column(
                  children: [
                    // Title aligned to the right
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16.0),
                      child: const Text(
                        'סכום משמעותי לפיתוח התוכנה, נתרם לעילוי נשמת:',
                        style: TextStyle(fontSize: 16),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scrollable and Centered Name
                    SizedBox(
                      height: 100, // Max height for the scrollable area
                      child: SingleChildScrollView(
                        child: Center(
                          // Center the RichText
                          child: RichText(
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 24, // Default size
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: 'ר\' ',
                                  style: TextStyle(
                                    fontSize: 20, // Smaller
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                TextSpan(
                                  text: 'משה',
                                  style: TextStyle(
                                    fontSize: 32, // Clearly larger
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' בן ',
                                  style: TextStyle(
                                    fontSize: 20, // Smaller
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                TextSpan(
                                  text: 'יהודה ראה',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ז"ל',
                                  style: TextStyle(
                                    fontSize: 20, // Smaller
                                    fontWeight: FontWeight.normal,
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
              ],
            ),

            // Lower part with versions and donations
            Column(
              children: [
                InkWell(
                  onTap: () async {
                    const url = 'https://forms.gle/Dq8bn7mw7he4wtTC9';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: const Text(
                    'לתרומות והנצחות, ולסיוע למאגר הספרים של אוצריא [פשוט וקל, כל אחד יכול!]',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'גרסת תוכנה: ${appVersion ?? 'לא ידוע'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'גרסת ספריה: ${libraryVersion ?? 'לא ידוע'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'מספר הספרים שבמאגר כעת: ${bookCount ?? 'לא ידוע'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
