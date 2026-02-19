import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/auth_state.dart';
import '../../core/translations.dart';
import '../../services/application_service.dart';
import '../../services/job_service.dart';
import '../../widgets/glass_container.dart';
import 'company_jobs_screen.dart';
import 'job_form_screen.dart';
import '../search/search_screen.dart';
import '../chat/conversation_list_screen.dart';
import '../notifications/notification_list_screen.dart';
import '../../services/notification_service.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, int>> _loadStats() async {
    final auth = context.read<AuthState>();
    if (auth.userId == null) return {'jobs': 0, 'applicants': 0};
    final jobs = await JobService(auth).fetchAll();
    final myJobs = jobs.where((j) => j.entrepriseId == auth.userId).toList();
    // Source unique : API candidatures (cohérent avec l'écran Candidats)
    final appService = ApplicationService(auth);
    int applicants = 0;
    for (final j in myJobs) {
      try {
        final list = await appService.byJob(j.id);
        applicants += list.length;
      } catch (_) {}
    }
    return {'jobs': myJobs.length, 'applicants': applicants};
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lang = settings.language;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.grey[50];
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.blueGrey[200] : Colors.grey[600];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.business_center,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.tr('company_space') ?? 'Espace Entreprise',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.tr('welcome') ?? 'Bienvenue',
                          style: TextStyle(
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Consumer<NotificationService>(
                      builder: (context, notificationService, child) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor ?? Colors.transparent),
                                boxShadow: isDark ? null : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen()));
                                },
                                icon: const Icon(Icons.notifications_none, color: Colors.blueAccent),
                                tooltip: lang.tr('notifications'),
                              ),
                            ),
                            if (notificationService.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 8,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor ?? Colors.transparent),
                        boxShadow: isDark ? null : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationListScreen()));
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                        tooltip: lang.tr('messages'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSearchBar(context, surfaceColor, borderColor, isDark, lang),
              const SizedBox(height: 16),
              _buildStatsRow(context, isDark, surfaceColor, borderColor, lang),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor ?? Colors.transparent),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.blueGrey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.list_alt_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(lang.tr('offers') ?? 'Offres'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(lang.tr('publish') ?? 'Publier'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: TabBarView(
                  children: [
                    CompanyJobsScreen(),
                    JobFormScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark, Color surfaceColor, Color? borderColor, AppLanguage lang) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.blueGrey[200] : Colors.grey[600];
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final jobs = snapshot.data?['jobs'] ?? 0;
        final applicants = snapshot.data?['applicants'] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  opacity: 0.2,
                  blur: 6,
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, color: Colors.blueAccent, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$jobs',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            lang.tr('offers'),
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  opacity: 0.2,
                  blur: 6,
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$applicants',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            lang.tr('applicants'),
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, Color surfaceColor, Color? borderColor, bool isDark, AppLanguage lang) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Text(
              lang.tr('search_profile_placeholder') ?? 'Rechercher un profil...',
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
