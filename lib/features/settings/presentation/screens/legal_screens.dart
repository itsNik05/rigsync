import 'package:flutter/material.dart';

// ── Privacy Policy Screen ─────────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(content: _privacyPolicyText),
      ),
    );
  }
}

// ── Terms of Service Screen ───────────────────────────────────────────────────

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(content: _termsOfServiceText),
      ),
    );
  }
}

// ── Shared content widget ─────────────────────────────────────────────────────

class _PolicyContent extends StatelessWidget {
  const _PolicyContent({required this.content});
  final List<_PolicySection> content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...content.map((section) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.isHeader) ...[
              const SizedBox(height: 8),
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
          ],
        )),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _PolicySection {
  const _PolicySection({
    required this.title,
    required this.body,
    this.isHeader = false,
  });
  final String title;
  final String body;
  final bool isHeader;
}

// ── Privacy Policy Content ────────────────────────────────────────────────────

const _privacyPolicyText = [
  _PolicySection(
    title: 'Privacy Policy — RigSync',
    body: 'Last updated: April 2026\n\n'
        'NuvioLabs ("we", "our", or "us") built RigSync as a paid application. '
        'This page informs you of our policies regarding the collection, use, and '
        'disclosure of personal information when you use our app.',
    isHeader: true,
  ),
  _PolicySection(
    title: '1. Information we collect',
    body: 'RigSync is designed to work primarily offline. The following data is '
        'stored locally on your device:\n\n'
        '• Worker names and job roles\n'
        '• Hitch schedule dates and patterns\n'
        '• Pay period amounts and daily rates\n'
        '• Rig location coordinates you manually enter\n'
        '• App settings and preferences\n\n'
        'If you choose to use Family Sharing (optional), the following data is '
        'stored on Firebase (Google\'s cloud platform):\n\n'
        '• Your Google account name and email (for authentication)\n'
        '• Hitch schedule data shared with your household\n'
        '• Family events you add (titles, dates)\n'
        '• Household invite codes',
  ),
  _PolicySection(
    title: '2. How we use your information',
    body: 'We use the information stored on your device solely to provide the '
        'app\'s features — displaying your hitch calendar, calculating pay, '
        'estimating travel times, and sending rotation reminders.\n\n'
        'We do not sell, trade, or transfer your personal information to third '
        'parties. We do not use your data for advertising purposes.',
  ),
  _PolicySection(
    title: '3. Third-party services',
    body: 'RigSync uses the following third-party services:\n\n'
        '• Firebase (Google) — for optional family sharing and authentication. '
        'Firebase\'s privacy policy applies: firebase.google.com/support/privacy\n\n'
        '• OpenWeatherMap — for weather data at rig locations. Only the '
        'coordinates you manually pin are sent. No personal data is shared. '
        'openweathermap.org/privacy-policy\n\n'
        '• OpenStreetMap — map tiles are loaded from public OSM servers. '
        'No personal data is sent. openstreetmap.org/privacy\n\n'
        '• Google Play Billing — for processing the Pro upgrade purchase. '
        'Google\'s privacy policy applies.',
  ),
  _PolicySection(
    title: '4. Location data',
    body: 'RigSync requests location permission only to show your current '
        'position on the map and calculate travel distance to rig sites. '
        'Your location is never uploaded to our servers or shared with anyone. '
        'Location access is optional — the app works without it.',
  ),
  _PolicySection(
    title: '5. Notifications',
    body: 'RigSync sends local notifications (processed entirely on your device) '
        'to remind you of upcoming rotation changes and pay periods. '
        'No notification data is sent to external servers.',
  ),
  _PolicySection(
    title: '6. Data retention and deletion',
    body: 'All local data can be deleted at any time through Settings → '
        'Clear all data. This permanently removes all schedules, workers, '
        'and pay periods from your device.\n\n'
        'If you used Family Sharing, your data in Firebase can be removed by '
        'leaving your household and contacting us at nuviolabs07@gmail.com.',
  ),
  _PolicySection(
    title: '7. Children\'s privacy',
    body: 'RigSync is not directed at children under 13 years of age. '
        'We do not knowingly collect personal information from children under 13.',
  ),
  _PolicySection(
    title: '8. Changes to this policy',
    body: 'We may update this Privacy Policy from time to time. Changes will be '
        'posted within the app and on our website. Continued use of the app '
        'after changes constitutes acceptance of the updated policy.',
  ),
  _PolicySection(
    title: '9. Contact us',
    body: 'If you have any questions about this Privacy Policy, contact us at:\n\n'
        'NuvioLabs\n'
        'Email: nuviolabs07@gmail.com',
  ),
];

