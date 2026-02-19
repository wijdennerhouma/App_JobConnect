import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_settings.dart';
import '../../../core/translations.dart';
import '../../../models/app_application.dart';

class ApplicationDetailsSheet extends StatelessWidget {
  final ApplicationItem app;
  final ScrollController scrollController;

  const ApplicationDetailsSheet({
    super.key,
    required this.app,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final job = app.job;
    final statusColor = _getStatusColor(app.status);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // En-tête (Titre du Job)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job?.title ?? lang.tr('offer'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (job?.address != null)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            job!.address,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (lang.tr('status') ?? 'Statut').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusLabel(app.status, lang),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor, // Darker shade?
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getStatusIcon(app.status),
                      color: statusColor, size: 28),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Lettre de motivation envoyée
          Text(
            lang.tr('cover_letter') ?? 'Lettre de motivation',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(
                  color: isDarkMode(context)
                      ? Colors.white12
                      : Colors.grey.shade200),
            ),
            child: Text(
              (app.coverLetter != null && app.coverLetter!.isNotEmpty)
                  ? app.coverLetter!
                  : (lang.tr('no_cover_letter') ?? 'Aucune lettre fournie'),
              style: TextStyle(
                height: 1.6,
                fontSize: 16,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.8),
              ),
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                lang.tr('close') ?? 'Fermer',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'started':
        return Colors.blue;
      case 'finished':
        return Colors.green;
      case 'contract_signed':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_filled;
      case 'accepted':
      case 'started':
        return Icons.work;
      case 'finished':
        return Icons.check_circle;
      case 'contract_signed':
        return Icons.gesture;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status, AppLanguage lang) {
    switch (status) {
      case 'pending':
        return lang.tr('status_pending') ?? 'En attente';
      case 'accepted':
        return lang.tr('status_accepted') ?? 'Acceptée';
      case 'started':
        return lang.tr('status_started') ?? 'Commencée';
      case 'finished':
        return lang.tr('status_finished') ?? 'Terminée';
      case 'contract_signed':
        return lang.tr('status_signed') ?? 'Signée';
      case 'rejected':
        return lang.tr('status_rejected') ?? 'Refusée';
      case 'reviewed':
        return lang.tr('status_reviewed') ?? 'Vue';
      default:
        return status.toUpperCase();
    }
  }

  bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
