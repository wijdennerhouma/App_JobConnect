import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../models/job.dart';
import '../../services/application_service.dart';
import '../../services/job_service.dart';
import '../../widgets/glass_skeleton.dart';
import 'job_applicants_screen.dart';

class CompanyJobsScreen extends StatefulWidget {
  const CompanyJobsScreen({super.key});

  @override
  State<CompanyJobsScreen> createState() => _CompanyJobsScreenState();
}

class _CompanyJobsPayload {
  final List<Job> jobs;
  final Map<String, int> applicantCounts;
  _CompanyJobsPayload({required this.jobs, required this.applicantCounts});
}

class _CompanyJobsScreenState extends State<CompanyJobsScreen> {
  late Future<_CompanyJobsPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CompanyJobsPayload> _load() async {
    final auth = context.read<AuthState>();
    final jobs = await JobService(auth).fetchAll();
    final myJobs = jobs
        .where((job) => job.entrepriseId == auth.userId)
        .toList(growable: false);
    // Source unique : API candidatures (cohérent avec l'écran Candidats)
    final appService = ApplicationService(auth);
    final Map<String, int> applicantCounts = {};
    for (final job in myJobs) {
      try {
        final list = await appService.byJob(job.id);
        applicantCounts[job.id] = list.length;
      } catch (_) {
        applicantCounts[job.id] = 0;
      }
    }
    return _CompanyJobsPayload(jobs: myJobs, applicantCounts: applicantCounts);
  }

  Future<void> _deleteJob(Job job) async {
    final lang = context.read<AppSettings>().language;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('delete_job_title')),
        content: Text(lang.tr('delete_job_content').replaceAll('{job}', job.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final auth = context.read<AuthState>();
        await JobService(auth).delete(job.id);
        setState(() {
          _future = _load();
        });
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(lang.tr('job_deleted_success'))),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${lang.tr('error')}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.blueGrey : Colors.grey[600];

    return FutureBuilder<_CompanyJobsPayload>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GlassJobListSkeleton(itemCount: 4);
        }
        if (snapshot.hasError) {
          return Center(child: Text('${lang.tr('error_prefix')}: ${snapshot.error}'));
        }
        final payload = snapshot.data;
        final jobs = payload?.jobs ?? [];
        final applicantCounts = payload?.applicantCounts ?? {};
        if (jobs.isEmpty) {
          return Center(
            child: Text(
              lang.tr('no_published_jobs_yet'), 
              style: TextStyle(color: subTextColor)
            )
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            final applicantCount = applicantCounts[job.id] ?? 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ), 
                ],
                border: isDark ? null : Border.all(color: Colors.grey[200]!),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobApplicantsScreen(job: job),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 16, color: Colors.blueAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$applicantCount',
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteJob(job),
                                  tooltip: 'Supprimer l\'offre',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: subTextColor),
                            const SizedBox(width: 4),
                            Text(
                              job.address,
                              style: TextStyle(color: subTextColor, fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.work_outline, size: 16, color: subTextColor),
                            const SizedBox(width: 4),
                            Text(
                              job.contract,
                              style: TextStyle(color: subTextColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

