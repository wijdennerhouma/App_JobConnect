import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth_state.dart';
import '../../core/api_config.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../services/job_service.dart';
import '../../services/user_service.dart';
import 'job_detail_screen.dart';

import 'apply_job_screen.dart';
import 'widgets/application_details_sheet.dart';
import '../../services/application_service.dart';
import '../../models/app_application.dart';

import '../../models/job_with_company.dart';
import '../../models/saved_search.dart';
import '../../services/recommendation_service.dart';
import '../../services/saved_search_service.dart';
import '../../widgets/glass_skeleton.dart';
import '../../widgets/hover_scale_wrapper.dart';
import 'widgets/job_card.dart';
import 'widgets/job_filter_sheet.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late Future<List<JobWithCompany>> _future;

  String _searchTitle = '';
  String _searchCity = '';
  late AppLanguage _appLang;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }


  Set<String> _savedJobIds = {};
  Set<String> _appliedJobIds = {};

  Future<List<JobWithCompany>> _load() async {
    final auth = context.read<AuthState>();
    final jobService = JobService(auth);
    final userService = UserService(auth);


    final jobs = await jobService.fetchAll();


    try {
      if (auth.userId != null) {
        final apps = await ApplicationService(auth).byApplicant(auth.userId!);
        _appliedJobIds = apps.map((a) => a.jobId).toSet();
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
    }


    try {
      if (auth.userId != null) {
        final savedJobsData = await userService.getSavedJobs(auth.userId!);
        _savedJobIds = savedJobsData.map((data) => Job.fromJson(data).id).toSet();
      }
    } catch (e) {
      debugPrint('Error loading saved jobs: $e');
    }
    

    final jobsWithCompany = <JobWithCompany>[];
    for (final job in jobs) {
      AppUser? company;
      try {
        final companyData = await userService.getProfile(job.entrepriseId);
        company = AppUser.fromJson(companyData);
      } catch (e) {

      }
      jobsWithCompany.add(JobWithCompany(job: job, company: company));
    }

    return jobsWithCompany;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettings>();
    _appLang = settings.language;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                _appLang.tr('latest_offers') ?? 'Dernières offres',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: _showFilterDialog,
                  tooltip: _appLang.tr('filter_tooltip') ?? 'Filtrer',
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: FutureBuilder<List<JobWithCompany>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const GlassJobListSkeleton(itemCount: 6);
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('${_appLang.tr('error_prefix')}: ${snapshot.error}'),
                );
              }
              final jobsWithCompany = snapshot.data ?? [];
              final filtered = jobsWithCompany.where((jobWithCompany) {
                final job = jobWithCompany.job;
                final company = jobWithCompany.company;
                
                // Filter by Title
                final titleMatch = _searchTitle.isEmpty || 
                    job.title.toLowerCase().contains(_searchTitle) || 
                    job.description.toLowerCase().contains(_searchTitle);

                // Filter by City
                final displayCity = company?.city ?? job.address;
                final cityMatch = _searchCity.isEmpty || 
                    displayCity.toLowerCase().contains(_searchCity);

                return titleMatch && cityMatch;
              }).toList();

              final auth = context.read<AuthState>();
              final scored = sortByRecommendation(
                jobs: filtered,
                userCity: _searchCity.isNotEmpty ? _searchCity : null,
                preferredContract: null,
                appliedJobIds: _appliedJobIds,
              );
              final recommended = scored.where((s) => s.score >= 60).toList();
              final rest = scored.where((s) => s.score < 60).toList();
              
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                      const SizedBox(height: 24),
                      Text(
                        _appLang.tr('no_jobs_yet') ?? 'Aucune offre trouvée',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              final combined = <dynamic>[];
              if (recommended.isNotEmpty) {
                combined.add('header_recommended');
                combined.addAll(recommended);
              }
              if (rest.isNotEmpty) {
                combined.add('header_latest');
                combined.addAll(rest);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                     _future = _load();
                  });
                },
                child: AnimationLimiter(
                  child: ListView.builder(
                    itemCount: combined.length,
                    itemBuilder: (context, index) {
                      final item = combined[index];
                      if (item == 'header_recommended') {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            _appLang.tr('recommended_for_you'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }
                      if (item == 'header_latest') {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Text(
                            _appLang.tr('latest_offers'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                      final scored = item as ScoredJob;
                      final jobWithCompany = scored.jobWithCompany;
                      final job = jobWithCompany.job;
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: HoverScaleWrapper(
                              child: JobCard(
                                job: job,
                                company: jobWithCompany.company,
                              isSaved: _savedJobIds.contains(job.id),
                              matchScore: scored.score,
                              hasApplied: auth.userId != null && _appliedJobIds.contains(job.id),
                              onToggleSaved: () async {
                                  try {
                                    final auth = context.read<AuthState>();
                                    final userService = UserService(auth);
                                    await userService.toggleSavedJob(auth.userId!, job.id);
                                    setState(() {
                                      if (_savedJobIds.contains(job.id)) {
                                        _savedJobIds.remove(job.id);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_appLang.tr('item_deleted_from'))));
                                      } else {
                                        _savedJobIds.add(job.id);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_appLang.tr('saved_successfully'))));
                                      }
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_appLang.tr('error')}: $e')));
                                  }
                              },
                              onApply: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ApplyJobScreen(job: job),
                                    ),
                                  );
                                  setState(() {
                                    _future = _load();
                                  });
                              },
                              onViewApplication: () => _viewApplication(context, job),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _viewApplication(BuildContext context, Job job) async {
    final auth = context.read<AuthState>();
    if (auth.userId == null) return;
    
    // Show loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final apps = await ApplicationService(auth).byApplicant(auth.userId!);

      final myApp = apps.cast<ApplicationItem?>().firstWhere(
        (a) => a?.jobId == job.id || a?.job?.id == job.id,
        orElse: () => null,
      );
      
      if (mounted) Navigator.pop(context); // hide loading
      
      if (myApp != null && mounted) {
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
                app: myApp,
                scrollController: scrollController,
              );
            },
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(_appLang.tr('application_not_found_redirect')),
               duration: const Duration(seconds: 2),
             ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ApplyJobScreen(job: job),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // hide loading
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${_appLang.tr('error_prefix')}: $e')),
         );
      }
    }
  }

  void _showFilterDialog() {
    final auth = context.read<AuthState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return JobFilterSheet(
          initialTitle: _searchTitle,
          initialCity: _searchCity,
          onApply: (title, city) {
            setState(() {
              _searchTitle = title;
              _searchCity = city;
            });
          },
          onSaveSearch: auth.userId != null
              ? (title, city) async {
                  final search = SavedSearch(
                    id: '${DateTime.now().millisecondsSinceEpoch}',
                    title: title.isEmpty ? _appLang.tr('search_placeholder') : title,
                    city: city.isEmpty ? null : city,
                    contract: null,
                    alertOnNewJob: true,
                    createdAt: DateTime.now(),
                  );
                  await SavedSearchService.add(auth.userId!, search);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_appLang.tr('saved_search_created'))),
                    );
                  }
                }
              : null,
        );
      },
    );
  }
}
