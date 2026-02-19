import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../models/job.dart';
import '../../models/user.dart';
import '../../services/application_service.dart';
import '../../services/user_service.dart';
import '../../services/resume_service.dart';
import 'job_detail_screen.dart';
import 'widgets/bouncing_button.dart'; // Reuse bouncing button there too

class ApplyJobScreen extends StatefulWidget {
  const ApplyJobScreen({super.key, required this.job});

  final Job job;

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  AppUser? _company;
  bool _isLoading = true;
  bool _isApplying = false;
  late AppLanguage _appLang;
  late ConfettiController _confettiController;
  
  final TextEditingController _coverLetterController = TextEditingController();


  bool _hasResume = false;
  bool _alreadyApplied = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadData();
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      final resumeService = ResumeService(auth);
      final appService = ApplicationService(auth);

      // Check if already applied
      final myApps = await appService.byApplicant(auth.userId!);
      if (myApps.any((app) => app.jobId == widget.job.id)) {
        if (mounted) {
          setState(() {
            _alreadyApplied = true;
            _isLoading = false;
          });
        }
        return;
      }

      // Load Company Info
      final companyData = await userService.getProfile(widget.job.entrepriseId);
      
      // Load User Resume Data
      bool hasResume = false;

      try {
        final resumeData = await resumeService.getByUser(auth.userId!);
        if (resumeData != null) {
          hasResume = true;
        }
      } catch (e) {
        // Resume might not exist
      }

      setState(() {
        _company = AppUser.fromJson(companyData);
        _hasResume = hasResume;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _apply() async {
    if (_coverLetterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appLang.tr('cover_letter_required') ?? 'Veuillez saisir une lettre de motivation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApplying = true);
    try {
      final auth = context.read<AuthState>();
      await ApplicationService(auth).apply(
        jobId: widget.job.id,
        entrepriseId: widget.job.entrepriseId,
        coverLetter: _coverLetterController.text,
      );
      if (!mounted) return;
      
      _confettiController.play();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appLang.tr('application_sent_success')),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retourner à la liste après un délai
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.of(context).pop(true); // Retour avec succès
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_appLang.tr('error_prefix')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    _appLang = settings.language;
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_appLang.tr('apply'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_alreadyApplied) {
      return Scaffold(
        appBar: AppBar(title: Text(_appLang.tr('apply_job'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                _appLang.tr('already_applied') ?? 'Vous avez déjà postulé à cette offre.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_appLang.tr('back_to_offers') ?? 'Retour aux offres'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(_appLang.tr('apply_job')),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé de l'offre
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_company != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _company!.name,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.place, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(widget.job.address),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('DT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                            const SizedBox(width: 4),
                            Text('${widget.job.price} / ${_appLang.tr(widget.job.pricingType.replaceAll(' ', '_')) ?? widget.job.pricingType}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Lettre de motivation
                Text(
                  _appLang.tr('cover_letter') ?? 'Lettre de motivation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _coverLetterController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: _appLang.tr('cover_letter_hint') ?? 'Expliquez pourquoi vous êtes le meilleur candidat...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                ),
                const SizedBox(height: 24),


                const SizedBox(height: 32),

                const SizedBox(height: 32),

                
                // Boutons d'action
                SizedBox(
                  width: double.infinity,
                  child: BouncingButton(
                    onPressed: _isApplying ? null : _apply,
                    child: FilledButton.icon(
                      onPressed: null, // BouncingButton handles tap
                      icon: _isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isApplying ? _appLang.tr('sending_in_progress') : _appLang.tr('send_application')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false, 
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ], 
          ),
        ),
      ],
    );
  }
}
