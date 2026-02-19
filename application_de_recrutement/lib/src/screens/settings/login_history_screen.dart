import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';

import 'package:intl/date_symbol_data_local.dart';

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('login_history')),
      ),
      body: FutureBuilder(
        future: Future.wait([
          auth.getLoginHistory(),
          initializeDateFormatting(lang.code, null),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = (snapshot.data as List)[0] as List<String>;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(lang.tr('no_results_found'), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final dateStr = history[index];
              final date = DateTime.tryParse(dateStr);
              
              if (date == null) return const SizedBox.shrink();

              // formatting handles the locale now that it is initialized
              final formattedDate = DateFormat.yMMMd(lang.code).add_jm().format(date);
              
              // Simulate location/device based on index for variety
              final isCurrent = index == 0;
              final device = isCurrent ? 'Chrome (Windows)' : (index % 2 == 0 ? 'Chrome (Windows)' : 'Mobile App (Android)');
              final ip = isCurrent ? '192.168.1.1' : '10.0.0.${index+2}';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  child: Icon(
                    isCurrent ? Icons.check_circle : Icons.history, 
                    color: isCurrent ? Colors.green : Colors.grey
                  ),
                ),
                title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device),
                    Text('IP: $ip', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: isCurrent 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(lang.tr('current_connection'), style: const TextStyle(color: Colors.green, fontSize: 12)),
                    )
                  : null,
              );
            },
          );
        },
      ),
    );
  }
}
