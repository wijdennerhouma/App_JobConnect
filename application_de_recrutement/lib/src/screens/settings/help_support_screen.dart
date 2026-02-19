import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/translations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('help_support_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('faq_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    context,
                    lang.tr('faq_q1'),
                    lang.tr('faq_a1'),
                  ),
                  const Divider(),
                  _buildFAQItem(
                    context,
                    lang.tr('faq_q2'),
                    lang.tr('faq_a2'),
                  ),
                  const Divider(),
                  _buildFAQItem(
                    context,
                    lang.tr('faq_q3'),
                    lang.tr('faq_a3'),
                  ),
                  const Divider(),
                  _buildFAQItem(
                    context,
                    lang.tr('faq_q4'),
                    lang.tr('faq_a4'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_support, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('contact_us'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(lang.tr('email_label')),
                    subtitle: const Text('support@jobconnect.com'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.tr('email_copied'))),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(lang.tr('phone_label_full')),
                    subtitle: const Text('+33 1 23 45 67 89'),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.tr('phone_copied'))),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(lang.tr('opening_hours')),
                    subtitle: Text(lang.tr('opening_hours_value')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Signaler un problème
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('report_issue'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showReportDialog(context);
                    },
                    icon: const Icon(Icons.report),
                    label: Text(lang.tr('report_bug')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    final lang = context.read<AppSettings>().language;
    final reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('report_issue')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.tr('describe_issue')),
              const SizedBox(height: 12),
          TextField(
                controller: reportController,
                maxLines: 5,
            decoration: InputDecoration(
              hintText: lang.tr('describe_issue'),
              border: const OutlineInputBorder(),
            ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.tr('issue_reported_thanks'))),
              );
            },
            child: Text(lang.tr('send')),
          ),
        ],
      ),
    );
  }
}
