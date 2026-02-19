import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/api_config.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../services/job_service.dart';
import '../../services/user_service.dart';
import '../../services/application_service.dart';
import '../../models/app_application.dart';
import 'apply_job_screen.dart';
import 'widgets/application_details_sheet.dart';
import '../chat/chat_screen.dart';
import 'widgets/bouncing_button.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<Job?> _jobFuture;
  AppUser? _company;
  bool _isLoadingCompany = true;
  bool _hasApplied = false;
  late AppLanguage _appLang;

  @override
  void initState() {
    super.initState();
    _jobFuture = _loadJob();
  }

  Future<Job?> _loadJob() async {
    final auth = context.read<AuthState>();
    final job = await JobService(auth).fetchById(widget.jobId);
    
    // Charger les infos de l'entreprise
    if (job != null) {
      _loadCompanyInfo(job.entrepriseId);
      _checkIfApplied();
    }
    
    return job;
  }

  Future<void> _loadCompanyInfo(String companyId) async {
    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      final companyData = await userService.getProfile(companyId);
      if (mounted) {
        setState(() {
          _company = AppUser.fromJson(companyData);
          _isLoadingCompany = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompany = false;
        });
      }
    }
  }

  Future<void> _checkIfApplied() async {
    try {
      final auth = context.read<AuthState>();
      if (auth.userId == null) return;
      
      final apps = await ApplicationService(auth).byApplicant(auth.userId!);
      if (mounted) {
        setState(() {
          _hasApplied = apps.any((a) => a.jobId == widget.jobId);
        });
      }
    } catch (e) {
      debugPrint('Error checking application status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    _appLang = settings.language;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_appLang.tr('job_details')),
      ),
      body: FutureBuilder<Job?>(
        future: _jobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${_appLang.tr('error_prefix')}: ${snapshot.error}'));
          }
          final job = snapshot.data;
          if (job == null) {
            return Center(child: Text(_appLang.tr('job_not_found')));
          }
          return _buildJobDetailContent(context, job);
        },
      ),
    );
  }

  Widget _buildJobDetailContent(BuildContext context, Job job) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte de l'entreprise (style LinkedIn)
                Card(
                  margin: const EdgeInsets.all(0),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _company != null ? _showCompanyProfile(context) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                      children: [
                        // Avatar et nom de l'entreprise
                        Row(
                          children: [
                            Hero(
                              tag: 'job-logo-${job.id}',
                              child: ClipOval(
                                child: _company?.avatar != null && _company!.avatar!.isNotEmpty
                                    ? Image.network(
                                        '${ApiConfig.baseUrl}/uploads/avatars/${_company!.avatar}',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey[300],
                                            alignment: Alignment.center,
                                            child: Icon(Icons.business, size: 35, color: Colors.grey[600]),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[300],
                                        alignment: Alignment.center,
                                        child: Icon(Icons.business, size: 35, color: Colors.grey[600]),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _company?.name ?? _appLang.tr('company'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_company?.city != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          _company!.city!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Nombre de candidats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                '${job.applicantsIds.length} ${_appLang.tr('applicants')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre du poste
                      Hero(
                        tag: 'job-title-${job.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Informations principales
                      _buildInfoRow(Icon(Icons.place, size: 20, color: Colors.grey[600]), _appLang.tr('location'), job.address),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icon(Icons.work_outline, size: 20, color: Colors.grey[600]), _appLang.tr('job_contract_label'), job.contract),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                        _appLang.tr('job_start_time_label'),
                        '${job.startTime} - ${job.endTime}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                        _appLang.tr('job_start_date_label'),
                        '${job.startDate} → ${job.endDate}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                        _appLang.tr('job_duration_label'),
                        job.duration,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('DT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        ),
                        _appLang.tr('salary'),
                        '${job.price} / ${_appLang.tr(job.pricingType.replaceAll(' ', '_')) ?? job.pricingType}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                        _appLang.tr('job_hours_per_week_label'),
                        '${job.workHours}',
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        _appLang.tr('job_description_label'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Barre d'action fixe en bas (style LinkedIn)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      return BouncingButton(
                        onPressed: _hasApplied 
                            ? () => _viewApplication(context, job)
                            : () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ApplyJobScreen(job: job),
                                  ),
                                );
                                // Refresh status
                                _checkIfApplied();
                              },
                        child: FilledButton.icon(
                          onPressed: null, // BouncingButton handles tap
                          icon: Icon(_hasApplied ? Icons.visibility : Icons.send),
                          label: Text(_hasApplied ? (_appLang.tr('view_application') ?? 'Voir ma candidature') : _appLang.tr('apply')),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _hasApplied ? Colors.blueGrey : null,
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
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
      // Find application for this job
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
          // Fallback: allow to apply if application not found (data sync issue)
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

  Widget _buildInfoRow(Widget icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCompanyProfile(BuildContext context) {
    if (_company == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: _company!.avatar != null && _company!.avatar!.isNotEmpty
                              ? NetworkImage('${ApiConfig.baseUrl}/uploads/avatars/${_company!.avatar}')
                              : null,
                          child: _company!.avatar == null || _company!.avatar!.isEmpty
                              ? const Icon(Icons.business, size: 35)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _company!.name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _appLang.tr('company') ?? 'Entreprise',
                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                     SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close modal
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: _company!)));
                        },
                        icon: const Icon(Icons.chat),
                        label: Text(_appLang.tr('send_message') ?? 'Envoyer un message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_company!.email != null) ...[
                      _buildInfoRow(const Icon(Icons.email, color: Colors.grey), 'Email', _company!.email!),
                      const SizedBox(height: 16),
                    ],
                    if (_company!.address != null || _company!.city != null) ...[
                      _buildInfoRow(const Icon(Icons.location_on, color: Colors.grey), 'Adresse', '${_company!.address ?? ""} ${_company!.city ?? ""}'),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_appLang.tr('close') ?? 'Fermer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

