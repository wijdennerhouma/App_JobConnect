import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../models/app_application.dart';
import '../../services/application_service.dart';
import 'widgets/application_details_sheet.dart';

class ApplicationsHistoryScreen extends StatefulWidget {
  const ApplicationsHistoryScreen({super.key});

  @override
  State<ApplicationsHistoryScreen> createState() =>
      _ApplicationsHistoryScreenState();
}

class _ApplicationsHistoryScreenState extends State<ApplicationsHistoryScreen> {
  late Future<List<ApplicationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ApplicationItem>> _load() async {
    final auth = context.read<AuthState>();
    return ApplicationService(auth).byApplicant(auth.userId!);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final theme = Theme.of(context);
    
    return FutureBuilder<List<ApplicationItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${lang.tr('error_prefix')}: ${snapshot.error}'));
        }
        final apps = snapshot.data ?? [];
        if (apps.isEmpty) {
          return Center(child: Text(lang.tr('no_applications_yet')));
        }
        return ListView.builder(
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            final job = app.job;
            // Format date instead of pricing
            String dateText = '';
            if (app.createdAt != null) {
              final diff = DateTime.now().difference(app.createdAt!);
              if (diff.inDays > 0) {
                 dateText = '${diff.inDays} ${lang.tr('days_ago') ?? 'days ago'}';
              } else if (diff.inHours > 0) {
                 dateText = '${diff.inHours} ${lang.tr('hours_ago') ?? 'hours ago'}';
              } else {
                 dateText = lang.tr('just_now') ?? 'Just now';
              }
            } else {
              dateText = lang.tr('date_not_specified') ?? 'Date unknown';
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                onTap: () => _showApplicationDetails(context, app),
                title: Text(job?.title ?? lang.tr('offer')),
                subtitle: Text('${lang.tr('status')}: ${_getStatusLabel(app.status, lang)}'),
                trailing: Text(dateText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }

  void _showApplicationDetails(BuildContext context, ApplicationItem app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return ApplicationDetailsSheet(
            app: app,
            scrollController: scrollController,
          );
        },
      ),
    );
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
      case 'interview':
        return lang.tr('status_interview') ?? 'Entretien';
      default:
        return status;
    }
  }
}