// ── Terms of Service Content ──────────────────────────────────────────────────

const _termsOfServiceText = [
  _PolicySection(
    title: 'Terms of Service — RigSync',
    body: 'Last updated: April 2026\n\n'
        'Please read these Terms of Service carefully before using RigSync, '
        'operated by NuvioLabs. By downloading or using the app, you agree '
        'to be bound by these terms.',
    isHeader: true,
  ),
  _PolicySection(
    title: '1. Acceptance of terms',
    body: 'By accessing or using RigSync, you confirm that you are at least '
        '18 years old and agree to these Terms of Service. If you do not '
        'agree, do not use the app.',
  ),
  _PolicySection(
    title: '2. License',
    body: 'NuvioLabs grants you a limited, non-exclusive, non-transferable, '
        'revocable license to use RigSync for your personal, non-commercial '
        'purposes. You may not copy, modify, distribute, sell, or lease any '
        'part of the app.',
  ),
  _PolicySection(
    title: '3. Pro upgrade',
    body: 'RigSync offers a one-time Pro upgrade purchase that unlocks '
        'additional features including unlimited workers, finance tracking, '
        'family sharing, rig location, and notifications.\n\n'
        '• The Pro upgrade is a one-time payment — no subscription or '
        'recurring charges.\n'
        '• The purchase is processed by Google Play and subject to their '
        'refund policy.\n'
        '• The upgrade is tied to your Google Play account and can be '
        'restored on reinstallation using the Restore Purchase option.\n'
        '• We reserve the right to modify Pro features with reasonable notice.',
  ),
  _PolicySection(
    title: '4. Accuracy of information',
    body: 'RigSync is a scheduling and tracking tool. All schedules, pay '
        'calculations, travel estimates, and weather data are provided for '
        'informational purposes only.\n\n'
        'Pay calculations are estimates based on the daily rate and dates '
        'you enter. They do not account for taxes, deductions, overtime, or '
        'other payroll factors. Always verify actual pay with your employer.\n\n'
        'Travel time estimates assume average driving conditions and may not '
        'reflect actual journey times.',
  ),
  _PolicySection(
    title: '5. User responsibilities',
    body: 'You are responsible for:\n\n'
        '• Maintaining the accuracy of data you enter into the app\n'
        '• Keeping your device and Google account secure\n'
        '• Any data shared through the Family Sharing feature\n'
        '• Ensuring location permissions are appropriate for your use',
  ),
  _PolicySection(
    title: '6. Family sharing',
    body: 'The Family Sharing feature allows you to share hitch schedules '
        'with household members using an invite code. By using this feature:\n\n'
        '• You consent to your schedule data being stored on Firebase servers\n'
        '• You are responsible for who you share your invite code with\n'
        '• Household owners can see all member data within the household\n'
        '• You can leave a household at any time through the app',
  ),
  _PolicySection(
    title: '7. Limitation of liability',
    body: 'NuvioLabs shall not be liable for any indirect, incidental, special, '
        'or consequential damages arising from your use of RigSync, including '
        'but not limited to loss of data, missed rotations, or financial '
        'discrepancies.\n\n'
        'The app is provided "as is" without warranty of any kind.',
  ),
  _PolicySection(
    title: '8. Termination',
    body: 'We reserve the right to terminate or suspend access to RigSync '
        'at our discretion, without notice, for conduct that we believe '
        'violates these Terms or is harmful to other users, us, or third parties.',
  ),
  _PolicySection(
    title: '9. Changes to terms',
    body: 'We may revise these Terms at any time. We will notify users of '
        'significant changes through the app. Continued use after changes '
        'constitutes acceptance of the revised terms.',
  ),
  _PolicySection(
    title: '10. Governing law',
    body: 'These Terms shall be governed by and construed in accordance with '
        'the laws of India. Any disputes shall be subject to the exclusive '
        'jurisdiction of courts in India.',
  ),
  _PolicySection(
    title: '11. Contact',
    body: 'For questions about these Terms, contact us at:\n\n'
        'NuvioLabs\n'
        'Email: nuviolabs07@gmail.com',
  ),
];