import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:application_de_recrutement/src/core/auth_state.dart';
import 'package:application_de_recrutement/src/core/app_settings.dart';
import 'package:application_de_recrutement/src/core/translations.dart';
import 'package:application_de_recrutement/src/services/user_service.dart';
import 'package:application_de_recrutement/src/models/job.dart';
import 'package:application_de_recrutement/src/models/user.dart';
import 'package:application_de_recrutement/src/models/job_with_company.dart';
import 'package:application_de_recrutement/src/screens/employee/widgets/job_card.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  bool _loading = true;
  List<JobWithCompany> _savedJobs = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      final jobsData = await userService.getSavedJobs(auth.userId!);
      
      final jobsWithCompany = <JobWithCompany>[];
      for (final data in jobsData) {
        try {
          final job = Job.fromJson(data);
          
          AppUser? company;
          try {
            final companyData = await userService.getProfile(job.entrepriseId);
            company = AppUser.fromJson(companyData);
          } catch (e) {
            // Company not found, proceed without
          }
          
          jobsWithCompany.add(JobWithCompany(job: job, company: company));
        } catch (e) {
          debugPrint('Error parsing job: $e');
        }
      }

      setState(() {
        _savedJobs = jobsWithCompany;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  Future<void> _unsaveJob(String jobId) async {
    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      await userService.toggleSavedJob(auth.userId!, jobId);
      _loadSavedJobs(); // Reload list
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Offre retirée des favoris')),
         );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('saved_jobs') ?? 'Offres sauvegardées'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _savedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            lang.tr('no_saved_jobs') ?? 'Aucune offre sauvegardée',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _savedJobs.length,
                      itemBuilder: (context, index) {
                        final item = _savedJobs[index];
                        return JobCard(
                          job: item.job,
                          company: item.company,
                          isSaved: true,
                          onToggleSaved: () => _unsaveJob(item.job.id),
                          showApplyButton: false, // Hide apply button in saved list if preferred, or true
                        );
                      },
                    ),
    );
  }
}

